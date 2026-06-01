using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace DanpheEMR.DalLayer
{
    public class DALFunctions
    {
        #region GetData From stored procedure
        public static DataSet GetDatasetFromStoredProc(string storedProcName, List<SqlParameter> ipParams, DbContext dbContext)
        {
            // creates resulting dataset
            var result = new DataSet();
            // creates a Command 
            var conn = dbContext.Database.GetDbConnection();
            var cmd = conn.CreateCommand();

            bool isPostgres = dbContext.Database.ProviderName != null && dbContext.Database.ProviderName.Contains("Npgsql");
            System.Data.Common.DbTransaction transaction = null;

            if (isPostgres)
            {
                cmd.CommandType = CommandType.Text;
                string funcName = storedProcName.ToLower();

                var paramNames = new List<string>();
                if (ipParams != null && ipParams.Count > 0)
                {
                    foreach (var param in ipParams)
                    {
                        string pName = param.ParameterName.Replace("@", "").ToLower();
                        var npgParam = new Npgsql.NpgsqlParameter(pName, param.Value ?? DBNull.Value);
                        cmd.Parameters.Add(npgParam);
                        paramNames.Add("@" + pName);
                    }
                }
                cmd.CommandText = $"SELECT * FROM {funcName}({string.Join(", ", paramNames)})";
            }
            else
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = storedProcName;

                if (ipParams != null && ipParams.Count > 0)
                {
                    foreach (var param in ipParams)
                    {
                        cmd.Parameters.Add(param);
                    }
                }
            }

            try
            {
                // executes
                if (conn.State != ConnectionState.Open)
                {
                    conn.Open();
                }

                if (isPostgres)
                {
                    transaction = conn.BeginTransaction();
                    cmd.Transaction = transaction;
                }

                var reader = cmd.ExecuteReader();

                if (isPostgres)
                {
                    bool isRefCursor = false;
                    if (reader.FieldCount > 0 && reader.GetDataTypeName(0) == "refcursor")
                    {
                        isRefCursor = true;
                    }

                    if (isRefCursor)
                    {
                        var cursorNames = new List<string>();
                        while (reader.Read())
                        {
                            cursorNames.Add(reader.GetString(0));
                        }
                        reader.Close();

                        foreach (var cursorName in cursorNames)
                        {
                            using (var fetchCmd = conn.CreateCommand())
                            {
                                fetchCmd.Transaction = transaction;
                                fetchCmd.CommandType = CommandType.Text;
                                fetchCmd.CommandText = $"FETCH ALL IN \"{cursorName}\"";
                                using (var fetchReader = fetchCmd.ExecuteReader())
                                {
                                    var tb = new DataTable();
                                    tb.Load(fetchReader);
                                    result.Tables.Add(tb);
                                }
                            }
                        }

                        transaction.Commit();
                        return result;
                    }
                }

                // Default non-cursor standard execution
                do
                {
                    // loads the DataTable (schema will be fetch automatically)
                    var tb = new DataTable();
                    tb.Load(reader);
                    result.Tables.Add(tb);

                } while (!reader.IsClosed);

                if (transaction != null)
                {
                    transaction.Commit();
                }

                return result;
            }
            catch (Exception ex)
            {
                if (transaction != null)
                {
                    try { transaction.Rollback(); } catch {}
                }
                throw ex;
            }
            finally
            {
                // closes the connection
                cmd.Parameters.Clear();
                conn.Close();
            }

        }
        ///// Get DataTable From SP with Input Parameters
        public static DataTable GetDataTableFromStoredProc(string storedProcName, List<SqlParameter> ipParams, DbContext dbContext)
        {
            try
            {
                DataSet ds = DALFunctions.GetDatasetFromStoredProc(storedProcName, ipParams, dbContext);
                return ds.Tables[0];
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        ///// Get DataTable From SP without Any Input Parameters
        public static DataTable GetDataTableFromStoredProc(string storedProcName, DbContext dbContext)
        {
            try
            {
                DataSet ds = DALFunctions.GetDatasetFromStoredProc(storedProcName, null, dbContext);
                return ds.Tables[0];
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        #endregion

        //this function shoud be replaced later with Execute Scalar of Ado.Net.

        public static int ExecuteStoredProcedure(string storedProcName, List<SqlParameter> ipParams, DbContext dbContext)
        {
            try
            {
                DataSet ds = DALFunctions.GetDatasetFromStoredProc(storedProcName, ipParams, dbContext);
                return 1;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        //Function to convert LINQ query result to Datatable
        public static DataTable LINQResultToDataTable<T>(IEnumerable<T> Linqlist)
        {
            DataTable dt = new DataTable();
            PropertyInfo[] columns = null;

            if (Linqlist == null) return dt;

            foreach (T Record in Linqlist)
            {

                if (columns == null)
                {
                    columns = ((Type)Record.GetType()).GetProperties();
                    foreach (PropertyInfo GetProperty in columns)
                    {
                        Type colType = GetProperty.PropertyType;

                        if ((colType.IsGenericType) && (colType.GetGenericTypeDefinition()
                        == typeof(Nullable<>)))
                        {
                            colType = colType.GetGenericArguments()[0];
                        }

                        dt.Columns.Add(new DataColumn(GetProperty.Name, colType));
                    }
                }

                DataRow dr = dt.NewRow();

                foreach (PropertyInfo pinfo in columns)
                {
                    dr[pinfo.Name] = pinfo.GetValue(Record, null) == null ? DBNull.Value : pinfo.GetValue
                    (Record, null);
                }

                dt.Rows.Add(dr);
            }
            return dt;
        }
    }
}

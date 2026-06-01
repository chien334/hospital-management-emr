using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using Npgsql;
using Xunit;

namespace DanpheEMR.Tests
{
    public class DatabaseMigration
    {
        private const string MsSqlConnString = "Server=localhost;Database=DanpheEMR;User Id=SA;Password=EMR_password123!;TrustServerCertificate=True";
        private const string PgSqlConnString = "Host=localhost;Database=danphe_emr;Username=postgres;Password=emr_password;Port=5432";

        [Fact]
        public void MigrateSqlServerToPostgreSQL()
        {
            Console.WriteLine("Starting Database Migration from MS SQL to PostgreSQL...");

            // 1. Reset PostgreSQL database (Drop and Recreate Public Schema)
            using (var pgConn = new NpgsqlConnection(PgSqlConnString))
            {
                pgConn.Open();
                using (var cmd = pgConn.CreateCommand())
                {
                    cmd.CommandText = "DROP SCHEMA public CASCADE; CREATE SCHEMA public;";
                    cmd.ExecuteNonQuery();
                    Console.WriteLine("PostgreSQL public schema reset successfully.");
                }
            }

            var tables = new List<string>();

            // 2. Fetch all user tables from SQL Server
            using (var msConn = new SqlConnection(MsSqlConnString))
            {
                msConn.Open();
                using (var cmd = msConn.CreateCommand())
                {
                    cmd.CommandText = "SELECT t.name AS TableName FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.is_ms_shipped = 0 ORDER BY t.name";
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            tables.Add(reader.GetString(0));
                        }
                    }
                }
            }

            Console.WriteLine($"Found {tables.Count} tables in MS SQL to migrate.");

            // 3. Migrate each table
            foreach (var tableName in tables)
            {
                try
                {
                    MigrateTable(tableName);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"ERROR migrating table {tableName}: {ex.Message}");
                    throw;
                }
            }

            Console.WriteLine("All tables and data migrated successfully!");
        }

        private void MigrateTable(string tableName)
        {
            var columns = new List<ColumnDefinition>();
            var primaryKeys = new HashSet<string>();

            // Fetch columns and PKs from MS SQL
            using (var msConn = new SqlConnection(MsSqlConnString))
            {
                msConn.Open();

                // Fetch Primary Keys
                using (var cmd = msConn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT COLUMN_NAME
                        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                        WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + CONSTRAINT_NAME), 'IsPrimaryKey') = 1
                          AND TABLE_NAME = @TableName";
                    cmd.Parameters.AddWithValue("@TableName", tableName);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            primaryKeys.Add(reader.GetString(0));
                        }
                    }
                }

                // Fetch Columns info
                using (var cmd = msConn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT 
                            c.name AS ColumnName,
                            ty.name AS DataType,
                            c.is_nullable AS IsNullable,
                            c.max_length AS MaxLength,
                            c.precision AS Precision,
                            c.scale AS Scale,
                            c.is_identity AS IsIdentity
                        FROM sys.columns c
                        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
                        WHERE c.object_id = OBJECT_ID(@TableName)
                        ORDER BY c.column_id";
                    cmd.Parameters.AddWithValue("@TableName", tableName);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            columns.Add(new ColumnDefinition
                            {
                                Name = reader.GetString(0),
                                DataType = reader.GetString(1),
                                IsNullable = reader.GetBoolean(2),
                                MaxLength = reader.GetInt16(3),
                                Precision = reader.GetByte(4),
                                Scale = reader.GetByte(5),
                                IsIdentity = reader.GetBoolean(6)
                            });
                        }
                    }
                }
            }

            // Map columns to PostgreSQL DDL
            var pgColumnsDdl = new List<string>();
            foreach (var col in columns)
            {
                string pgType = MapDataType(col.DataType, col.MaxLength, col.Precision, col.Scale);
                string colDdl = $"\"{col.Name}\" {pgType}";

                if (!col.IsNullable)
                {
                    colDdl += " NOT NULL";
                }

                pgColumnsDdl.Add(colDdl);
            }

            if (primaryKeys.Count > 0)
            {
                var pkCols = new List<string>();
                foreach (var pk in primaryKeys)
                {
                    pkCols.Add($"\"{pk}\"");
                }
                pgColumnsDdl.Add($"PRIMARY KEY ({string.Join(", ", pkCols)})");
            }

            string createTableSql = $"CREATE TABLE \"{tableName}\" (\n  {string.Join(",\n  ", pgColumnsDdl)}\n);";

            // Create Table in PostgreSQL
            using (var pgConn = new NpgsqlConnection(PgSqlConnString))
            {
                pgConn.Open();
                using (var cmd = pgConn.CreateCommand())
                {
                    cmd.CommandText = createTableSql;
                    cmd.ExecuteNonQuery();
                }
            }

            // Copy Data from MS SQL to PostgreSQL
            using (var msConn = new SqlConnection(MsSqlConnString))
            using (var pgConn = new NpgsqlConnection(PgSqlConnString))
            {
                msConn.Open();
                pgConn.Open();

                using (var msCmd = msConn.CreateCommand())
                {
                    msCmd.CommandText = $"SELECT * FROM [{tableName}]";
                    using (var msReader = msCmd.ExecuteReader())
                    {
                        // Build PostgreSQL parameterized batch insert statement
                        var colNames = new List<string>();
                        var paramPlaceholders = new List<string>();
                        for (int i = 0; i < columns.Count; i++)
                        {
                            colNames.Add($"\"{columns[i].Name}\"");
                            paramPlaceholders.Add($"$ {i + 1}"); // PostgreSQL Npgsql parameters can be positional or named. Positional is easiest!
                        }

                        // Let's use named parameters for maximum safety
                        var namedPlaceholders = new List<string>();
                        for (int i = 0; i < columns.Count; i++)
                        {
                            namedPlaceholders.Add($"@p{i}");
                        }

                        string insertSql = $"INSERT INTO \"{tableName}\" ({string.Join(", ", colNames)}) VALUES ({string.Join(", ", namedPlaceholders)})";

                        using (var pgTrans = pgConn.BeginTransaction())
                        using (var pgCmd = pgConn.CreateCommand())
                        {
                            pgCmd.Transaction = pgTrans;
                            pgCmd.CommandText = insertSql;

                            // Pre-create parameters
                            for (int i = 0; i < columns.Count; i++)
                            {
                                var param = pgCmd.CreateParameter();
                                param.ParameterName = $"p{i}";
                                pgCmd.Parameters.Add(param);
                            }

                            int rowCount = 0;
                            while (msReader.Read())
                            {
                                for (int i = 0; i < columns.Count; i++)
                                {
                                    object val = msReader.GetValue(i);
                                    pgCmd.Parameters[i].Value = val == DBNull.Value ? DBNull.Value : val;
                                }

                                pgCmd.ExecuteNonQuery();
                                rowCount++;
                            }

                            pgTrans.Commit();
                            Console.WriteLine($"Migrated table {tableName}: {rowCount} rows.");
                        }
                    }
                }
            }
        }

        private string MapDataType(string mssqlType, int maxLength, int precision, int scale)
        {
            switch (mssqlType.ToLower())
            {
                case "int": return "INT";
                case "bigint": return "BIGINT";
                case "smallint": return "SMALLINT";
                case "tinyint": return "SMALLINT";
                case "bit": return "BOOLEAN";
                case "decimal":
                case "numeric":
                    return $"DECIMAL({precision},{scale})";
                case "money":
                case "smallmoney":
                    return "DECIMAL(19,4)";
                case "float": return "DOUBLE PRECISION";
                case "real": return "REAL";
                case "varchar":
                case "nvarchar":
                    return maxLength == -1 ? "TEXT" : $"VARCHAR({maxLength})";
                case "char":
                case "nchar":
                    return $"CHAR({maxLength})";
                case "text":
                case "ntext":
                    return "TEXT";
                case "datetime":
                case "datetime2":
                case "smalldatetime":
                    return "TIMESTAMP";
                case "date": return "DATE";
                case "time": return "TIME";
                case "uniqueidentifier": return "UUID";
                case "varbinary":
                case "image":
                case "binary":
                    return "BYTEA";
                default:
                    return "TEXT"; // Default fallback
            }
        }

        private class ColumnDefinition
        {
            public string Name { get; set; } = "";
            public string DataType { get; set; } = "";
            public bool IsNullable { get; set; }
            public int MaxLength { get; set; }
            public int Precision { get; set; }
            public int Scale { get; set; }
            public bool IsIdentity { get; set; }
        }
    }
}

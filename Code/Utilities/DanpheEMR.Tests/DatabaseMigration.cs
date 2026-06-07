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

            // Create User-Defined Table Types in PostgreSQL
            try
            {
                MigrateTableTypes();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"WARNING: Failed to migrate table types: {ex.Message}");
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

            // 3. Migrate each table (Schema + Data + Indexes + UQ)
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

            // 4. Migrate Foreign Keys at the end
            try
            {
                MigrateForeignKeys();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR migrating foreign keys: {ex.Message}");
                throw;
            }

            Console.WriteLine("All tables, data, indexes, unique constraints, and foreign keys migrated successfully!");
        }

        private void MigrateTableTypes()
        {
            var tableTypes = new Dictionary<string, List<(string Name, string Type)>>();

            using (var msConn = new SqlConnection(MsSqlConnString))
            {
                msConn.Open();
                using (var cmd = msConn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT 
                            tt.name AS TableTypeName,
                            c.name AS ColumnName,
                            ty.name AS DataType,
                            c.max_length AS MaxLength,
                            c.precision AS Precision,
                            c.scale AS Scale
                        FROM sys.table_types tt
                        JOIN sys.columns c ON tt.type_table_object_id = c.object_id
                        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
                        ORDER BY tt.name, c.column_id";

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string typeName = reader.GetString(0);
                            string colName = reader.GetString(1);
                            string dataType = reader.GetString(2);
                            short maxLength = reader.GetInt16(3);
                            byte precision = reader.GetByte(4);
                            byte scale = reader.GetByte(5);

                            string pgType = MapDataType(dataType, maxLength, precision, scale);

                            if (!tableTypes.ContainsKey(typeName))
                            {
                                tableTypes[typeName] = new List<(string, string)>();
                            }
                            tableTypes[typeName].Add((colName, pgType));
                        }
                    }
                }
            }

            using (var pgConn = new NpgsqlConnection(PgSqlConnString))
            {
                pgConn.Open();
                foreach (var tt in tableTypes)
                {
                    var cols = new List<string>();
                    foreach (var col in tt.Value)
                    {
                        cols.Add($"\"{col.Name}\" {col.Type}");
                    }

                    string sql = $"CREATE TYPE \"{tt.Key.ToLower()}\" AS (\n  {string.Join(",\n  ", cols)}\n);";
                    using (var cmd = pgConn.CreateCommand())
                    {
                        cmd.CommandText = sql;
                        cmd.ExecuteNonQuery();
                    }
                    Console.WriteLine($"Migrated User-Defined Table Type: {tt.Key}");
                }
            }
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
                            c.is_identity AS IsIdentity,
                            object_definition(c.default_object_id) AS DefaultDefinition
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
                                IsIdentity = reader.GetBoolean(6),
                                DefaultValue = reader.IsDBNull(7) ? null : reader.GetString(7)
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

                if (col.IsIdentity)
                {
                    colDdl += " GENERATED BY DEFAULT AS IDENTITY";
                }
                else
                {
                    string? mappedDefault = MapDefaultValue(col.DefaultValue, pgType);
                    if (mappedDefault != null)
                    {
                        colDdl += $" DEFAULT {mappedDefault}";
                    }

                    if (!col.IsNullable)
                    {
                        colDdl += " NOT NULL";
                    }
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
                        for (int i = 0; i < columns.Count; i++)
                        {
                            colNames.Add($"\"{columns[i].Name}\"");
                        }

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

                // 1. Update sequence for identity columns
                foreach (var col in columns)
                {
                    if (col.IsIdentity)
                    {
                        using (var seqCmd = pgConn.CreateCommand())
                        {
                            seqCmd.CommandText = "SELECT setval(pg_get_serial_sequence('public.\"" + tableName + "\"', '" + col.Name + "'), GREATEST(COALESCE(MAX(\"" + col.Name + "\"), 1), 1)) FROM \"" + tableName + "\";";
                            seqCmd.ExecuteNonQuery();
                        }
                    }
                }

                // 2. Create Unique Constraints
                CreateUniqueConstraints(tableName, pgConn, msConn);

                // 3. Create Indexes
                CreateIndexes(tableName, pgConn, msConn);
            }
        }

        private void CreateUniqueConstraints(string tableName, NpgsqlConnection pgConn, SqlConnection msConn)
        {
            var uqConstraints = new List<(string Name, string Columns)>();

            using (var cmd = msConn.CreateCommand())
            {
                cmd.CommandText = @"
                    SELECT 
                        kc.name AS ConstraintName,
                        STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
                    FROM sys.key_constraints kc
                    JOIN sys.tables t ON kc.parent_object_id = t.object_id
                    JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id AND kc.unique_index_id = ic.index_id
                    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                    WHERE kc.type = 'UQ' AND t.name = @TableName
                    GROUP BY kc.name";
                cmd.Parameters.AddWithValue("@TableName", tableName);

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        uqConstraints.Add((reader.GetString(0), reader.GetString(1)));
                    }
                }
            }

            foreach (var uq in uqConstraints)
            {
                var colList = new List<string>();
                foreach (var col in uq.Columns.Split(','))
                {
                    colList.Add($"\"{col.Trim()}\"");
                }

                string uqName = uq.Name;
                if (uqName.Length > 63)
                {
                    string hash = Math.Abs(uqName.GetHashCode()).ToString("X");
                    uqName = uqName.Substring(0, 50) + "_" + hash;
                }

                try
                {
                    string createUqSql = $"ALTER TABLE \"{tableName}\" ADD CONSTRAINT \"{uqName}\" UNIQUE ({string.Join(", ", colList)});";
                    using (var cmd = pgConn.CreateCommand())
                    {
                        cmd.CommandText = createUqSql;
                        cmd.ExecuteNonQuery();
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"WARNING: Failed to create unique constraint {uqName} on {tableName}: {ex.Message}");
                }
            }
        }

        private void CreateIndexes(string tableName, NpgsqlConnection pgConn, SqlConnection msConn)
        {
            var indexes = new List<(string Name, bool IsUnique, string Columns)>();

            using (var cmd = msConn.CreateCommand())
            {
                cmd.CommandText = @"
                    SELECT 
                        i.name AS IndexName,
                        i.is_unique AS IsUnique,
                        STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
                    FROM sys.indexes i
                    JOIN sys.tables t ON i.object_id = t.object_id
                    JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                    WHERE t.name = @TableName
                      AND i.is_primary_key = 0 
                      AND i.is_unique_constraint = 0
                      AND i.type_desc = 'NONCLUSTERED'
                    GROUP BY i.name, i.is_unique, i.index_id";
                cmd.Parameters.AddWithValue("@TableName", tableName);

                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        indexes.Add((reader.GetString(0), reader.GetBoolean(1), reader.GetString(2)));
                    }
                }
            }

            foreach (var idx in indexes)
            {
                var colList = new List<string>();
                foreach (var col in idx.Columns.Split(','))
                {
                    colList.Add($"\"{col.Trim()}\"");
                }

                string pgIndexName = $"idx_{tableName}_{idx.Name}";
                if (pgIndexName.Length > 63)
                {
                    string hash = Math.Abs(pgIndexName.GetHashCode()).ToString("X");
                    pgIndexName = pgIndexName.Substring(0, 50) + "_" + hash;
                }

                try
                {
                    string createIdxSql = $"CREATE {(idx.IsUnique ? "UNIQUE" : "")} INDEX \"{pgIndexName}\" ON \"{tableName}\" ({string.Join(", ", colList)});";
                    using (var cmd = pgConn.CreateCommand())
                    {
                        cmd.CommandText = createIdxSql;
                        cmd.ExecuteNonQuery();
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"WARNING: Failed to create index {pgIndexName} on {tableName}: {ex.Message}");
                }
            }
        }

        private void MigrateForeignKeys()
        {
            var fkeys = new List<(string Name, string ParentTable, string ReferencedTable, string ParentCols, string ReferencedCols)>();

            using (var msConn = new SqlConnection(MsSqlConnString))
            {
                msConn.Open();
                using (var cmd = msConn.CreateCommand())
                {
                    cmd.CommandText = @"
                        SELECT 
                            fk.name AS ForeignKeyName,
                            tp.name AS ParentTable,
                            tr.name AS ReferencedTable,
                            STRING_AGG(cp.name, ',') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS ParentColumns,
                            STRING_AGG(cr.name, ',') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS ReferencedColumns
                        FROM sys.foreign_keys fk
                        JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
                        JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
                        JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
                        JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
                        JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
                        GROUP BY fk.name, tp.name, tr.name";

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            fkeys.Add((
                                reader.GetString(0),
                                reader.GetString(1),
                                reader.GetString(2),
                                reader.GetString(3),
                                reader.GetString(4)
                            ));
                        }
                    }
                }
            }

            Console.WriteLine($"Migrating {fkeys.Count} Foreign Keys to PostgreSQL...");

            using (var pgConn = new NpgsqlConnection(PgSqlConnString))
            {
                pgConn.Open();
                foreach (var fk in fkeys)
                {
                    try
                    {
                        var parentColsList = new List<string>();
                        foreach (var col in fk.ParentCols.Split(','))
                        {
                            parentColsList.Add($"\"{col.Trim()}\"");
                        }

                        var refColsList = new List<string>();
                        foreach (var col in fk.ReferencedCols.Split(','))
                        {
                            refColsList.Add($"\"{col.Trim()}\"");
                        }

                        string parentCols = string.Join(", ", parentColsList);
                        string refCols = string.Join(", ", refColsList);

                        string fkSql = $"ALTER TABLE \"{fk.ParentTable}\" ADD CONSTRAINT \"{fk.Name}\" FOREIGN KEY ({parentCols}) REFERENCES \"{fk.ReferencedTable}\" ({refCols});";
                        using (var cmd = pgConn.CreateCommand())
                        {
                            cmd.CommandText = fkSql;
                            cmd.ExecuteNonQuery();
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"WARNING: Failed to create Foreign Key {fk.Name} on {fk.ParentTable}: {ex.Message}");
                    }
                }
            }
        }

        private string? MapDefaultValue(string? mssqlDefault, string pgType)
        {
            if (string.IsNullOrEmpty(mssqlDefault)) return null;

            string cleaned = mssqlDefault.Trim();
            while (cleaned.StartsWith("(") && cleaned.EndsWith(")"))
            {
                cleaned = cleaned.Substring(1, cleaned.Length - 2).Trim();
            }

            if (cleaned.Equals("getdate()", StringComparison.OrdinalIgnoreCase) || 
                cleaned.Equals("getutcdate()", StringComparison.OrdinalIgnoreCase))
            {
                return "CURRENT_TIMESTAMP";
            }
            if (cleaned.Equals("newid()", StringComparison.OrdinalIgnoreCase))
            {
                return "gen_random_uuid()";
            }
            if (cleaned.Equals("null", StringComparison.OrdinalIgnoreCase))
            {
                return "NULL";
            }

            if (pgType.Equals("BOOLEAN", StringComparison.OrdinalIgnoreCase))
            {
                if (cleaned == "1" || cleaned.Equals("'true'", StringComparison.OrdinalIgnoreCase) || cleaned.Equals("true", StringComparison.OrdinalIgnoreCase))
                    return "true";
                if (cleaned == "0" || cleaned.Equals("'false'", StringComparison.OrdinalIgnoreCase) || cleaned.Equals("false", StringComparison.OrdinalIgnoreCase))
                    return "false";
            }

            return cleaned;
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
            public string? DefaultValue { get; set; }
        }
    }
}

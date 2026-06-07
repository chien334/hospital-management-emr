#!/usr/bin/env python3
import sys
import os
import json
import re
import traceback

# Add current directory to python path for robust importing
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

try:
    from converter import (
        clean_mssql_syntax,
        strip_standalone_select_parentheses,
        convert_mssql_procedure_to_postgresql,
        try_compile,
        convert_postgresql_to_mssql,
        tokenize_sql,
        convert_pg_identifiers_quotes,
        convert_pg_variable_names,
        convert_limit_to_select_top_tokens,
        convert_pg_into_assignments_tokens,
        convert_pg_temp_tables,
        convert_pg_control_flow
    )
except ImportError as e:
    sys.stderr.write(f"[ERROR] Failed to import modules: {str(e)}\n")
    sys.stderr.flush()

def log(msg):
    sys.stderr.write(f"[LOG] {msg}\n")
    sys.stderr.flush()

def main():
    log("SQL Server to PostgreSQL Converter MCP Server starting up...")
    
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            
            # Parse JSON-RPC request
            try:
                request = json.loads(line)
            except json.JSONDecodeError:
                log(f"Invalid JSON received: {repr(line)}")
                continue
                
            req_id = request.get("id")
            method = request.get("method")
            params = request.get("params", {})
            
            if method == "initialize":
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {}
                        },
                        "serverInfo": {
                            "name": "sqlserver-to-postgresql-mcp",
                            "version": "1.0.0"
                        }
                    }
                }
            elif method == "notifications/initialized":
                continue
            elif method == "tools/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "tools": [
                            {
                                "name": "convert_procedure",
                                "description": "Convert a complete T-SQL CREATE PROCEDURE block to a PostgreSQL CREATE OR REPLACE FUNCTION statement using standard mapping, variable renaming, control flow conversion, and schema corrections.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "sql": {
                                            "type": "string",
                                            "description": "The complete SQL Server T-SQL procedure code."
                                        },
                                        "verify": {
                                            "type": "boolean",
                                            "description": "Whether to verify compilation of the converted code in the target PostgreSQL database."
                                        }
                                    },
                                    "required": ["sql"]
                                }
                            },
                            {
                                "name": "convert_query_fragment",
                                "description": "Convert a standalone T-SQL query fragment (e.g. SELECT TOP, string concat, etc.) to PostgreSQL syntax.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "sql": {
                                            "type": "string",
                                            "description": "The T-SQL fragment to convert."
                                        }
                                    },
                                    "required": ["sql"]
                                }
                            },
                            {
                                "name": "verify_compilation",
                                "description": "Verify the compilation of PostgreSQL function SQL code in the target database.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "pg_sql": {
                                            "type": "string",
                                            "description": "The PostgreSQL function code (PL/pgSQL)."
                                        },
                                        "func_name": {
                                            "type": "string",
                                            "description": "Optional function name to DROP before verification."
                                        }
                                    },
                                    "required": ["pg_sql"]
                                }
                            },
                            {
                                "name": "convert_postgres_procedure",
                                "description": "Convert a complete PostgreSQL CREATE FUNCTION block (PL/pgSQL) to a SQL Server T-SQL CREATE PROCEDURE or CREATE FUNCTION statement.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "sql": {
                                            "type": "string",
                                            "description": "The complete PostgreSQL function code."
                                        }
                                    },
                                    "required": ["sql"]
                                }
                            },
                            {
                                "name": "convert_postgres_query_fragment",
                                "description": "Convert a standalone PostgreSQL query fragment (e.g. string concat, limit, cast, etc.) to SQL Server T-SQL syntax.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "sql": {
                                            "type": "string",
                                            "description": "The PL/pgSQL or Postgres SQL fragment to convert."
                                        }
                                    },
                                    "required": ["sql"]
                                }
                            }
                        ]
                    }
                }
            elif method == "tools/call":
                tool_name = params.get("name")
                arguments = params.get("arguments", {})
                
                if tool_name == "convert_procedure":
                    sql_code = arguments.get("sql", "")
                    should_verify = arguments.get("verify", False)
                    try:
                        converted = convert_mssql_procedure_to_postgresql(sql_code)
                        
                        if should_verify:
                            ok, err = try_compile(converted)
                            status_str = "SUCCESS" if ok else f"FAILED - {err.strip()}"
                            output_text = f"--- CONVERTED POSTGRESQL CODE ---\n{converted}\n\n--- VERIFICATION RESULTS ---\nCompilation: {status_str}"
                        else:
                            output_text = converted
                            
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": output_text
                                }
                            ]
                        }
                    except Exception as e:
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Error during procedure conversion: {str(e)}\n{traceback.format_exc()}"
                                }
                            ],
                            "isError": True
                        }
                elif tool_name == "convert_query_fragment":
                    sql_code = arguments.get("sql", "")
                    try:
                        converted = clean_mssql_syntax(sql_code)
                        converted = strip_standalone_select_parentheses(converted)
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": converted
                                }
                            ]
                        }
                    except Exception as e:
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Error during query fragment conversion: {str(e)}\n{traceback.format_exc()}"
                                }
                            ],
                            "isError": True
                        }
                elif tool_name == "verify_compilation":
                    pg_sql = arguments.get("pg_sql", "")
                    func_name = arguments.get("func_name", None)
                    try:
                        ok, err = try_compile(pg_sql, func_name)
                        status_str = "SUCCESS" if ok else f"FAILED - {err.strip()}"
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Compilation verification: {status_str}"
                                }
                            ],
                            "isError": not ok
                        }
                    except Exception as e:
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Error during compilation verification: {str(e)}\n{traceback.format_exc()}"
                                }
                            ],
                            "isError": True
                        }
                elif tool_name == "convert_postgres_procedure":
                    sql_code = arguments.get("sql", "")
                    try:
                        converted = convert_postgresql_to_mssql(sql_code)
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": converted
                                }
                            ]
                        }
                    except Exception as e:
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Error during Postgres procedure conversion: {str(e)}\n{traceback.format_exc()}"
                                }
                            ],
                            "isError": True
                        }
                elif tool_name == "convert_postgres_query_fragment":
                    sql_code = arguments.get("sql", "")
                    try:
                        tokens = tokenize_sql(sql_code)
                        tokens = convert_pg_identifiers_quotes(tokens)
                        tokens = convert_pg_variable_names(tokens)
                        tokens = convert_pg_into_assignments_tokens(tokens)
                        tokens = convert_limit_to_select_top_tokens(tokens)
                        converted = "".join(t[1] for t in tokens)
                        converted = convert_pg_temp_tables(converted)
                        converted = convert_pg_control_flow(converted)
                        
                        # Apply scalar mappings
                        converted = re.sub(r'(\([^)]+\)|@?\w+)::date\b', r'CONVERT(DATE, \1)', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'(\([^)]+\)|@?\w+)::varchar\b', r'CAST(\1 AS VARCHAR)', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'(\([^)]+\)|@?\w+)::int\b', r'CAST(\1 AS INT)', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'(\([^)]+\)|@?\w+)::numeric\b', r'CAST(\1 AS NUMERIC)', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'(\([^)]+\)|@?\w+)::text\b', r'CAST(\1 AS VARCHAR(MAX))', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'\|\|', '+', converted)
                        converted = re.sub(r'\bnow\(\)', 'GETDATE()', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'\bcurrent_timestamp\b', 'GETDATE()', converted, flags=re.IGNORECASE)
                        converted = re.sub(r'\bcoalesce\b', 'ISNULL', converted, flags=re.IGNORECASE)
                        
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": converted
                                }
                            ]
                        }
                    except Exception as e:
                        result = {
                            "content": [
                                {
                                    "type": "text",
                                    "text": f"Error during Postgres query fragment conversion: {str(e)}\n{traceback.format_exc()}"
                                }
                            ],
                            "isError": True
                        }
                else:
                    response = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {
                            "code": -32601,
                            "message": f"Tool not found: {tool_name}"
                        }
                    }
                    sys.stdout.write(json.dumps(response) + "\n")
                    sys.stdout.flush()
                    continue
                
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": result
                }
            else:
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {
                        "code": -32601,
                        "message": f"Method not found: {method}"
                    }
                }
                
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
            
        except Exception as e:
            log(f"Exception in main loop: {str(e)}\n{traceback.format_exc()}")

if __name__ == '__main__':
    main()

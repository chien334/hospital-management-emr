# SQL Server to PostgreSQL Converter MCP Server

Đây là một Model Context Protocol (MCP) server độc lập cho phép các Agent Coding Tool (Cursor, Windsurf, Claude Desktop, v.v.) gọi công cụ tự động chuyển đổi stored procedure/function hai chiều giữa SQL Server (T-SQL) và PostgreSQL (PL/pgSQL).

## Tính năng nổi bật

1. **Chuyển đổi Stored Procedure/Function hai chiều (Bidirectional)**:
   - **SQL Server sang PostgreSQL**: Tự động chuyển đổi biến (`@` -> `v_`/`p_`), con trỏ kết quả (`refcursor`), đệ quy `FOR JSON PATH`, `PIVOT`, `XML PATH`, v.v.
   - **PostgreSQL sang SQL Server**: Chuyển đổi khai báo Postgres `DECLARE` thành T-SQL `DECLARE`, dịch biến (`p_`/`v_` -> `@`), đổi kiểu dữ liệu (`BOOLEAN` -> `BIT`, `TIMESTAMP` -> `DATETIME`), chuyển ngược `LIMIT` thành `SELECT TOP`, dịch phép ghép chuỗi `||` -> `+`, gán assignments `SELECT ... INTO` -> `SELECT @var = ...`, và bảng tạm `#temp`.
2. **Xác thực Biên dịch PostgreSQL**: Sử dụng Docker container PostgreSQL chạy thử biên dịch trực tiếp mã PL/pgSQL đầu ra.
3. **Chạy qua giao thức Stdio**: Tương thích hoàn toàn với chuẩn MCP qua luồng input/output chuẩn, không yêu cầu cài đặt thêm các thư viện bên thứ ba.

---

## Danh sách công cụ (MCP Tools)

### 1. `convert_procedure`
Chuyển đổi toàn bộ khối mã nguồn `CREATE PROCEDURE` (T-SQL) thành mã PostgreSQL PL/pgSQL tương ứng.
- **Tham số**:
  - `sql` (string, bắt buộc): Mã nguồn MSSQL Stored Procedure.
  - `verify` (boolean, tùy chọn): Cấu hình `true` để tự động biên dịch thử vào DB PostgreSQL và trả về kết quả biên dịch.

### 2. `convert_query_fragment`
Dịch nhanh một đoạn truy vấn SQL Server đơn lẻ (ví dụ: `SELECT TOP 10 ...`, string concatenation dạng `+`, v.v.) sang PostgreSQL.
- **Tham số**:
  - `sql` (string, bắt buộc): Đoạn mã SQL Server cần dịch.

### 3. `verify_compilation`
Biên dịch thử mã PostgreSQL PL/pgSQL trực tiếp trong DB PostgreSQL mục tiêu để kiểm tra cú pháp.
- **Tham số**:
  - `pg_sql` (string, bắt buộc): Khối mã nguồn PL/pgSQL PostgreSQL.
  - `func_name` (string, tùy chọn): Tên hàm cần tự động DROP trước khi tạo mới để tránh xung đột kiểu chữ ký (signature).

### 4. `convert_postgres_procedure`
Chuyển đổi toàn bộ khối mã nguồn `CREATE OR REPLACE FUNCTION` (PostgreSQL PL/pgSQL) thành mã SQL Server T-SQL `CREATE PROCEDURE` hoặc `CREATE FUNCTION` tương ứng.
- **Tham số**:
  - `sql` (string, bắt buộc): Mã nguồn PostgreSQL function.

### 5. `convert_postgres_query_fragment`
Dịch nhanh một đoạn truy vấn PostgreSQL đơn lẻ (ví dụ: `||`, `LIMIT`, `COALESCE`, cast `::int`, v.v.) sang SQL Server T-SQL.
- **Tham số**:
  - `sql` (string, bắt buộc): Đoạn mã PostgreSQL cần dịch.

---

## Các biến môi trường cấu hình (Environment Variables)

Các biến môi trường sau có thể được cấu hình cho tiến trình chạy MCP Server để tùy biến hành vi của bộ kiểm tra biên dịch DB:

| Biến môi trường | Giá trị mặc định | Mô tả |
| :--- | :--- | :--- |
| `PG_CONTAINER` | `pg-emr` | Tên Docker container chạy PostgreSQL |
| `PG_DB` | `danphe_emr` | Tên Database dùng để thử biên dịch |
| `PG_USER` | `postgres` | Username kết nối PostgreSQL |
| `RTK_PATH` | `/Users/macbbook/.local/bin/rtk` | Đường dẫn đến công cụ `rtk` (nếu không có sẽ gọi `docker` trực tiếp) |
| `MSSQL_DIR` | (Xem converter.py) | Thư mục chứa các tệp `.sql` của MSSQL (cho bulk migration) |
| `PG_DIR` | (Xem converter.py) | Thư mục đầu ra ghi tệp `.sql` của Postgres (cho bulk migration) |

---

## Hướng dẫn cấu hình trên các IDE / Agent Tools

### 1. Cursor IDE
Tru cập **Settings > Features > MCP** và bấm **+ Add New MCP Server**:
- **Name**: `sqlserver-to-postgresql-converter`
- **Type**: `command`
- **Command**:
  ```bash
  python3 /Users/macbbook/SourceCodes/hospital-management-emr/Database/sqlserver-to-postgresql-mcp/src/main.py
  ```

### 2. Windsurf (hoặc các IDE dựa trên VS Code sử dụng mcp_config.json)
Thêm cấu hình vào tệp `mcp_config.json` (thường nằm ở `~/.codeium/windsurf/mcp_config.json` hoặc trong workspace `.vscode/mcp_config.json`):
```json
{
  "mcpServers": {
    "sqlserver-to-postgresql": {
      "command": "python3",
      "args": ["/Users/macbbook/SourceCodes/hospital-management-emr/Database/sqlserver-to-postgresql-mcp/src/main.py"],
      "env": {
        "PG_CONTAINER": "pg-emr",
        "PG_DB": "danphe_emr",
        "PG_USER": "postgres"
      }
    }
  }
}
```

### 3. Claude Desktop App
Thêm cấu hình vào tệp cấu hình của Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "sqlserver-to-postgresql": {
      "command": "python3",
      "args": ["/Users/macbbook/SourceCodes/hospital-management-emr/Database/sqlserver-to-postgresql-mcp/src/main.py"]
    }
  }
}
```

---

## Kiểm tra vận hành nhanh (Quick Test)

Bạn có thể chạy thử lệnh sau trong terminal để kiểm thử phản hồi giao thức JSON-RPC của MCP Server:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | python3 /Users/macbbook/SourceCodes/hospital-management-emr/Database/sqlserver-to-postgresql-mcp/src/main.py
```

Kết quả trả về kỳ vọng (stdout):
```json
{"jsonrpc": "2.0", "id": 1, "result": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "serverInfo": {"name": "sqlserver-to-postgresql-mcp", "version": "1.0.0"}}}
```

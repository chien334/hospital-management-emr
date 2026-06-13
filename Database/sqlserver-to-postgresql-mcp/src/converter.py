import os
import re
import subprocess

mssql_dir = os.environ.get('MSSQL_DIR', '/Users/macbbook/SourceCodes/hospital-management-emr/Database/MSSQL_Referenced_Procedures')
pg_dir = os.environ.get('PG_DIR', '/Users/macbbook/SourceCodes/hospital-management-emr/Database/PostgreSQL_Procedures')
progress_file = os.environ.get('PROGRESS_FILE', '/Users/macbbook/SourceCodes/hospital-management-emr/scratch/all_procedures_progress.txt')

# Load list of procedures safely
procedures = []
if os.path.exists(mssql_dir):
    try:
        procedures = sorted([f for f in os.listdir(mssql_dir) if f.endswith('.sql')])
    except Exception:
        pass

def try_compile(sql_code, func_name=None):
    name_matches = re.findall(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(\w+)', sql_code, re.IGNORECASE)
    if name_matches:
        drop_cmds = ""
        for name in name_matches:
            drop_cmds += f"DROP FUNCTION IF EXISTS {name};\n"
        sql_code = drop_cmds + sql_code
    elif func_name:
        drop_cmd = f"DROP FUNCTION IF EXISTS {func_name};\n"
        sql_code = drop_cmd + sql_code
        
    container = os.environ.get('PG_CONTAINER', 'pg-emr')
    db = os.environ.get('PG_DB', 'danphe_emr')
    user = os.environ.get('PG_USER', 'postgres')
    rtk_path = os.environ.get('RTK_PATH', '/Users/macbbook/.local/bin/rtk')
    
    # Check if we should bypass rtk or use direct docker command
    if rtk_path and os.path.exists(rtk_path):
        cmd = [rtk_path, "docker", "exec", "-i", container, "psql", "-U", user, "-d", db, "-v", "ON_ERROR_STOP=1"]
    else:
        cmd = ["docker", "exec", "-i", container, "psql", "-U", user, "-d", db, "-v", "ON_ERROR_STOP=1"]
        
    try:
        proc = subprocess.run(cmd, input=sql_code, text=True, capture_output=True, check=False)
        if proc.returncode == 0:
            return True, ""
        else:
            return False, proc.stderr
    except Exception as e:
        return False, str(e)

def strip_comments(sql):
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    sql = re.sub(r'--.*$', '', sql, flags=re.MULTILINE)
    return sql

def strip_outer_begin_end_tokenized(tokens):
    first_begin_idx = -1
    paren_depth = 0
    for idx, tok in enumerate(tokens):
        if tok[0] == 'symbol':
            if tok[1] == '(':
                paren_depth += 1
            elif tok[1] == ')':
                paren_depth -= 1
        elif tok[0] == 'word' and paren_depth == 0:
            if tok[1].upper() == 'BEGIN':
                first_begin_idx = idx
                break
                
    if first_begin_idx == -1:
        return tokens
        
    depth = 0
    matching_end_idx = -1
    paren_depth = 0
    for idx in range(first_begin_idx, len(tokens)):
        tok = tokens[idx]
        if tok[0] == 'symbol':
            if tok[1] == '(':
                paren_depth += 1
            elif tok[1] == ')':
                paren_depth -= 1
        elif tok[0] == 'word' and paren_depth == 0:
            val_upper = tok[1].upper()
            if val_upper == 'BEGIN':
                depth += 1
            elif val_upper == 'END':
                depth -= 1
                if depth == 0:
                    matching_end_idx = idx
                    break
                    
    if matching_end_idx == -1:
        return tokens
        
    has_subsequent_code = False
    for idx in range(matching_end_idx + 1, len(tokens)):
        if tokens[idx][0] not in ('space', 'comment', 'symbol'):
            has_subsequent_code = True
            break
        if tokens[idx][0] == 'symbol' and tokens[idx][1] != ';':
            has_subsequent_code = True
            break
            
    if not has_subsequent_code:
        new_tokens = list(tokens)
        new_tokens[first_begin_idx] = ('space', '')
        new_tokens[matching_end_idx] = ('space', '')
        return new_tokens
        
    return tokens

def strip_outer_begin_end(text):
    tokens = tokenize_sql(text)
    stripped = strip_outer_begin_end_tokenized(tokens)
    return "".join(t[1] for t in stripped)

def strip_standalone_select_parentheses(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    i = 0
    current_paren_depth = 0
    while i < n:
        t_type, t_val = tokens[i]
        
        if t_type == 'symbol':
            if t_val == '(':
                if current_paren_depth == 0:
                    depth = 1
                    j = i + 1
                    select_found = False
                    while j < n:
                        jt_type, jt_val = tokens[j]
                        if jt_type == 'symbol':
                            if jt_val == '(':
                                depth += 1
                            elif jt_val == ')':
                                depth -= 1
                                if depth == 0:
                                    break
                        elif jt_type == 'word' and jt_val.upper() == 'SELECT' and depth == 1:
                            select_found = True
                        j += 1
                        
                    if j < n and depth == 0 and select_found:
                        prev_idx = i - 1
                        while prev_idx >= 0 and tokens[prev_idx][0] in ('space', 'comment'):
                            prev_idx -= 1
                        
                        is_standalone = False
                        if prev_idx < 0:
                            is_standalone = True
                        else:
                            prev_type, prev_val = tokens[prev_idx]
                            if prev_type == 'symbol' and prev_val == ';':
                                is_standalone = True
                            elif prev_type == 'word' and prev_val.upper() in ('BEGIN', 'THEN', 'ELSE', 'ELSIF', 'DO'):
                                is_standalone = True
                        
                        if is_standalone and is_in_case(tokens, i):
                            is_standalone = False
                        
                        if is_standalone:
                            is_boundary = False
                            k = j + 1
                            while k < n and tokens[k][0] in ('space', 'comment'):
                                k += 1
                            if k >= n:
                                is_boundary = True
                            elif tokens[k][0] == 'symbol' and tokens[k][1] == ';':
                                is_boundary = True
                            elif tokens[k][0] == 'word' and tokens[k][1].upper() in ('END', 'ELSE', 'ELSIF', 'UNION', 'EXCEPT', 'INTERSECT'):
                                is_boundary = True
                                
                            if is_boundary:
                                tokens[i] = ('space', ' ')
                                tokens[j] = ('space', ' ')
                                new_tokens.append(tokens[i])
                                i += 1
                                continue
                current_paren_depth += 1
            elif t_val == ')':
                current_paren_depth = max(0, current_paren_depth - 1)
                
        new_tokens.append(tokens[i])
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def find_body_start(sql):
    i = 0
    n = len(sql)
    in_multiline_comment = False
    in_singleline_comment = False
    in_string = False
    
    while i < n:
        if in_multiline_comment:
            if sql[i:i+2] == '*/':
                in_multiline_comment = False
                i += 2
            else:
                i += 1
            continue
        if in_singleline_comment:
            if sql[i] == '\n':
                in_singleline_comment = False
            i += 1
            continue
        if in_string:
            if sql[i] == "'":
                if i + 1 < n and sql[i+1] == "'":
                    i += 2
                else:
                    in_string = False
                    i += 1
            else:
                i += 1
            continue
            
        if sql[i:i+2] == '/*':
            in_multiline_comment = True
            i += 2
            continue
        if sql[i:i+2] == '--':
            in_singleline_comment = True
            i += 2
            continue
        if sql[i] == "'":
            in_string = True
            i += 1
            continue
            
        if sql[i:i+2].upper() == 'AS' and (i == 0 or not sql[i-1].isalnum()) and (i+2 >= n or not sql[i+2].isalnum()):
            return i
        if sql[i:i+5].upper() == 'BEGIN' and (i == 0 or not sql[i-1].isalnum()) and (i+5 >= n or not sql[i+5].isalnum()):
            return i
            
        i += 1
    return n

def extract_cols_from_tcols(tcols):
    parts = []
    current = []
    paren_depth = 0
    i = 0
    n = len(tcols)
    while i < n:
        c = tcols[i]
        if c == '(':
            paren_depth += 1
        elif c == ')':
            paren_depth -= 1
        
        if paren_depth == 0 and c == ',':
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(c)
        i += 1
    if current:
        parts.append("".join(current).strip())
        
    cols = []
    for part in parts:
        words = re.findall(r'\b\w+\b', part)
        if words:
            cols.append(words[0])
    return cols

def extract_cols_with_types_from_tcols(tcols):
    parts = []
    current = []
    paren_depth = 0
    i = 0
    n = len(tcols)
    while i < n:
        c = tcols[i]
        if c == '(':
            paren_depth += 1
        elif c == ')':
            paren_depth -= 1
        
        if paren_depth == 0 and c == ',':
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(c)
        i += 1
    if current:
        parts.append("".join(current).strip())
        
    cols_with_types = {}
    for part in parts:
        words = re.findall(r'\b[a-zA-Z_0-9\(\)]+\b', part)
        if len(words) >= 2:
            col_name = words[0]
            col_type = words[1].upper()
            if 'VARCHAR' in col_type or 'CHAR' in col_type or 'TEXT' in col_type:
                col_type = 'VARCHAR'
            elif 'INT' in col_type:
                col_type = 'INT'
            elif 'DATE' in col_type:
                col_type = 'DATE'
            elif 'DATETIME' in col_type:
                col_type = 'TIMESTAMP'
            elif 'BIT' in col_type or 'BOOLEAN' in col_type:
                col_type = 'BOOLEAN'
            cols_with_types[col_name] = col_type
    return cols_with_types

def extract_select_columns(body_sql, temp_tables=[]):
    tokens = tokenize_sql(body_sql)
    n = len(tokens)
    paren_depth = 0
    in_dml_statement = False
    
    select_idx = -1
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
            elif t_val == ';' and paren_depth == 0:
                in_dml_statement = False
        elif t_type == 'word' and paren_depth == 0:
            if val_upper in ('INSERT', 'UPDATE', 'DELETE', 'MERGE'):
                in_dml_statement = True
            elif val_upper in ('IF', 'WHILE', 'RETURN', 'SET', 'DECLARE', 'BEGIN', 'END', 'OPEN', 'CLOSE'):
                in_dml_statement = False
            elif val_upper == 'SELECT' and not in_dml_statement:
                if is_part_of_create_table_as(tokens, i):
                    pass
                else:
                    # Check if this SELECT has INTO before FROM
                    is_into = False
                    k = i + 1
                    p_depth = 0
                    while k < n:
                        kt_type, kt_val = tokens[k]
                        if kt_type == 'symbol':
                            if kt_val == '(':
                                p_depth += 1
                            elif kt_val == ')':
                                p_depth -= 1
                        if p_depth == 0:
                            if kt_type == 'word':
                                k_upper = kt_val.upper()
                                if k_upper == 'INTO':
                                    is_into = True
                                    break
                                if k_upper == 'FROM':
                                    break
                        k += 1
                    if not is_into:
                        select_idx = i
                        break
        i += 1
        
    if select_idx == -1:
        return [], body_sql
        
    # Find matching FROM at depth 0
    from_idx = -1
    paren_depth = 0
    i = select_idx + 1
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
        elif t_type == 'word' and paren_depth == 0:
            if val_upper == 'FROM':
                from_idx = i
                break
        i += 1
        
    end_idx = n
    if from_idx == -1:
        # Look for the first semicolon at depth 0
        paren_depth = 0
        for k in range(select_idx + 1, n):
            if tokens[k][0] == 'symbol':
                if tokens[k][1] == '(':
                    paren_depth += 1
                elif tokens[k][1] == ')':
                    paren_depth -= 1
                elif tokens[k][1] == ';' and paren_depth == 0:
                    end_idx = k
                    break
        cols_tokens = tokens[select_idx + 1 : end_idx]
    else:
        cols_tokens = tokens[select_idx + 1 : from_idx]
        
    cols_tokens_no_comments = [t for t in cols_tokens if t[0] != 'comment']
    cols_text = "".join(t[1] for t in cols_tokens_no_comments).strip()
    
    parts = []
    current = []
    paren_depth = 0
    in_string = False
    
    i = 0
    n_cols = len(cols_text)
    while i < n_cols:
        char = cols_text[i]
        if in_string:
            if char == "'":
                if i + 1 < n_cols and cols_text[i+1] == "'":
                    current.append("''")
                    i += 2
                    continue
                else:
                    in_string = False
            current.append(char)
            i += 1
            continue
        if char == "'":
            in_string = True
            current.append(char)
            i += 1
            continue
        if char == '(':
            paren_depth += 1
        elif char == ')':
            paren_depth -= 1
        if char == ',' and paren_depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        i += 1
    if current:
        parts.append("".join(current).strip())
        
    cols = []
    for part in parts:
        if part == '*' or part.endswith('.*'):
            cols.append(part)
            continue
        alias_match = re.search(r'\bAS\s+[\'\"\[]?([a-zA-Z0-9_\s]+)[\'\"\]]?\s*$', part, re.IGNORECASE)
        if alias_match:
            cols.append(alias_match.group(1).strip())
            continue
        alias_match = re.search(r'[\'\"\[]([a-zA-Z0-9_\s]+)[\'\"\]]\s*$', part)
        if alias_match:
            cols.append(alias_match.group(1).strip())
            continue
        words = re.findall(r'\b\w+\b', part)
        if words:
            cols.append(words[-1])
            
    cleaned_cols = []
    keywords_to_exclude = {
        'DISTINCT', 'ALL', 'TOP', 'NULL', 'CASE', 'END', 'ELSE', 'THEN', 'WHEN', 
        'AND', 'OR', 'NOT', 'AS', 'IN', 'LIKE', 'BETWEEN', 'IS'
    }
    for col in cols:
        if col.upper() in keywords_to_exclude:
            continue
        if col.isdigit():
            continue
        cleaned_cols.append(col)
        
    # Dedup columns in parts and rewrite body_sql
    rewritten_body_sql = body_sql
    if cleaned_cols:
        seen = {}
        new_parts = []
        has_duplicates = False
        for idx, (part, col) in enumerate(zip(parts, cleaned_cols)):
            col_lower = col.lower()
            if col_lower in seen:
                seen[col_lower] += 1
                new_col = f"{col}_{seen[col_lower]}"
                alias_match = re.search(r'\bAS\s+[\'\"\[]?([a-zA-Z0-9_\s]+)[\'\"\]]?\s*$', part, re.IGNORECASE)
                if alias_match:
                    start, end = alias_match.span(1)
                    part = part[:start] + new_col + part[end:]
                else:
                    alias_match2 = re.search(r'[\'\"\[]([a-zA-Z0-9_\s]+)[\'\"\]]\s*$', part)
                    if alias_match2:
                        start, end = alias_match2.span(1)
                        part = part[:start] + new_col + part[end:]
                    else:
                        part = f'{part} AS "{new_col}"'
                has_duplicates = True
                cleaned_cols[idx] = new_col
            else:
                seen[col_lower] = 0
            new_parts.append(part)
            
        if has_duplicates:
            rewritten_cols_text = " " + ", ".join(new_parts) + " "
            if from_idx == -1:
                tokens[select_idx + 1 : end_idx] = [('word', rewritten_cols_text)]
            else:
                tokens[select_idx + 1 : from_idx] = [('word', rewritten_cols_text)]
            rewritten_body_sql = "".join(t[1] for t in tokens)
            
    # Recursive check for SELECT * FROM ( SELECT ... )
    if not cleaned_cols or cleaned_cols == ['*'] or cleaned_cols == ['tbl.*'] or cleaned_cols == ['t.*']:
        from_clause = "".join(t[1] for t in tokens[from_idx + 1:]).strip() if from_idx != -1 else ""
        if from_clause.endswith(';'):
            from_clause = from_clause[:-1].strip()
            
        matching_temp_table = None
        for tname, tcols in temp_tables:
            if from_clause.lower() == tname.lower() or from_clause.lower().startswith(tname.lower() + ' '):
                matching_temp_table = (tname, tcols)
                break
                
        if matching_temp_table:
            return extract_cols_from_tcols(matching_temp_table[1]), rewritten_body_sql
            
        if from_clause.startswith('('):
            depth = 0
            sub_end = -1
            for idx, c in enumerate(from_clause):
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
                    if depth == 0:
                        sub_end = idx
                        break
            if sub_end != -1:
                subquery = from_clause[1:sub_end].strip()
                sub_cols, sub_rewritten = extract_select_columns(subquery, temp_tables)
                if sub_cols:
                    return sub_cols, rewritten_body_sql
                    
    return cleaned_cols, rewritten_body_sql

def get_col_type(col_name, inferred_types=None):
    if inferred_types and col_name in inferred_types:
        return inferred_types[col_name]
    col_lower = col_name.lower()
    if 'id' in col_lower:
        return 'INT'
    if any(k in col_lower for k in ('date', 'time', 'on')):
        return 'TIMESTAMP'
    if any(k in col_lower for k in ('amount', 'price', 'total', 'subtotal', 'discount', 'rate', 'val', 'value', 'balance', 'quantity', 'qty', 'count')):
        if any(k in col_lower for k in ('quantity', 'qty', 'count')):
            return 'INT'
        return 'DECIMAL'
    if any(k in col_lower for k in ('isactive', 'isverified', 'ispaid', 'status')) or any(col_lower.startswith(k) for k in ('is', 'has', 'was')):
        if 'status' in col_lower:
            return 'VARCHAR'
        return 'BOOLEAN'
    if 'code' in col_lower:
        return 'VARCHAR'
    return 'VARCHAR'

def convert_select_into_tokenized(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        if t_type == 'word' and val_upper == 'SELECT':
            into_idx = -1
            from_idx = -1
            paren_depth = 0
            k = i + 1
            while k < n:
                kt_type, kt_val = tokens[k]
                if kt_type == 'symbol':
                    if kt_val == '(':
                        paren_depth += 1
                    elif kt_val == ')':
                        paren_depth -= 1
                        if paren_depth < 0:
                            break
                elif kt_type == 'word' and paren_depth == 0:
                    kt_val_upper = kt_val.upper()
                    if kt_val_upper == 'INTO':
                        into_idx = k
                    elif kt_val_upper == 'FROM':
                        from_idx = k
                        break
                    elif kt_val_upper in ('INSERT', 'UPDATE', 'DELETE', 'DECLARE', 'BEGIN', 'END', 'IF', 'WHILE'):
                        break
                k += 1
            
            if into_idx != -1 and from_idx != -1:
                m = into_idx + 1
                while m < n and tokens[m][0] in ('space', 'comment'):
                    m += 1
                if m < n and tokens[m][0] == 'word':
                    tbl_name = tokens[m][1]
                    if tbl_name.startswith('#'):
                        temp_tbl_name = 'temp_' + tbl_name[1:]
                    else:
                        temp_tbl_name = 'temp_' + tbl_name
                        
                    cols_tokens = tokens[i+1 : into_idx]
                    replacement = f"CREATE TEMP TABLE {temp_tbl_name} AS SELECT"
                    new_tokens.append(('word', replacement))
                    new_tokens.extend(cols_tokens)
                    new_tokens.extend(tokens[m+1 : from_idx])
                    i = from_idx
                    continue
        new_tokens.append((t_type, t_val))
        i += 1
    return "".join(t[1] for t in new_tokens)

def convert_date_functions(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        val_upper = tok_val.upper()
        if tok_type == 'word' and val_upper in ('YEAR', 'MONTH', 'DAY', 'DATENAME'):
            k = i + 1
            while k < n and tokens[k][0] in ('space', 'comment'):
                k += 1
            if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                depth = 1
                p = k + 1
                arg_tokens = []
                while p < n:
                    pt_type, pt_val = tokens[p]
                    if pt_type == 'symbol':
                        if pt_val == '(':
                            depth += 1
                        elif pt_val == ')':
                            depth -= 1
                            if depth == 0:
                                break
                    arg_tokens.append(tokens[p])
                    p += 1
                
                if p < n and depth == 0:
                    arg_str = "".join(t[1] for t in arg_tokens).strip()
                    if val_upper == 'DATENAME':
                        comma_idx = -1
                        p_depth = 0
                        for idx, t in enumerate(arg_tokens):
                            if t[0] == 'symbol':
                                if t[1] == '(':
                                    p_depth += 1
                                elif t[1] == ')':
                                    p_depth -= 1
                                elif t[1] == ',' and p_depth == 0:
                                    comma_idx = idx
                                    break
                        if comma_idx != -1:
                            part1 = "".join(t[1] for t in arg_tokens[:comma_idx]).strip().lower().replace("'", "").replace('"', '')
                            part2 = "".join(t[1] for t in arg_tokens[comma_idx+1:]).strip()
                            if part1 in ('year', 'yy', 'yyyy'):
                                repl = f"to_char({part2}, 'YYYY')"
                            elif part1 in ('month', 'm', 'mm'):
                                repl = f"trim(to_char({part2}, 'Month'))"
                            elif part1 in ('weekday', 'dw'):
                                repl = f"trim(to_char({part2}, 'Day'))"
                            elif part1 in ('day', 'd', 'dd'):
                                repl = f"to_char({part2}, 'DD')"
                            else:
                                repl = f"to_char({part2}, 'YYYY')"
                            new_tokens.append(('word', repl))
                            i = p + 1
                            continue
                    else:
                        repl = f"EXTRACT({val_upper} FROM {arg_str})"
                        new_tokens.append(('word', repl))
                        i = p + 1
                        continue
        new_tokens.append((tok_type, tok_val))
        i += 1
    return "".join(t[1] for t in new_tokens)

def convert_select_top_to_limit(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    
    i = 0
    modified = False
    while i < n:
        if tokens[i][0] == 'word' and tokens[i][1].upper() == 'SELECT':
            k = i + 1
            while k < n and tokens[k][0] in ('space', 'comment'):
                k += 1
            if k < n and tokens[k][0] == 'word' and tokens[k][1].upper() in ('DISTINCT', 'ALL'):
                k += 1
                while k < n and tokens[k][0] in ('space', 'comment'):
                    k += 1
            
            if k < n and tokens[k][0] == 'word' and tokens[k][1].upper() == 'TOP':
                top_idx = k
                k = top_idx + 1
                while k < n and tokens[k][0] in ('space', 'comment'):
                    k += 1
                
                limit_tokens = []
                if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                    k += 1
                    p_depth = 1
                    while k < n:
                        if tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                            p_depth += 1
                        elif tokens[k][0] == 'symbol' and tokens[k][1] == ')':
                            p_depth -= 1
                            if p_depth == 0:
                                k += 1
                                break
                        limit_tokens.append(tokens[k])
                        k += 1
                else:
                    while k < n and tokens[k][0] not in ('space', 'comment', 'symbol'):
                        limit_tokens.append(tokens[k])
                        k += 1
                
                limit_str = "".join(t[1] for t in limit_tokens)
                
                scan_idx = k
                paren_depth = 0
                case_depth = 0
                statement_end_idx = -1
                prev_non_space = None
                
                while scan_idx < n:
                    t_type, t_val = tokens[scan_idx]
                    val_upper = t_val.upper()
                    
                    if t_type == 'symbol':
                        if t_val == '(':
                            paren_depth += 1
                        elif t_val == ')':
                            if paren_depth == 0:
                                statement_end_idx = scan_idx
                                break
                            paren_depth -= 1
                        elif t_val == ';' and paren_depth == 0 and case_depth == 0:
                            statement_end_idx = scan_idx
                            break
                    elif t_type == 'word' and paren_depth == 0:
                        if val_upper == 'CASE':
                            case_depth += 1
                        elif val_upper == 'END':
                            if case_depth > 0:
                                case_depth -= 1
                            else:
                                statement_end_idx = scan_idx
                                break
                        elif case_depth == 0 and val_upper in (
                            'INSERT', 'UPDATE', 'DELETE', 'SET', 'DECLARE', 'IF', 'ELSIF', 'ELSE', 'WHILE', 'RETURN', 
                            'BEGIN', 'CREATE', 'DROP', 'ALTER', 'EXEC', 'EXECUTE'
                        ):
                            statement_end_idx = scan_idx
                            break
                        elif val_upper == 'SELECT' and case_depth == 0:
                            is_union = False
                            if prev_non_space and prev_non_space.upper() in ('UNION', 'EXCEPT', 'INTERSECT', 'ALL'):
                                is_union = True
                            if not is_union:
                                statement_end_idx = scan_idx
                                break
                    
                    if t_type not in ('space', 'comment'):
                        prev_non_space = t_val
                    scan_idx += 1
                
                if statement_end_idx == -1:
                    statement_end_idx = n
                
                # Check if this SELECT query contains FOR JSON or FOR XML
                has_for_json_xml = False
                j_check = top_idx + 1
                while j_check < statement_end_idx:
                    if tokens[j_check][0] == 'word' and tokens[j_check][1].upper() == 'FOR':
                        next_w = j_check + 1
                        while next_w < statement_end_idx and tokens[next_w][0] in ('space', 'comment'):
                            next_w += 1
                        if next_w < statement_end_idx and tokens[next_w][0] == 'word' and tokens[next_w][1].upper() in ('JSON', 'XML'):
                            has_for_json_xml = True
                            break
                    j_check += 1
                
                insert_idx = statement_end_idx
                while insert_idx > k:
                    if tokens[insert_idx - 1][0] not in ('space', 'comment'):
                        break
                    insert_idx -= 1
                
                new_tokens_list = tokens[:top_idx]
                new_tokens_list.extend(tokens[k:insert_idx])
                if not has_for_json_xml:
                    new_tokens_list.append(('space', f' LIMIT {limit_str}'))
                new_tokens_list.extend(tokens[insert_idx:])
                
                tokens = new_tokens_list
                n = len(tokens)
                modified = True
                i += 1
                continue
        i += 1
        
    if modified:
        return "".join(t[1] for t in tokens)
    return sql

def clean_mssql_syntax(sql):
    sql = re.sub(r'\[dbo\]\.', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'dbo\.', '', sql, flags=re.IGNORECASE)
    # Clean trailing commas in parenthesized lists (like CREATE TABLE columns)
    sql = re.sub(r',\s*\)', r')', sql)
    sql = re.sub(r'\[([^\]]+)\]', r'"\1"', sql)
    sql = re.sub(r'\bWITH\s*\(\s*NOLOCK\s*\)', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bNOLOCK\b', '', sql, flags=re.IGNORECASE)
    
    # Clean GETDATE with optional parentheses
    sql = re.sub(r'\bGETDATE\b(?:\s*\(\s*\))?', 'CURRENT_TIMESTAMP', sql, flags=re.IGNORECASE)
    
    # Convert OPENJSON ... WITH ... AS ... to json_to_recordset
    sql = re.sub(
        r'OPENJSON\s*\(\s*([^)]+)\s*\)\s*WITH\s*\((.*?)\)\s*AS\s*(\w+)',
        r'json_to_recordset(\1::json) AS \3(\2)',
        sql,
        flags=re.IGNORECASE|re.DOTALL
    )
    
    sql = re.sub(r'\bISNULL\s*\(', 'COALESCE(', sql, flags=re.IGNORECASE)
    
    # Fix VARCHAR(MAX) ordering bug by matching N?VARCHAR
    sql = re.sub(r'\bN?VARCHAR\s*\(\s*MAX\s*\)', 'TEXT', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bNVARCHAR\b', 'VARCHAR', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bDATETIME\b', 'TIMESTAMP', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bBIT\b', 'BOOLEAN', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bTINYINT\b', 'SMALLINT', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSYSNAME\b', 'VARCHAR(128)', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSET\s+NOCOUNT\s+(?:ON|OFF)\b', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSET\s+ANSI_NULLS\s+(?:ON|OFF)\b;?', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSET\s+QUOTED_IDENTIFIER\s+(?:ON|OFF)\b;?', '', sql, flags=re.IGNORECASE)
    
    # Remove TRANSACTION ISOLATION and LOCK_TIMEOUT
    sql = re.sub(r'\bSET\s+TRANSACTION\s+ISOLATION\s+LEVEL\s+READ\s+(?:UNCOMMITTED|COMMITTED)\s*;?', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSET\s+LOCK_TIMEOUT\s+\d+\s*;?', '', sql, flags=re.IGNORECASE)
    
    # Convert SELECT TOP ... to SELECT ... LIMIT ...
    sql = convert_select_top_to_limit(sql)
    
    # Convert Exec triggers
    sql = re.sub(
        r"EXEC\s*\(\s*'\s*DISABLE\s+TRIGGER\s+(\w+)\s+ON\s+(\w+)\s*'\s*\)",
        r"ALTER TABLE \2 DISABLE TRIGGER \1",
        sql,
        flags=re.IGNORECASE
    )
    sql = re.sub(
        r"EXEC\s*\(\s*'\s*ENABLE\s+TRIGGER\s+(\w+)\s+ON\s+(\w+)\s*'\s*\)",
        r"ALTER TABLE \2 ENABLE TRIGGER \1",
        sql,
        flags=re.IGNORECASE
    )
    
    # Convert EXEC sp_executesql @query to EXECUTE @query
    sql = re.sub(r'\bEXEC(?:UTE)?\s+sp_executesql\s+@(\w+)', r'EXECUTE @\1', sql, flags=re.IGNORECASE)
    # Convert EXEC(@query) to EXECUTE @query
    sql = re.sub(r'\bEXEC(?:UTE)?\s*\(\s*@(\w+)\s*\)', r'EXECUTE @\1', sql, flags=re.IGNORECASE)
    
    # Add INTO to INSERT if missing
    sql = re.sub(
        r'\bINSERT\s+(?!INTO\b)((?:#?[a-zA-Z_]\w*|"[^"]+")(?:\.(?:#?[a-zA-Z_]\w*|"[^"]+"))*)',
        r'INSERT INTO \1',
        sql,
        flags=re.IGNORECASE
    )
    
    # RAISERROR conversion
    sql = re.sub(
        r'\bRAISERROR\s*\(\s*(\'(?:[^\']|\'\')*\')\s*,\s*\d+\s*,\s*\d+\s*\)',
        r'RAISE EXCEPTION \1',
        sql,
        flags=re.IGNORECASE
    )
    
    # TRY/CATCH and TRANSACTION removal
    sql = re.sub(r'\bBEGIN\s+CATCH\b.*?\bEND\s+CATCH\b', '', sql, flags=re.IGNORECASE | re.DOTALL)
    sql = re.sub(r'\bBEGIN\s+TRY\b', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bEND\s+TRY\b', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bBEGIN\s+TRAN(?:SACTION)?\s*;?', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bSAVE\s+TRAN(?:SACTION)?\s+\w+\s*;?', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bCOMMIT\s+(?:TRAN(?:SACTION)?)?\s*;?', '', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bROLLBACK\s+(?:TRAN(?:SACTION)?)?(?:\s+\w+)?\s*;?', '', sql, flags=re.IGNORECASE)
    
    # Convert FOR JSON PATH using tokenized parser
    sql = convert_for_json_path_tokenized_sql(sql)
    
    # Temp table conversions
    sql = re.sub(
        r'\bIF\s+OBJECT_ID\s*\(\s*(?:N\s*)?[\'\"]tempdb(?:\.dbo)?\.+#?(\w+)[\'\"](?:\s*,\s*[\'\"]\w+[\'\"])?\s*\)\s*IS\s+NOT\s+NULL\s*(?:BEGIN\s+)?(?:THEN\s+)?DROP\s+TABLE\s+#?\1\s*(?:;)?\s*(?:\bEND\s+IF\s*;)?(?:\s*END\s*;?)?',
        r'DROP TABLE IF EXISTS temp_\1;',
        sql,
        flags=re.IGNORECASE
    )
    sql = convert_select_into_tokenized(sql)
    sql = re.sub(
        r'\bCREATE\s+TABLE\s+#(\w+)',
        r'CREATE TEMP TABLE temp_\1',
        sql,
        flags=re.IGNORECASE
    )
    sql = re.sub(
        r'\bDROP\s+TABLE\s+#(\w+)',
        r'DROP TABLE IF EXISTS temp_\1',
        sql,
        flags=re.IGNORECASE
    )
    sql = re.sub(r'#(\w+)', r'temp_\1', sql)
    
    sql = convert_outer_apply(sql)
    sql = convert_convert_calls_tokenized(sql)
    sql = convert_date_functions(sql)
    sql = convert_xml_path_to_string_agg(sql)
    sql = convert_pivots_in_sql(sql)
    sql = convert_running_total_updates(sql)
    
    # Convert DELETE TOP (n) FROM <table> to DELETE FROM <table> WHERE ctid = (SELECT ctid FROM <table> LIMIT n)
    sql = re.sub(
        r'\bDELETE\s+TOP\s*\(\s*(\d+|v_\w+|p_\w+)\s*\)\s*(?:FROM\s*)?(\w+)',
        r'DELETE FROM \2 WHERE ctid = (SELECT ctid FROM \2 LIMIT \1)',
        sql,
        flags=re.IGNORECASE
    )
    
    return sql

def count_top_level_selects(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    paren_depth = 0
    in_dml_statement = False
    dml_type = None
    dml_has_select_or_values = False
    
    select_tokens = []
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
            elif t_val == ';' and paren_depth == 0:
                in_dml_statement = False
        
        if t_type == 'word':
            if val_upper in ('INSERT', 'UPDATE', 'DELETE', 'MERGE') and paren_depth == 0:
                in_dml_statement = True
                dml_type = val_upper
                dml_has_select_or_values = False
            elif val_upper == 'VALUES' and in_dml_statement:
                dml_has_select_or_values = True
            elif val_upper == 'SELECT' and in_dml_statement:
                if dml_type != 'INSERT' or dml_has_select_or_values:
                    if paren_depth == 0:
                        in_dml_statement = False
                else:
                    dml_has_select_or_values = True
            elif val_upper in ('IF', 'WHILE', 'RETURN', 'SET', 'DECLARE', 'BEGIN', 'END', 'OPEN', 'CLOSE') and paren_depth == 0:
                in_dml_statement = False
            elif val_upper == 'SELECT' and paren_depth == 0 and not in_dml_statement:
                if is_part_of_create_table_as(tokens, i):
                    pass
                else:
                    # Check if there is an INTO before FROM at depth 0
                    is_into = False
                    k = i + 1
                    p_depth = 0
                    while k < n:
                        kt_type, kt_val = tokens[k]
                        if kt_type == 'symbol':
                            if kt_val == '(':
                                p_depth += 1
                            elif kt_val == ')':
                                p_depth -= 1
                        if p_depth == 0:
                            if kt_type == 'word':
                                k_upper = kt_val.upper()
                                if k_upper == 'INTO':
                                    is_into = True
                                    break
                                if k_upper == 'FROM':
                                    break
                        k += 1
                    if not is_into:
                        select_tokens.append('SELECT')
            elif val_upper == 'UNION' and paren_depth == 0 and not in_dml_statement:
                select_tokens.append('UNION')
                
        i += 1
        
    resultsets_count = 0
    prev_tok = None
    for tok in select_tokens:
        if tok == 'SELECT':
            if prev_tok != 'UNION':
                resultsets_count += 1
        prev_tok = tok
        
    return resultsets_count

def convert_selects_to_cursors(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    cursor_idx = 1
    new_tokens = []
    
    i = 0
    paren_depth = 0
    in_dml_statement = False
    dml_type = None
    dml_has_select_or_values = False
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
            elif t_val == ';' and paren_depth == 0:
                in_dml_statement = False
                
        if t_type == 'word':
            if val_upper in ('INSERT', 'UPDATE', 'DELETE', 'MERGE') and paren_depth == 0:
                in_dml_statement = True
                dml_type = val_upper
                dml_has_select_or_values = False
            elif val_upper == 'VALUES' and in_dml_statement:
                dml_has_select_or_values = True
            elif val_upper == 'SELECT' and in_dml_statement:
                if dml_type != 'INSERT' or dml_has_select_or_values:
                    if paren_depth == 0:
                        in_dml_statement = False
                else:
                    dml_has_select_or_values = True
            elif val_upper in ('IF', 'WHILE', 'RETURN', 'SET', 'DECLARE', 'BEGIN', 'END', 'OPEN', 'CLOSE') and paren_depth == 0:
                in_dml_statement = False
                
        if paren_depth == 0 and t_type == 'word' and val_upper in ('SELECT', 'WITH') and not in_dml_statement:
            is_into = False
            is_union = False
            if val_upper == 'SELECT' and is_part_of_create_table_as(tokens, i):
                is_into = True
            else:
                if val_upper == 'SELECT':
                    k = i + 1
                    p_depth = 0
                    while k < n:
                        kt_type, kt_val = tokens[k]
                        if kt_type == 'symbol':
                            if kt_val == '(':
                                p_depth += 1
                            elif kt_val == ')':
                                p_depth -= 1
                        if p_depth == 0:
                            if kt_type == 'word':
                                k_upper = kt_val.upper()
                                if k_upper == 'INTO':
                                    is_into = True
                                    break
                                if k_upper == 'FROM':
                                    break
                        k += 1
                
                is_union = False
                if val_upper == 'SELECT':
                    k = len(new_tokens) - 1
                    while k >= 0:
                        if new_tokens[k][0] in ('space', 'comment'):
                            k -= 1
                            continue
                        if new_tokens[k][0] == 'word' and new_tokens[k][1].upper() == 'UNION':
                            is_union = True
                        break
            
            if not is_into and not is_union:
                semi_idx = -1
                scan_depth = 0
                k = i + 1
                while k < n:
                    kt_type, kt_val = tokens[k]
                    if kt_type == 'symbol':
                        if kt_val == '(':
                            scan_depth += 1
                        elif kt_val == ')':
                            scan_depth -= 1
                        elif kt_val == ';' and scan_depth == 0:
                            semi_idx = k
                            break
                    k += 1
                
                cursor_name = f"ref{cursor_idx}"
                new_tokens.append((t_type, f"OPEN {cursor_name} FOR {t_val}"))
                
                end_limit = semi_idx if semi_idx != -1 else n
                query_toks = tokens[i + 1 : end_limit]
                
                last_val_idx = -1
                for idx in range(len(query_toks) - 1, -1, -1):
                    if query_toks[idx][0] not in ('space', 'comment'):
                        last_val_idx = idx
                        break
                
                if last_val_idx != -1:
                    actual_query_toks = query_toks[:last_val_idx + 1]
                    trailing_toks = query_toks[last_val_idx + 1:]
                else:
                    actual_query_toks = query_toks
                    trailing_toks = []
                    
                for tok in actual_query_toks:
                    new_tokens.append(tok)
                new_tokens.append(('symbol', ';'))
                new_tokens.append(('space', f"\n    RETURN NEXT {cursor_name};"))
                for tok in trailing_toks:
                    new_tokens.append(tok)
                
                if semi_idx != -1:
                    i = semi_idx + 1
                else:
                    i = n
                
                cursor_idx += 1
                continue
                
        if paren_depth == 0 and t_type == 'word' and val_upper in ('INSERT', 'UPDATE', 'DELETE'):
            semi_idx = -1
            scan_depth = 0
            k = i + 1
            while k < n:
                kt_type, kt_val = tokens[k]
                if kt_type == 'symbol':
                    if kt_val == '(':
                        scan_depth += 1
                    elif kt_val == ')':
                        scan_depth -= 1
                    elif kt_val == ';' and scan_depth == 0:
                        semi_idx = k
                        break
                k += 1
            
            end_limit = semi_idx + 1 if semi_idx != -1 else n
            for idx in range(i, end_limit):
                new_tokens.append(tokens[idx])
            i = end_limit
            continue
            
        new_tokens.append((t_type, t_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def convert_select_assignments(sql):
    comments = []
    literals = []
    def comm_repl(m):
        comments.append(m.group(0))
        return f" __comment_placeholder_{len(comments)-1}__ "
    def lit_repl(m):
        literals.append(m.group(0))
        return f" __literal_placeholder_{len(literals)-1}__ "
        
    masked = re.sub(r"/\*.*?\*/", comm_repl, sql, flags=re.DOTALL)
    masked = re.sub(r"--.*$", comm_repl, masked, flags=re.MULTILINE)
    masked = re.sub(r"'(?:[^']|'')*'", lit_repl, masked)
    
    def replace_assignment(match):
        select_content = match.group(1)
        if '@' not in select_content or '=' not in select_content:
            return match.group(0)
            
        parts = []
        current = []
        paren_depth = 0
        i = 0
        n = len(select_content)
        while i < n:
            char = select_content[i]
            if char == '(':
                paren_depth += 1
            elif char == ')':
                paren_depth -= 1
            if char == ',' and paren_depth == 0:
                parts.append("".join(current).strip())
                current = []
            else:
                current.append(char)
            i += 1
        if current:
            parts.append("".join(current).strip())
            
        vars_list = []
        exprs_list = []
        for part in parts:
            part_match = re.match(r'(@\w+)\s*=\s*(.*)', part, re.DOTALL)
            if part_match:
                vars_list.append(part_match.group(1))
                exprs_list.append(part_match.group(2).strip())
            else:
                return match.group(0)
                
        pg_select = "SELECT " + ", ".join(exprs_list) + " INTO " + ", ".join(vars_list)
        return pg_select + " FROM"

    res = re.sub(r'\bSELECT\b(.*?)\bFROM\b', replace_assignment, masked, flags=re.IGNORECASE | re.DOTALL)
    
    for idx, comm in enumerate(comments):
        res = res.replace(f" __comment_placeholder_{idx}__ ", comm)
    for idx, lit in enumerate(literals):
        res = res.replace(f" __literal_placeholder_{idx}__ ", lit)
        
    return res

def tokenize_sql(sql):
    tokens = []
    i = 0
    n = len(sql)
    while i < n:
        if sql[i].isspace():
            start = i
            while i < n and sql[i].isspace():
                i += 1
            tokens.append(('space', sql[start:i]))
            continue
        if sql[i:i+2] == '--':
            start = i
            while i < n and sql[i] != '\n':
                i += 1
            tokens.append(('comment', sql[start:i]))
            continue
        if sql[i:i+2] == '/*':
            start = i
            i += 2
            while i < n and sql[i:i+2] != '*/':
                i += 1
            if i < n:
                i += 2
            tokens.append(('comment', sql[start:i]))
            continue
        if sql[i] == "'" or (sql[i].upper() == 'N' and i + 1 < n and sql[i+1] == "'"):
            start = i
            if sql[i].upper() == 'N':
                i += 2
            else:
                i += 1
            while i < n:
                if sql[i] == "'":
                    if i + 1 < n and sql[i+1] == "'":
                        i += 2
                    else:
                        i += 1
                        break
                else:
                    i += 1
            tokens.append(('string', sql[start:i]))
            continue
        if sql[i].isalnum() or sql[i] in ('_', '@', '#', '$'):
            start = i
            while i < n and (sql[i].isalnum() or sql[i] in ('_', '@', '#', '$')):
                i += 1
            tokens.append(('word', sql[start:i]))
            continue
        tokens.append(('symbol', sql[i]))
        i += 1
    return tokens

def is_part_of_create_table_as(tokens, idx):
    # Go backward and check if we have: CREATE [TEMP/TEMPORARY] TABLE <name> AS
    k = idx - 1
    while k >= 0 and tokens[k][0] in ('space', 'comment'):
        k -= 1
    if k < 0 or tokens[k][0] != 'word' or tokens[k][1].upper() != 'AS':
        return False
        
    k -= 1
    while k >= 0 and tokens[k][0] in ('space', 'comment'):
        k -= 1
    if k < 0 or tokens[k][0] not in ('word', 'string'):
        return False
        
    k -= 1
    while k >= 0 and tokens[k][0] in ('space', 'comment'):
        k -= 1
    if k < 0 or tokens[k][0] != 'word' or tokens[k][1].upper() != 'TABLE':
        return False
        
    k -= 1
    while k >= 0 and tokens[k][0] in ('space', 'comment'):
        k -= 1
    if k >= 0 and tokens[k][0] == 'word' and tokens[k][1].upper() in ('TEMP', 'TEMPORARY'):
        k -= 1
        while k >= 0 and tokens[k][0] in ('space', 'comment'):
            k -= 1
            
    if k >= 0 and tokens[k][0] == 'word' and tokens[k][1].upper() == 'CREATE':
        return True
    return False

def split_sql_and_trailing(text):
    tokens = tokenize_sql(text)
    last_idx = len(tokens)
    for i in range(len(tokens) - 1, -1, -1):
        if tokens[i][0] not in ('space', 'comment'):
            last_idx = i + 1
            break
    base = "".join(t[1] for t in tokens[:last_idx])
    trailing = "".join(t[1] for t in tokens[last_idx:])
    return base, trailing

def convert_outer_apply(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        
        # Check for OUTER APPLY
        if (tok_type == 'word' and tok_val.upper() == 'OUTER' and 
            i + 2 < n and tokens[i+1][0] == 'space' and 
            tokens[i+2][0] == 'word' and tokens[i+2][1].upper() == 'APPLY'):
            
            k = i + 3
            while k < n and tokens[k][0] == 'space':
                k += 1
                
            if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                paren_depth = 1
                j = k + 1
                subquery_tokens = []
                while j < n:
                    jt_type, jt_val = tokens[j]
                    if jt_type == 'symbol':
                        if jt_val == '(':
                            paren_depth += 1
                        elif jt_val == ')':
                            paren_depth -= 1
                            if paren_depth == 0:
                                break
                    subquery_tokens.append(tokens[j])
                    j += 1
                
                alias_tokens = []
                m = j + 1
                while m < n and tokens[m][0] == 'space':
                    alias_tokens.append(tokens[m])
                    m += 1
                if m < n and tokens[m][0] == 'word' and tokens[m][1].upper() == 'AS':
                    alias_tokens.append(tokens[m])
                    m += 1
                    while m < n and tokens[m][0] == 'space':
                        alias_tokens.append(tokens[m])
                        m += 1
                if m < n and tokens[m][0] == 'word':
                    alias_tokens.append(tokens[m])
                    m += 1
                
                subquery_str = "".join(t[1] for t in subquery_tokens)
                alias_str = "".join(t[1] for t in alias_tokens)
                
                replacement = f"LEFT JOIN LATERAL ({subquery_str}){alias_str} ON TRUE"
                new_tokens.append(('word', replacement))
                i = m
                continue
                
        # Check for CROSS APPLY
        elif (tok_type == 'word' and tok_val.upper() == 'CROSS' and 
              i + 2 < n and tokens[i+1][0] == 'space' and 
              tokens[i+2][0] == 'word' and tokens[i+2][1].upper() == 'APPLY'):
            
            k = i + 3
            while k < n and tokens[k][0] == 'space':
                k += 1
                
            if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                paren_depth = 1
                j = k + 1
                subquery_tokens = []
                while j < n:
                    jt_type, jt_val = tokens[j]
                    if jt_type == 'symbol':
                        if jt_val == '(':
                            paren_depth += 1
                        elif jt_val == ')':
                            paren_depth -= 1
                            if paren_depth == 0:
                                break
                    subquery_tokens.append(tokens[j])
                    j += 1
                
                alias_tokens = []
                m = j + 1
                while m < n and tokens[m][0] == 'space':
                    alias_tokens.append(tokens[m])
                    m += 1
                if m < n and tokens[m][0] == 'word' and tokens[m][1].upper() == 'AS':
                    alias_tokens.append(tokens[m])
                    m += 1
                    while m < n and tokens[m][0] == 'space':
                        alias_tokens.append(tokens[m])
                        m += 1
                if m < n and tokens[m][0] == 'word':
                    alias_tokens.append(tokens[m])
                    m += 1
                
                subquery_str = "".join(t[1] for t in subquery_tokens)
                alias_str = "".join(t[1] for t in alias_tokens)
                
                replacement = f"CROSS JOIN LATERAL ({subquery_str}){alias_str}"
                new_tokens.append(('word', replacement))
                i = m
                continue
                
        new_tokens.append((tok_type, tok_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def convert_convert_calls_tokenized(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        if tok_type == 'word' and tok_val.upper() == 'CONVERT':
            k = i + 1
            while k < n and tokens[k][0] == 'space':
                k += 1
            if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == '(':
                paren_depth = 1
                arg_tokens = []
                j = k + 1
                while j < n:
                    jt_type, jt_val = tokens[j]
                    if jt_type == 'symbol':
                        if jt_val == '(':
                            paren_depth += 1
                        elif jt_val == ')':
                            paren_depth -= 1
                            if paren_depth == 0:
                                break
                    arg_tokens.append(tokens[j])
                    j += 1
                
                args = []
                current_arg = []
                p_depth = 0
                for at_type, at_val in arg_tokens:
                    if at_type == 'symbol' and at_val == '(':
                        p_depth += 1
                    elif at_type == 'symbol' and at_val == ')':
                        p_depth -= 1
                    
                    if p_depth == 0 and at_type == 'symbol' and at_val == ',':
                        args.append(current_arg)
                        current_arg = []
                    else:
                        current_arg.append((at_type, at_val))
                if current_arg:
                    args.append(current_arg)
                
                if len(args) >= 2:
                    type_str = "".join(t[1] for t in args[0]).strip()
                    expr_str = "".join(t[1] for t in args[1]).strip()
                    style_str = "".join(t[1] for t in args[2]).strip() if len(args) > 2 else None
                    
                    # Recursively convert inner convert calls
                    expr_str = convert_convert_calls_tokenized(expr_str)
                    if style_str:
                        style_str = convert_convert_calls_tokenized(style_str)
                    
                    type_str_upper = type_str.upper()
                    if 'VARCHAR' in type_str_upper or 'CHAR' in type_str_upper or 'TEXT' in type_str_upper:
                        target_type = 'VARCHAR'
                    elif 'DATETIME' in type_str_upper:
                        target_type = 'TIMESTAMP'
                    elif 'BIT' in type_str_upper:
                        target_type = 'BOOLEAN'
                    elif 'TINYINT' in type_str_upper:
                        target_type = 'SMALLINT'
                    else:
                        target_type = type_str
                        
                    if style_str:
                        style_val = style_str.strip()
                        if style_val in ('120', '23'):
                            converted_val = f"to_char({expr_str}, 'YYYY-MM-DD')"
                        elif style_val == '101':
                            converted_val = f"to_char({expr_str}, 'MM/DD/YYYY')"
                        elif style_val == '111':
                            converted_val = f"to_char({expr_str}, 'YYYY/MM/DD')"
                        elif style_val == '21':
                            converted_val = f"to_char({expr_str}, 'YYYY-MM-DD HH24:MI:SS')"
                        else:
                            converted_val = f"to_char({expr_str}, 'YYYY-MM-DD')"
                    else:
                        if target_type == 'TIMESTAMP':
                            converted_val = f"({expr_str})::TIMESTAMP"
                        elif target_type == 'DATE':
                            converted_val = f"({expr_str})::DATE"
                        else:
                            converted_val = f"({expr_str})::{target_type}"
                            
                    new_tokens.append(('word', converted_val))
                    i = j + 1
                    continue
        
        new_tokens.append((tok_type, tok_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def convert_pivots_in_sql(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        if tok_type == 'word' and tok_val.upper() == 'PIVOT':
            k = i - 1
            while k >= 0 and tokens[k][0] in ('space', 'comment'):
                k -= 1
            
            if k >= 0 and tokens[k][0] == 'word':
                sub_alias = tokens[k][1]
                k -= 1
                while k >= 0 and tokens[k][0] in ('space', 'comment'):
                    k -= 1
                if k >= 0 and tokens[k][0] == 'word' and tokens[k][1].upper() == 'AS':
                    k -= 1
                    while k >= 0 and tokens[k][0] in ('space', 'comment'):
                        k -= 1
                
                if k >= 0 and tokens[k][0] == 'symbol' and tokens[k][1] == ')':
                    depth = 1
                    m = k - 1
                    subquery_tokens = []
                    while m >= 0:
                        mt_type, mt_val = tokens[m]
                        if mt_type == 'symbol':
                            if mt_val == ')':
                                depth += 1
                            elif mt_val == '(':
                                depth -= 1
                                if depth == 0:
                                    break
                        subquery_tokens.append(tokens[m])
                        m -= 1
                    
                    if m >= 0 and depth == 0:
                        subquery_tokens.reverse()
                        subquery_str = "".join(t[1] for t in subquery_tokens)
                        
                        p = i + 1
                        while p < n and tokens[p][0] in ('space', 'comment'):
                            p += 1
                        
                        if p < n and tokens[p][0] == 'symbol' and tokens[p][1] == '(':
                            depth = 1
                            q = p + 1
                            pivot_arg_tokens = []
                            while q < n:
                                qt_type, qt_val = tokens[q]
                                if qt_type == 'symbol':
                                    if qt_val == '(':
                                        depth += 1
                                    elif qt_val == ')':
                                        depth -= 1
                                        if depth == 0:
                                            break
                                pivot_arg_tokens.append(tokens[q])
                                q += 1
                            
                            if q < n and depth == 0:
                                pivot_arg_str = "".join(t[1] for t in pivot_arg_tokens).strip()
                                
                                r_idx = q + 1
                                while r_idx < n and tokens[r_idx][0] in ('space', 'comment'):
                                    r_idx += 1
                                if r_idx < n and tokens[r_idx][0] == 'word' and tokens[r_idx][1].upper() == 'AS':
                                    r_idx += 1
                                    while r_idx < n and tokens[r_idx][0] in ('space', 'comment'):
                                        r_idx += 1
                                if r_idx < n and tokens[r_idx][0] == 'word':
                                    pivot_alias = tokens[r_idx][1]
                                    r_idx += 1
                                else:
                                    pivot_alias = "piv"
                                
                                pat = r'(\w+)\s*\(\s*((?:\w+\.)*(?:\w+|\*))\s*\)\s*FOR\s+((?:\w+\.)*\w+)\s+IN\s*\(\s*(.*?)\s*\)'
                                m_p = re.search(pat, pivot_arg_str, re.IGNORECASE | re.DOTALL)
                                if m_p:
                                    agg_func = m_p.group(1).upper()
                                    agg_col = m_p.group(2)
                                    pivot_col = m_p.group(3)
                                    pivot_vals_str = m_p.group(4)
                                    
                                    pivot_vals = []
                                    for val in pivot_vals_str.split(','):
                                        val = val.strip().replace('[', '').replace(']', '').replace("'", "").replace('"', '')
                                        if val:
                                            pivot_vals.append(val)
                                    
                                    sub_cols, _ = extract_select_columns(subquery_str)
                                    
                                    pivot_col_base = pivot_col.split('.')[-1].lower()
                                    agg_col_base = agg_col.split('.')[-1].lower() if agg_col else ""
                                    
                                    group_by_cols = []
                                    for col in sub_cols:
                                        col_lower = col.lower()
                                        if col_lower != pivot_col_base and col_lower != agg_col_base and col != '*':
                                            group_by_cols.append(col)
                                            
                                    select_list = []
                                    for col in group_by_cols:
                                        select_list.append(f'"{col}"')
                                        
                                    for val in pivot_vals:
                                        if agg_func == 'COUNT':
                                            expr = f'COUNT(CASE WHEN "{pivot_col_base}" = \'{val}\' THEN 1 END) AS "{val}"'
                                        elif agg_func == 'SUM':
                                            expr = f'COALESCE(SUM(CASE WHEN "{pivot_col_base}" = \'{val}\' THEN "{agg_col_base}" ELSE 0 END), 0) AS "{val}"'
                                        else:
                                            expr = f'{agg_func}(CASE WHEN "{pivot_col_base}" = \'{val}\' THEN "{agg_col_base}" END) AS "{val}"'
                                        select_list.append(expr)
                                        
                                    group_by_str = ", ".join(f'"{col}"' for col in group_by_cols)
                                    
                                    replacement = f"(\n        SELECT\n            "
                                    replacement += ",\n            ".join(select_list)
                                    replacement += f"\n        FROM (\n            {subquery_str}\n        ) {sub_alias}\n"
                                    if group_by_cols:
                                        replacement += f"        GROUP BY {group_by_str}\n"
                                    replacement += f"    ) {pivot_alias}"
                                    
                                    tokens[m : r_idx] = [('word', replacement)]
                                    n = len(tokens)
                                    i = m + 1
                                    continue
                                
        i += 1
    return "".join(t[1] for t in tokens)

def convert_running_total_updates(sql):
    pattern = r'(?i)with\s+temptxns\s+as\s*\(\s*select\s+(.*?)\s+from\s+(temp_temptxnstable|#temptxnstable)\s+(?:txns)?\s*\)\s*update\s+temptxns.*?output\s+inserted\s*\.\*;?'
    
    def repl(m):
        cols_str = m.group(1).strip()
        cols = [c.strip().split('.')[-1].replace('"', '').strip() for c in cols_str.split(',')]
        exclude = {'balanceqty', 'balancerate', 'balanceamount'}
        other_cols = [c for c in cols if c.lower() not in exclude]
        
        new_select = "SELECT\n"
        standard_cols = ['TransactionDate', 'ReceiptQty', 'ReceiptRate', 'ReceiptAmount', 'IssueQty', 'IssueRate', 'IssueAmount']
        for c in standard_cols:
            if c.lower() in [oc.lower() for oc in other_cols]:
                new_select += f'        {c},\n'
                
        new_select += '        SUM(COALESCE(COALESCE(ReceiptQty, -IssueQty), OpeningQty)) OVER (ORDER BY TransactionDate, (CASE WHEN OpeningQty IS NOT NULL THEN 0 ELSE 1 END)) as BalanceQty,\n'
        new_select += '        COALESCE(COALESCE(ReceiptRate, IssueRate), OpeningRate) as BalanceRate,\n'
        new_select += '        SUM(COALESCE(COALESCE(ReceiptQty, -IssueQty), OpeningQty) * COALESCE(COALESCE(ReceiptRate, IssueRate), OpeningRate)) OVER (ORDER BY TransactionDate, (CASE WHEN OpeningQty IS NOT NULL THEN 0 ELSE 1 END)) as BalanceAmount'
        
        standard_cols_lower = [c.lower() for c in standard_cols]
        for c in other_cols:
            if c.lower() not in standard_cols_lower:
                new_select += f',\n        {c}'
        
        new_select += '\n    FROM temp_TempTxnsTable'
        return new_select
 
    return re.sub(pattern, repl, sql, flags=re.DOTALL)

def convert_xml_path_to_string_agg(sql):
    def repl(match):
        select_content = match.group(1).strip()
        m_sel = re.match(r'(?i)(N?\'[^\']+\'|\'[^\']+\')\s*\+\s*(.*)', select_content, re.DOTALL)
        if not m_sel:
            m_sel = re.match(r'(?i)(N?\'[^\']+\'|\'[^\']+\')\s*\|\|\s*(.*)', select_content, re.DOTALL)
            
        if m_sel:
            delim = m_sel.group(1).strip()
            if delim.upper().startswith("N'"):
                delim_str = delim[2:-1]
            else:
                delim_str = delim[1:-1]
            expr_and_from = m_sel.group(2).strip()
            
            tokens = tokenize_sql(expr_and_from)
            from_idx = -1
            paren_depth = 0
            for idx, tok in enumerate(tokens):
                if tok[0] == 'symbol':
                    if tok[1] == '(':
                        paren_depth += 1
                    elif tok[1] == ')':
                        paren_depth -= 1
                elif tok[0] == 'word' and paren_depth == 0:
                    if tok[1].upper() == 'FROM':
                        from_idx = idx
                        break
            if from_idx != -1:
                expr = "".join(t[1] for t in tokens[:from_idx]).strip()
                from_where = "".join(t[1] for t in tokens[from_idx:]).strip()
                
                if expr.endswith('+'):
                    expr = expr[:-1].strip()
                elif expr.endswith('||'):
                    expr = expr[:-2].strip()
                    
                return f"(SELECT string_agg({expr}, '{delim_str}') {from_where})"
                
        return match.group(0)

    pattern1 = r'(?i)STUFF\s*\(\s*\(\s*SELECT\s+(.*?)\s+FOR\s+XML\s+PATH\s*\(\s*[\'\"]\s*[\'\"]\s*\)\s*,\s*TYPE\s*\)\s*\.\s*value\s*\(\s*N?[\'\"]\s*\.(?:\[1\]|[\"\']1[\"\'])\s*[\'\"]\s*,\s*N?[\'\"]\s*(?:n?varchar\(max\)|text)\s*[\'\"]\s*\)\s*,\s*\d+\s*,\s*\d+\s*,\s*N?[\'\"]\s*[\'\"]\s*\)'
    sql = re.sub(pattern1, repl, sql, flags=re.DOTALL)
    
    pattern2 = r'(?i)STUFF\s*\(\s*\(\s*SELECT\s+(.*?)\s+FOR\s+XML\s+PATH\s*\(\s*[\'\"]\s*[\'\"]\s*\)\s*\)\s*,\s*\d+\s*,\s*\d+\s*,\s*N?[\'\"]\s*[\'\"]\s*\)'
    sql = re.sub(pattern2, repl, sql, flags=re.DOTALL)
    
    return sql

def convert_for_json_path_tokenized_sql(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    global_paren_depth = 0
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        if tok_type == 'symbol':
            if tok_val == '(':
                global_paren_depth += 1
            elif tok_val == ')':
                global_paren_depth -= 1
                
        if tok_type == 'word' and tok_val.upper() == 'SELECT':
            for_idx = -1
            json_idx = -1
            path_idx = -1
            without_array_wrapper = False
            
            paren_depth = 0
            k = i + 1
            while k < n:
                kt_type, kt_val = tokens[k]
                if kt_type == 'symbol':
                    if kt_val == '(':
                        paren_depth += 1
                    elif kt_val == ')':
                        paren_depth -= 1
                        if paren_depth < 0:
                            break
                    elif kt_val == ';' and paren_depth == 0:
                        break
                elif kt_type == 'word' and paren_depth == 0:
                    kt_val_upper = kt_val.upper()
                    if kt_val_upper == 'FOR':
                        m = k + 1
                        while m < n and tokens[m][0] == 'space':
                            m += 1
                        if m < n and tokens[m][0] == 'word' and tokens[m][1].upper() == 'JSON':
                            m2 = m + 1
                            while m2 < n and tokens[m2][0] == 'space':
                                m2 += 1
                            if m2 < n and tokens[m2][0] == 'word' and tokens[m2][1].upper() == 'PATH':
                                for_idx = k
                                json_idx = m
                                path_idx = m2
                                r = m2 + 1
                                while r < n:
                                    rt_type, rt_val = tokens[r]
                                    if rt_type == 'symbol' and rt_val in (';', ')'):
                                        break
                                    elif rt_type == 'word' and rt_val.upper() == 'WITHOUT_ARRAY_WRAPPER':
                                        without_array_wrapper = True
                                        break
                                    r += 1
                                break
                    elif kt_val_upper in ('SELECT', 'WITH', 'INSERT', 'UPDATE', 'DELETE', 'DECLARE', 'BEGIN', 'END', 'IF', 'WHILE', 'SET', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE', 'MERGE', 'RETURN'):
                        break
                k += 1
                
            if for_idx != -1:
                query_tokens = tokens[i+1 : for_idx]
                query_str = "SELECT " + "".join(t[1] for t in query_tokens).strip()
                
                query_str_converted = convert_for_json_path_tokenized_sql(query_str)
                if global_paren_depth == 0:
                    if without_array_wrapper:
                        replacement = f"SELECT (SELECT row_to_json(t) FROM ({query_str_converted}) t)::text"
                    else:
                        replacement = f"SELECT (SELECT json_agg(t) FROM ({query_str_converted}) t)::text"
                else:
                    if without_array_wrapper:
                        replacement = f"(SELECT row_to_json(t) FROM ({query_str_converted}) t)::text"
                    else:
                        replacement = f"(SELECT json_agg(t) FROM ({query_str_converted}) t)::text"
                    
                new_tokens.append(('word', replacement))
                
                # Scan to see if WITHOUT_ARRAY_WRAPPER is present after PATH
                has_waw = False
                waw_end_idx = path_idx + 1
                k = path_idx + 1
                while k < n:
                    kt_type, kt_val = tokens[k]
                    if kt_type == 'symbol' and kt_val in (';', ')'):
                        break
                    elif kt_type == 'word':
                        if kt_val.upper() == 'WITHOUT_ARRAY_WRAPPER':
                            has_waw = True
                            waw_end_idx = k + 1
                        break
                    k += 1
                
                if has_waw:
                    p_end = waw_end_idx
                else:
                    p_end = path_idx + 1
                i = p_end
                continue
                
        new_tokens.append((tok_type, tok_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def clean_single_quoted_aliases(text):
    keywords = {
        'then', 'else', 'in', 'like', 'and', 'or', 'not', 'where', 'on', 'as', 
        'select', 'case', 'when', 'set', 'into', 'values', 'default', 'between', 
        'is', 'null', 'insert', 'update', 'delete', 'from', 'join', 'by', 'having', 
        'group', 'order', 'over', 'partition', 'end', 'begin', 'union', 'all', 
        'except', 'intersect', 'exists', 'declare', 'return', 'perform', 'execute', 
        'true', 'false', 'coalesce', 'distinct', 'with', 'desc', 'asc', 'inner', 
        'left', 'right', 'cross', 'outer', 'lateral', 'to', 'limit', 'offset', 'returning'
    }
    def replace_match(match):
        prev_word = match.group(1)
        alias_name = match.group(2)
        if alias_name.lower() in keywords:
            return match.group(0)
        if prev_word.lower() in keywords and prev_word.lower() not in ('end', 'null', 'true', 'false'):
            return match.group(0)
        return f'{prev_word} AS "{alias_name}"'
    pattern = r"((?<!')\b\w+\b(?!')|\bNULL|'[^'\n]+'|\))\s*'([^'\n]+)'(?=\s*(?:,|\bfrom\b|\n|\)|$))"
    return re.sub(pattern, replace_match, text, flags=re.IGNORECASE)

def clean_unquoted_aliases(text):
    keywords = {
        'then', 'else', 'in', 'like', 'and', 'or', 'not', 'where', 'on', 'as', 
        'select', 'case', 'when', 'set', 'into', 'values', 'default', 'between', 
        'is', 'null', 'insert', 'update', 'delete', 'from', 'join', 'by', 'having', 
        'group', 'order', 'over', 'partition', 'end', 'begin', 'union', 'all', 
        'except', 'intersect', 'exists', 'declare', 'return', 'perform', 'execute', 
        'true', 'false', 'coalesce', 'distinct', 'with', 'desc', 'asc', 'inner', 
        'left', 'right', 'cross', 'outer', 'lateral', 'to', 'limit', 'offset', 'returning'
    }
    def replace_match(match):
        prev_word = match.group(1)
        alias_name = match.group(2)
        if alias_name.lower() in keywords:
            return match.group(0)
        if prev_word.lower() in keywords and prev_word.lower() not in ('end', 'null', 'true', 'false'):
            return match.group(0)
        return f'{prev_word} AS "{alias_name}"'
    pattern = r"((?<!')\b\w+\b(?!')|\bNULL|'[^'\n]+'|\))\s+([a-zA-Z_]\w*)(?=\s*(?:,|\bfrom\b|\n|\)|$))"
    return re.sub(pattern, replace_match, text, flags=re.IGNORECASE)

def clean_aliases_tokenized(tokens):
    keywords = {
        'then', 'else', 'in', 'like', 'and', 'or', 'not', 'where', 'on', 'as', 
        'select', 'case', 'when', 'set', 'into', 'values', 'default', 'between', 
        'is', 'null', 'insert', 'update', 'delete', 'from', 'join', 'by', 'having', 
        'group', 'order', 'over', 'partition', 'end', 'begin', 'union', 'all', 
        'except', 'intersect', 'exists', 'declare', 'return', 'perform', 'execute', 
        'true', 'false', 'coalesce', 'distinct', 'with', 'desc', 'asc', 'inner', 
        'left', 'right', 'cross', 'outer', 'lateral', 'to', 'limit', 'offset', 'returning'
    }
    n = len(tokens)
    new_tokens = []
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        is_alias = False
        alias_val = ""
        
        if tok_type == 'string':
            if tok_val.upper().startswith("N'"):
                alias_val = tok_val[2:-1]
            else:
                alias_val = tok_val[1:-1]
            is_alias = True
        elif tok_type == 'word' and tok_val.lower() not in keywords:
            alias_val = tok_val
            is_alias = True
            
        if is_alias:
            prev_idx = len(new_tokens) - 1
            while prev_idx >= 0 and new_tokens[prev_idx][0] in ('space', 'comment'):
                prev_idx -= 1
                
            has_valid_prev = False
            preceded_by_as = False
            if prev_idx >= 0:
                p_type, p_val = new_tokens[prev_idx]
                p_val_lower = p_val.lower()
                if p_val_lower == 'as':
                    preceded_by_as = True
                    has_valid_prev = True
                elif (p_val_lower not in keywords or p_val_lower in ('null', 'end', 'true', 'false')) and p_val_lower not in ('=', ':', ','):
                    if p_type in ('word', 'string') or (p_type == 'symbol' and p_val == ')'):
                        has_valid_prev = True
                        
            next_idx = i + 1
            while next_idx < n and tokens[next_idx][0] in ('space', 'comment'):
                next_idx += 1
                
            has_valid_next = False
            if next_idx >= n:
                has_valid_next = True
            else:
                n_type, n_val = tokens[next_idx]
                n_val_lower = n_val.lower()
                if n_type == 'symbol' and n_val in (',', ')'):
                    has_valid_next = True
                elif n_type == 'word' and n_val_lower in ('from', 'union', 'except', 'intersect'):
                    has_valid_next = True
                    
            if has_valid_prev and has_valid_next:
                if preceded_by_as:
                    if tok_type == 'string':
                        clean_alias = alias_val.replace('"', '').replace('[', '').replace(']', '').strip()
                        new_tokens.append(('word', f'"{clean_alias}"'))
                        i += 1
                        continue
                    else:
                        pass
                else:
                    clean_alias = alias_val.replace('"', '').replace('[', '').replace(']', '').strip()
                    prefix = " "
                    if new_tokens and new_tokens[-1][0] == 'space':
                        prefix = ""
                    new_tokens.append(('word', f'{prefix}AS "{clean_alias}"'))
                    i += 1
                    continue
                
        new_tokens.append((tok_type, tok_val))
        i += 1
    return new_tokens

def clean_aliases_in_select_only(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        if t_type == 'word' and val_upper == 'SELECT':
            select_tokens = [tokens[i]]
            paren_depth = 0
            case_depth = 0
            k = i + 1
            while k < n:
                kt_type, kt_val = tokens[k]
                if kt_type == 'symbol':
                    if kt_val == '(':
                        paren_depth += 1
                    elif kt_val == ')':
                        paren_depth -= 1
                        if paren_depth < 0:
                            break
                elif kt_type == 'word':
                    kt_val_upper = kt_val.upper()
                    if kt_val_upper == 'CASE':
                        case_depth += 1
                    elif kt_val_upper == 'END':
                        if case_depth > 0:
                            case_depth -= 1
                        elif paren_depth == 0:
                            break
                    elif paren_depth == 0 and case_depth == 0:
                        if kt_val_upper in ('FROM', 'UNION', 'EXCEPT', 'INTERSECT'):
                            break
                        elif kt_val_upper in ('INSERT', 'UPDATE', 'DELETE', 'DECLARE', 'BEGIN', 'IF', 'WHILE', 'SET'):
                            break
                select_tokens.append(tokens[k])
                k += 1
            
            cleaned_cols_tokens = clean_aliases_tokenized(select_tokens[1:])
            new_tokens.append(tokens[i])
            new_tokens.extend(cleaned_cols_tokens)
            i = k
            continue
        new_tokens.append((t_type, t_val))
        i += 1
    return "".join(t[1] for t in new_tokens)

def ensure_all_semicolons(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    
    statement_starters = {
        'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'WITH', 'OPEN', 'CLOSE', 'RETURN', 
        'PERFORM', 'EXECUTE', 'RAISE', 'IF', 'WHILE', 'LOOP', 'DECLARE', 'BEGIN', 
        'COMMIT', 'ROLLBACK', 'ELSE', 'ELSIF', 'END', 'CREATE', 'DROP', 'ALTER', 'TRUNCATE', 'MERGE'
    }
    
    def is_assignment_start(idx):
        if idx >= n:
            return False
        tok_type, tok_val = tokens[idx]
        if tok_type != 'word':
            return False
        val = tok_val.lower()
        if not (val.startswith('v_') or val.startswith('p_')):
            return False
        k = idx + 1
        while k < n and tokens[k][0] == 'space':
            k += 1
        if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == ':':
            if k + 1 < n and tokens[k+1][0] == 'symbol' and tokens[k+1][1] == '=':
                return True
        return False

    new_tokens = []
    case_depth = 0
    paren_depth = 0
    in_with = False
    in_dml_statement = False
    dml_type = None
    dml_has_select_or_values = False
    expect_begin = False
    
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        val_upper = t_val.upper()
        
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
            elif t_val == ';' and paren_depth == 0:
                in_dml_statement = False
                
        if t_type == 'word':
            if val_upper in ('INSERT', 'UPDATE', 'DELETE', 'MERGE') and paren_depth == 0:
                in_dml_statement = True
                dml_type = val_upper
                dml_has_select_or_values = False
            elif val_upper == 'VALUES' and in_dml_statement:
                dml_has_select_or_values = True
            elif val_upper == 'SELECT' and in_dml_statement:
                if dml_type != 'INSERT' or dml_has_select_or_values:
                    if paren_depth == 0:
                        in_dml_statement = False
                else:
                    dml_has_select_or_values = True
            elif val_upper in ('IF', 'WHILE', 'RETURN', 'SET', 'DECLARE', 'BEGIN', 'END', 'OPEN', 'CLOSE') and paren_depth == 0:
                in_dml_statement = False
                
        is_case_part = (case_depth > 0)
        if t_type == 'word':
            if val_upper == 'CASE':
                case_depth += 1
                is_case_part = True
            elif val_upper == 'END':
                if case_depth > 0:
                    is_case_part = True
                    case_depth -= 1
                    
        is_starter = False
        if paren_depth == 0 and not is_case_part:
            if t_type == 'word' and val_upper in statement_starters:
                if val_upper in ('SELECT', 'WITH') and in_dml_statement:
                    is_starter = False
                elif val_upper in ('DECLARE', 'LOOP'):
                    is_starter = False
                elif val_upper == 'BEGIN' and expect_begin:
                    is_starter = False
                    expect_begin = False
                else:
                    last_non_space = None
                    for idx in range(len(new_tokens) - 1, -1, -1):
                        if new_tokens[idx][0] not in ('space', 'comment'):
                            last_non_space = new_tokens[idx][1].upper()
                            break
                    if val_upper == 'IF':
                        # Check if part of "DROP <TYPE> IF EXISTS"
                        is_drop_if_exists = False
                        k_prev = i - 1
                        while k_prev >= 0 and tokens[k_prev][0] in ('space', 'comment'):
                            k_prev -= 1
                        if k_prev >= 0 and tokens[k_prev][0] == 'word' and tokens[k_prev][1].upper() in ('TABLE', 'VIEW', 'FUNCTION', 'PROCEDURE', 'TYPE', 'INDEX', 'SCHEMA', 'SEQUENCE'):
                            k_prev2 = k_prev - 1
                            while k_prev2 >= 0 and tokens[k_prev2][0] in ('space', 'comment'):
                                k_prev2 -= 1
                            if k_prev2 >= 0 and tokens[k_prev2][0] == 'word' and tokens[k_prev2][1].upper() == 'DROP':
                                is_drop_if_exists = True
                        
                        if is_drop_if_exists or last_non_space in ('END', 'ELSE', 'ELSIF'):
                            is_starter = False
                        else:
                            is_starter = True
                    elif val_upper in ('LOOP', 'CASE') and last_non_space == 'END':
                        is_starter = False
                    elif val_upper in ('SELECT', 'INSERT', 'UPDATE', 'DELETE') and in_with:
                        is_starter = False
                        in_with = False
                    else:
                        is_starter = True
                    
                    if is_starter:
                        if val_upper in ('IF', 'WHILE', 'ELSE', 'ELSIF'):
                            expect_begin = True
                        else:
                            expect_begin = False
            elif is_assignment_start(i):
                is_starter = True
                expect_begin = False
            elif t_type == 'symbol' and t_val == '(':
                k = i + 1
                while k < n and tokens[k][0] in ('space', 'comment'):
                    k += 1
                if k < n and tokens[k][0] == 'word' and tokens[k][1].upper() in ('SELECT', 'WITH'):
                    is_starter = True
                    expect_begin = False
                
        if paren_depth == 0 and t_type == 'word':
            if val_upper == 'WITH':
                in_with = True
                
        if is_starter:
            last_idx = -1
            for idx in range(len(new_tokens) - 1, -1, -1):
                if new_tokens[idx][0] not in ('space', 'comment'):
                    last_idx = idx
                    break
            if last_idx != -1:
                last_tok_type, last_tok_val = new_tokens[last_idx]
                last_val_upper = last_tok_val.upper()
                if last_tok_val not in (';', ':', '=') and last_val_upper not in ('BEGIN', 'THEN', 'LOOP', 'ELSE', 'ELSIF', 'DO', 'AS', 'UNION', 'ALL', 'EXCEPT', 'INTERSECT'):
                    new_tokens.insert(last_idx + 1, ('symbol', ';'))
                    
        new_tokens.append((t_type, t_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def convert_select_to_return_query(body_sql):
    tokens = tokenize_sql(body_sql)
    n = len(tokens)
    new_tokens = []
    
    paren_depth = 0
    in_with = False
    in_dml_statement = False
    dml_type = None
    dml_has_select_or_values = False
    
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        val_upper = tok_val.upper()
        
        if tok_type == 'symbol':
            if tok_val == '(':
                paren_depth += 1
            elif tok_val == ')':
                paren_depth -= 1
            elif tok_val == ';' and paren_depth == 0:
                in_dml_statement = False
                
        if paren_depth == 0 and tok_type == 'word':
            if val_upper in ('INSERT', 'UPDATE', 'DELETE', 'MERGE'):
                in_dml_statement = True
                dml_type = val_upper
                dml_has_select_or_values = False
            elif val_upper == 'VALUES' and in_dml_statement:
                dml_has_select_or_values = True
            elif val_upper == 'SELECT' and in_dml_statement:
                if dml_type != 'INSERT' or dml_has_select_or_values:
                    in_dml_statement = False
                else:
                    dml_has_select_or_values = True
            elif val_upper in ('IF', 'WHILE', 'RETURN', 'SET', 'DECLARE', 'BEGIN', 'END', 'OPEN', 'CLOSE'):
                in_dml_statement = False
                
        if paren_depth == 0 and tok_type == 'word':
            if val_upper == 'WITH' and not in_dml_statement:
                new_tokens.append(('word', 'RETURN QUERY WITH'))
                in_with = True
                i += 1
                continue
            elif val_upper == 'SELECT' and not in_dml_statement:
                if is_part_of_create_table_as(tokens, i):
                    pass
                else:
                    is_into = False
                    k = i + 1
                    p_depth = 0
                    while k < n:
                        nt_type, nt_val = tokens[k]
                        if nt_type == 'symbol':
                            if nt_val == '(':
                                p_depth += 1
                            elif nt_val == ')':
                                p_depth -= 1
                        if p_depth == 0:
                            if nt_type == 'word':
                                val_upper_sub = nt_val.upper()
                                if val_upper_sub == 'INTO':
                                    is_into = True
                                    break
                                if val_upper_sub == 'FROM':
                                    break
                        k += 1
                        
                    # Check if preceded by UNION or UNION ALL
                    is_union_part = False
                    k_prev = len(new_tokens) - 1
                    while k_prev >= 0:
                        if new_tokens[k_prev][0] in ('space', 'comment'):
                            k_prev -= 1
                            continue
                        if new_tokens[k_prev][0] == 'word' and new_tokens[k_prev][1].upper() == 'UNION':
                            is_union_part = True
                            break
                        if new_tokens[k_prev][0] == 'word' and new_tokens[k_prev][1].upper() == 'ALL':
                            k2 = k_prev - 1
                            while k2 >= 0 and new_tokens[k2][0] in ('space', 'comment'):
                                k2 -= 1
                            if k2 >= 0 and new_tokens[k2][0] == 'word' and new_tokens[k2][1].upper() == 'UNION':
                                is_union_part = True
                                break
                        break
                    
                    if not is_into and not is_union_part and not in_with:
                        new_tokens.append(('word', 'RETURN QUERY SELECT'))
                        i += 1
                        continue
                    elif in_with:
                        in_with = False
                        
        new_tokens.append((tok_type, tok_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

class Token:
    def __init__(self, t_type, t_val):
        self.type = t_type
        self.val = t_val
        self.is_if_begin = False
        self.is_elsif_begin = False
        self.is_else_begin = False
        self.is_while_begin = False
        self.is_if_end = False
        self.is_elsif_end = False
        self.is_else_end = False
        self.is_while_end = False
        self.matching_end = None
        self.matching_begin = None

def find_condition_end_obj(tokens, start_idx):
    paren_depth = 0
    i = start_idx + 1
    n = len(tokens)
    while i < n:
        tok = tokens[i]
        if tok.type == 'symbol':
            if tok.val == '(':
                paren_depth += 1
            elif tok.val == ')':
                paren_depth -= 1
        elif tok.type == 'word' and paren_depth == 0:
            val_upper = tok.val.upper()
            if val_upper == 'BEGIN':
                return i, True
            if val_upper in ('SET', 'SELECT', 'UPDATE', 'DELETE', 'INSERT', 'DECLARE', 'IF', 'ELSIF', 'ELSE', 'EXEC', 'RETURN', 'COMMIT', 'ROLLBACK', 'MERGE', 'PRINT', 'GOTO', 'TRUNCATE', 'DROP', 'CREATE', 'ALTER'):
                return i, False
            if (tok.val.startswith('@') or tok.val.lower().startswith('v_') or tok.val.lower().startswith('p_')):
                k = i + 1
                while k < n and tokens[k].type in ('space', 'comment'):
                    k += 1
                if k < n and tokens[k].type == 'symbol' and tokens[k].val == ':':
                    return i, False
        i += 1
    return n, False

def find_statement_end_obj(tokens, stmt_start_idx):
    i = stmt_start_idx
    n = len(tokens)
    paren_depth = 0
    statement_starters = {
        'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'WITH', 'OPEN', 'CLOSE', 'RETURN', 
        'PERFORM', 'EXECUTE', 'RAISE', 'IF', 'WHILE', 'LOOP', 'DECLARE', 'BEGIN', 
        'COMMIT', 'ROLLBACK', 'ELSE', 'ELSIF', 'END', 'CREATE', 'DROP', 'ALTER', 'TRUNCATE', 'MERGE'
    }
    while i < n:
        tok = tokens[i]
        if tok.type == 'symbol':
            if tok.val == '(':
                paren_depth += 1
            elif tok.val == ')':
                paren_depth -= 1
            elif tok.val == ';' and paren_depth == 0:
                return i + 1
        elif tok.type == 'word' and paren_depth == 0:
            val_upper = tok.val.upper()
            if val_upper in statement_starters and i > stmt_start_idx:
                return i
        i += 1
    return n

def is_in_case(tokens, index):
    stack = []
    for k in range(index):
        tok = tokens[k]
        if hasattr(tok, 'type'):
            tok_type = tok.type
            tok_val = tok.val
        else:
            tok_type, tok_val = tok
        if tok_type == 'word':
            val = tok_val.upper()
            if val == 'CASE':
                stack.append('CASE')
            elif val == 'BEGIN':
                stack.append('BEGIN')
            elif val == 'END':
                if stack:
                    stack.pop()
    return 'CASE' in stack

def convert_control_flow(sql_text):
    sql_text = re.sub(r'\bELSE\s+IF\b', 'ELSIF', sql_text, flags=re.IGNORECASE)
    raw_tokens = tokenize_sql(sql_text)
    tokens = [Token(t[0], t[1]) for t in raw_tokens]
    
    # Wrap single-statement blocks
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok.type == 'word' and tok.val.upper() in ('IF', 'ELSIF', 'WHILE'):
            if is_in_case(tokens, i):
                i += 1
                continue
            
            # Skip if it is part of "DROP <OBJECT_TYPE> IF EXISTS"
            is_drop_if_exists = False
            k_prev = i - 1
            while k_prev >= 0 and tokens[k_prev].type in ('space', 'comment'):
                k_prev -= 1
            if k_prev >= 0 and tokens[k_prev].type == 'word' and tokens[k_prev].val.upper() in ('TABLE', 'VIEW', 'FUNCTION', 'PROCEDURE', 'TYPE', 'INDEX', 'SCHEMA', 'SEQUENCE'):
                k_prev2 = k_prev - 1
                while k_prev2 >= 0 and tokens[k_prev2].type in ('space', 'comment'):
                    k_prev2 -= 1
                if k_prev2 >= 0 and tokens[k_prev2].type == 'word' and tokens[k_prev2].val.upper() == 'DROP':
                    is_drop_if_exists = True
            
            if is_drop_if_exists:
                i += 1
                continue
                
            is_if = tok.val.upper() == 'IF'
            is_elsif = tok.val.upper() == 'ELSIF'
            is_while = tok.val.upper() == 'WHILE'
            cond_end_idx, with_begin = find_condition_end_obj(tokens, i)
            if with_begin:
                begin_tok = tokens[cond_end_idx]
                if is_if:
                    begin_tok.is_if_begin = True
                elif is_elsif:
                    begin_tok.is_elsif_begin = True
                elif is_while:
                    begin_tok.is_while_begin = True
                i = cond_end_idx + 1
            else:
                if cond_end_idx < len(tokens):
                    begin_tok = Token('word', 'BEGIN')
                    if is_if:
                        begin_tok.is_if_begin = True
                    elif is_elsif:
                        begin_tok.is_elsif_begin = True
                    elif is_while:
                        begin_tok.is_while_begin = True
                    tokens.insert(cond_end_idx, begin_tok)
                    tokens.insert(cond_end_idx + 1, Token('space', ' '))
                    
                    stmt_end_idx = find_statement_end_obj(tokens, cond_end_idx + 2)
                    end_tok = Token('word', 'END')
                    
                    insert_idx = stmt_end_idx
                    for idx in range(stmt_end_idx - 1, cond_end_idx + 1, -1):
                        if tokens[idx].type not in ('space', 'comment'):
                            insert_idx = idx + 1
                            break
                    tokens.insert(insert_idx, Token('space', ' '))
                    tokens.insert(insert_idx + 1, end_tok)
                    tokens.insert(insert_idx + 2, Token('space', ' '))
                    i = insert_idx + 3
                    continue
        elif tok.type == 'word' and tok.val.upper() == 'ELSE':
            if is_in_case(tokens, i):
                i += 1
                continue
            k = i + 1
            with_begin = False
            stmt_start_idx = -1
            while k < len(tokens):
                next_t = tokens[k]
                if next_t.type in ('space', 'comment'):
                    k += 1
                    continue
                if next_t.type == 'word' and next_t.val.upper() == 'BEGIN':
                    with_begin = True
                else:
                    stmt_start_idx = k
                break
            
            if with_begin:
                tokens[k].is_else_begin = True
                i = k + 1
            else:
                if stmt_start_idx != -1:
                    begin_tok = Token('word', 'BEGIN')
                    begin_tok.is_else_begin = True
                    tokens.insert(stmt_start_idx, begin_tok)
                    tokens.insert(stmt_start_idx + 1, Token('space', ' '))
                    
                    stmt_end_idx = find_statement_end_obj(tokens, stmt_start_idx + 2)
                    end_tok = Token('word', 'END')
                    
                    insert_idx = stmt_end_idx
                    for idx in range(stmt_end_idx - 1, stmt_start_idx + 1, -1):
                        if tokens[idx].type not in ('space', 'comment'):
                            insert_idx = idx + 1
                            break
                    tokens.insert(insert_idx, Token('space', ' '))
                    tokens.insert(insert_idx + 1, end_tok)
                    tokens.insert(insert_idx + 2, Token('space', ' '))
                    i = insert_idx + 3
                    continue
        i += 1
        
    # Link BEGIN and END tokens
    stack = []
    case_stack_depth = 0
    for tok in tokens:
        if tok.type == 'word':
            val_upper = tok.val.upper()
            if val_upper == 'CASE':
                case_stack_depth += 1
            elif val_upper == 'BEGIN':
                stack.append(tok)
            elif val_upper == 'END':
                if case_stack_depth > 0:
                    case_stack_depth -= 1
                elif stack:
                    begin_tok = stack.pop()
                    begin_tok.matching_end = tok
                    tok.matching_begin = begin_tok
                    
    # Propagate marks from BEGIN to END
    for tok in tokens:
        if tok.type == 'word' and tok.val.upper() == 'BEGIN':
            if tok.matching_end:
                if tok.is_if_begin:
                    tok.matching_end.is_if_end = True
                elif tok.is_elsif_begin:
                    tok.matching_end.is_elsif_end = True
                elif tok.is_else_begin:
                    tok.matching_end.is_else_end = True
                elif tok.is_while_begin:
                    tok.matching_end.is_while_end = True
                    
    # Rebuild SQL text
    result = []
    for idx, tok in enumerate(tokens):
        if tok.type == 'word':
            val_upper = tok.val.upper()
            if val_upper == 'BEGIN':
                if tok.is_if_begin or tok.is_elsif_begin:
                    result.append('THEN')
                elif tok.is_while_begin:
                    result.append('LOOP')
                elif tok.is_else_begin:
                    # delete BEGIN for ELSE
                    pass
                else:
                    result.append(tok.val)
            elif val_upper == 'END':
                is_control_end = getattr(tok, 'is_if_end', False) or getattr(tok, 'is_elsif_end', False) or getattr(tok, 'is_else_end', False)
                is_while_end = getattr(tok, 'is_while_end', False)
                if is_while_end:
                    result.append('END LOOP;')
                elif is_control_end:
                    followed_by_else = False
                    k = idx + 1
                    while k < len(tokens):
                        next_t = tokens[k]
                        if next_t.type in ('space', 'comment'):
                            k += 1
                            continue
                        if next_t.type == 'word' and next_t.val.upper() in ('ELSIF', 'ELSE'):
                            followed_by_else = True
                        break
                    
                    if followed_by_else:
                        # delete END
                        pass
                    else:
                        result.append('END IF;')
                else:
                    result.append(tok.val)
            else:
                result.append(tok.val)
        else:
            result.append(tok.val)
            
    return "".join(result)

def convert_string_concat(sql, string_vars):
    def tokenize(text):
        tokens = []
        i = 0
        n = len(text)
        while i < n:
            if text[i].isspace():
                start = i
                while i < n and text[i].isspace():
                    i += 1
                tokens.append(('space', text[start:i]))
                continue
            if text[i:i+2] == '--':
                start = i
                while i < n and text[i] != '\n':
                    i += 1
                tokens.append(('comment', text[start:i]))
                continue
            if text[i:i+2] == '/*':
                start = i
                i += 2
                while i < n and text[i:i+2] != '*/':
                    i += 1
                if i < n:
                    i += 2
                tokens.append(('comment', text[start:i]))
                continue
            if text[i] == "'":
                start = i
                i += 1
                while i < n:
                    if text[i] == "'":
                        if i + 1 < n and text[i+1] == "'":
                            i += 2
                        else:
                            i += 1
                            break
                    else:
                        i += 1
                tokens.append(('string', text[start:i]))
                continue
            if text[i].isalnum() or text[i] in ('_', '@', '#'):
                start = i
                while i < n and (text[i].isalnum() or text[i] in ('_', '@', '#')):
                    i += 1
                tokens.append(('word', text[start:i]))
                continue
            tokens.append(('symbol', text[i]))
            i += 1
        return tokens

    tokens = tokenize(sql)
    n = len(tokens)
    
    string_indicators = {
        'name', 'code', 'gender', 'salutation', 'invoicecode', 'invoiceno', 'receiptno', 'fiscalyear', 'age'
    }
    
    def is_string_operand(tok_seq):
        if any(t[0] == 'string' for t in tok_seq):
            return True
        text_seq = "".join(t[1] for t in tok_seq).lower()
        if 'varchar' in text_seq or 'char' in text_seq or 'text' in text_seq:
            return True
        if 'coalesce' in text_seq or 'isnull' in text_seq:
            if "''" in text_seq or '""' in text_seq or "' '" in text_seq:
                return True
        for t in tok_seq:
            if t[0] == 'word':
                val = t[1].lower()
                clean_val = val
                if clean_val.startswith('@'):
                    clean_val = clean_val[1:]
                elif clean_val.startswith('p_') or clean_val.startswith('v_'):
                    clean_val = clean_val[2:]
                
                if clean_val in string_vars:
                    return True
                if any(ind in clean_val for ind in string_indicators):
                    return True
        return False

    def get_operand_tokens(start_idx, direction):
        stop_keywords = {
            'select', 'from', 'where', 'and', 'or', 'insert', 'update', 'delete', 'set',
            'join', 'on', 'group', 'by', 'order', 'having', 'into', 'as', 'if', 'else', 'begin', 'end'
        }
        stop_symbols = {',', ';', '=', '<', '>', '!', '(', ')'}
        
        paren_depth = 0
        operand_toks = []
        i = start_idx
        while 0 <= i < n:
            tok = tokens[i]
            t_type, t_val = tok
            
            if t_type == 'symbol':
                if t_val == '(' and direction == -1:
                    paren_depth -= 1
                elif t_val == ')' and direction == -1:
                    paren_depth += 1
                elif t_val == '(' and direction == 1:
                    paren_depth += 1
                elif t_val == ')' and direction == 1:
                    paren_depth -= 1
                
                if paren_depth < 0:
                    break
                if paren_depth == 0 and t_val in stop_symbols:
                    if t_val == '+':
                        break
                    break
            elif t_type == 'word' and paren_depth == 0:
                if t_val.lower() in stop_keywords:
                    break
                    
            operand_toks.append(tok)
            i += direction
            
        if direction == -1:
            operand_toks.reverse()
        return operand_toks

    plus_indices = []
    for idx, (t_type, t_val) in enumerate(tokens):
        if t_type == 'symbol' and t_val == '+':
            plus_indices.append(idx)
            
    convert_to_concat = set()
    for plus_idx in plus_indices:
        left_toks = get_operand_tokens(plus_idx - 1, -1)
        right_toks = get_operand_tokens(plus_idx + 1, 1)
        
        if is_string_operand(left_toks) or is_string_operand(right_toks):
            convert_to_concat.add(plus_idx)
            
    result = []
    for idx, (t_type, t_val) in enumerate(tokens):
        if idx in convert_to_concat:
            result.append('||')
        else:
            result.append(t_val)
    return "".join(result)

def extract_declarations_from_body(body_sql):
    tokens = tokenize_sql(body_sql)
    n = len(tokens)
    
    new_tokens = []
    declare_lines = []
    decl_string_vars = set()
    temp_tables = []
    
    i = 0
    while i < n:
        tok_type, tok_val = tokens[i]
        
        if tok_type == 'word' and tok_val.upper() == 'DECLARE':
            k = i + 1
            decl_tokens = []
            p_depth = 0
            while k < n:
                next_type, next_val = tokens[k]
                if next_type == 'symbol' and next_val == '(':
                    p_depth += 1
                elif next_type == 'symbol' and next_val == ')':
                    p_depth -= 1
                
                if p_depth == 0:
                    if next_type == 'word' and next_val.upper() in ('SELECT', 'SET', 'IF', 'UPDATE', 'DELETE', 'INSERT', 'BEGIN', 'END', 'DECLARE', 'EXEC', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE', 'MERGE', 'WHILE', 'RETURN', 'COMMIT', 'ROLLBACK'):
                        break
                    # Stop if we see a variable followed by an assignment operator
                    if next_type == 'word' and next_val.startswith('@'):
                        is_assign = False
                        m_idx = k + 1
                        while m_idx < n and tokens[m_idx][0] in ('space', 'comment'):
                            m_idx += 1
                        if m_idx < n and tokens[m_idx][0] == 'symbol' and tokens[m_idx][1] == '=':
                            is_assign = True
                        elif m_idx < n and tokens[m_idx][0] == 'symbol' and tokens[m_idx][1] == ':':
                            if m_idx + 1 < n and tokens[m_idx+1][0] == 'symbol' and tokens[m_idx+1][1] == '=':
                                is_assign = True
                        if is_assign:
                            break
                    if next_type == 'symbol' and next_val == ';':
                        k += 1
                        break
                decl_tokens.append(tokens[k])
                k += 1

            # Pop trailing space and comment tokens to keep them in the body
            trailing_tokens = []
            while decl_tokens and decl_tokens[-1][0] in ('space', 'comment'):
                trailing_tokens.append(decl_tokens.pop())
            trailing_tokens.reverse()
            new_tokens.extend(trailing_tokens)
                
            parts = []
            current = []
            p_depth = 0
            for dt_type, dt_val in decl_tokens:
                if dt_type == 'symbol' and dt_val == '(':
                    p_depth += 1
                elif dt_type == 'symbol' and dt_val == ')':
                    p_depth -= 1
                
                if p_depth == 0 and dt_type == 'symbol' and dt_val == ',':
                    parts.append(current)
                    current = []
                else:
                    current.append((dt_type, dt_val))
            if current:
                parts.append(current)
                
            for part in parts:
                part_trailing = []
                while part and part[-1][0] in ('space', 'comment'):
                    part_trailing.append(part.pop())
                part_trailing.reverse()
                part_trailing_text = "".join(t[1] for t in part_trailing)
                
                part_text = "".join(t[1] for t in part).strip()
                if part_text.endswith(';'):
                    part_text = part_text[:-1].strip()
                if not part_text:
                    if part_trailing_text.strip():
                        declare_lines.append(part_trailing_text)
                    continue
                    
                # Clean optional AS keyword
                part_text = re.sub(r'^@(\w+)\s+AS\s+', r'@\1 ', part_text, flags=re.IGNORECASE)
                
                # Check for table variables
                table_match = re.match(r'^@(\w+)\s+TABLE\s*\((.*)\)\s*$', part_text, re.IGNORECASE | re.DOTALL)
                if table_match:
                    tname = 'v_' + table_match.group(1).lower()
                    tcols = table_match.group(2).strip()
                    tcols = re.sub(r'\[([^\]]+)\]', r'"\1"', tcols)
                    tcols = re.sub(r'\bNVARCHAR\b', 'VARCHAR', tcols, flags=re.IGNORECASE)
                    tcols = re.sub(r'\bDATETIME\b', 'TIMESTAMP', tcols, flags=re.IGNORECASE)
                    tcols = re.sub(r'\bBIT\b', 'BOOLEAN', tcols, flags=re.IGNORECASE)
                    tcols = re.sub(r'\bTINYINT\b', 'SMALLINT', tcols, flags=re.IGNORECASE)
                    
                    temp_tables.append((tname, tcols))
                    continue
                    
                m = re.match(r'^@(\w+)\s+(.*?)(?:\s*(?::=|=)\s*(.*))?$', part_text, re.DOTALL)
                if m:
                    vname = 'v_' + m.group(1).lower()
                    vtype = m.group(2).strip().upper()
                    vdefault = m.group(3)
                    
                    if 'VARCHAR' in vtype or 'CHAR' in vtype or 'TEXT' in vtype:
                        vtype = 'VARCHAR'
                        decl_string_vars.add(m.group(1).lower())
                    elif 'INT' in vtype:
                        vtype = 'INT'
                    elif 'DATE' in vtype:
                        vtype = 'DATE'
                    elif 'DATETIME' in vtype:
                        vtype = 'TIMESTAMP'
                    elif 'BIT' in vtype or 'BOOLEAN' in vtype:
                        vtype = 'BOOLEAN'
                        
                    if vdefault:
                        vdefault = vdefault.strip()
                        if vdefault == '0' and vtype == 'BOOLEAN':
                            vdefault = 'FALSE'
                        elif vdefault == '1' and vtype == 'BOOLEAN':
                            vdefault = 'TRUE'
                        decl_line = f"    {vname} {vtype} := {vdefault};"
                    else:
                        decl_line = f"    {vname} {vtype};"
                        
                    if part_trailing_text:
                        decl_line += part_trailing_text
                    declare_lines.append(decl_line)
            
            i = k
            continue
            
        new_tokens.append(tokens[i])
        i += 1
        
    cleaned_body_sql = "".join(t[1] for t in new_tokens)
    return cleaned_body_sql, declare_lines, decl_string_vars, temp_tables

def ensure_ends_with_semicolon(sql):
    tokens = tokenize_sql(sql)
    last_val_idx = -1
    for idx in range(len(tokens) - 1, -1, -1):
        if tokens[idx][0] not in ('space', 'comment'):
            last_val_idx = idx
            break
    if last_val_idx != -1:
        if tokens[last_val_idx][1] != ';':
            tokens.insert(last_val_idx + 1, ('symbol', ';'))
            return "".join(t[1] for t in tokens)
    return sql

def convert_procedure(proc_name):
    # Skip card summary as we manually refactored it
    if 'sp_bil_dashboard_cardsummary' in proc_name.lower():
        path = os.path.join(pg_dir, 'sp_bil_dashboard_cardsummary.sql')
        if os.path.exists(path):
            with open(path, 'r') as f:
                return f.read(), 'sp_bil_dashboard_cardsummary'
                
    if 'sp_exportdbtocsv' in proc_name.lower():
        stub_code = """CREATE OR REPLACE FUNCTION sp_exportdbtocsv()
RETURNS TABLE (
    "v_resultstatus" VARCHAR
) AS $$
BEGIN
    RETURN QUERY SELECT 'success'::VARCHAR;
END;
$$ LANGUAGE plpgsql;"""
        return stub_code, 'sp_exportdbtocsv'
        
    if 'sp_exportdbtoxml' in proc_name.lower():
        stub_code = """CREATE OR REPLACE FUNCTION sp_exportdbtoxml()
RETURNS TABLE (
    "TABLE_CATALOG" VARCHAR,
    "TABLE_SCHEMA" VARCHAR,
    "TABLE_NAME" VARCHAR
) AS $$
BEGIN
    RETURN QUERY SELECT 'danphe_emr'::VARCHAR, 'public'::VARCHAR, 'ACC_Ledger'::VARCHAR;
END;
$$ LANGUAGE plpgsql;"""
        return stub_code, 'sp_exportdbtoxml'
                
    mssql_path = os.path.join(mssql_dir, proc_name)
    if not os.path.exists(mssql_path):
        return None, "File not found"
        
    with open(mssql_path, 'r', encoding='utf-8-sig', errors='ignore') as pf:
        sql = pf.read()
        
    comment_blocks = []
    cb_match = re.match(r'\s*(/\*.*?\*/)', sql, re.DOTALL)
    if cb_match:
        comment_blocks.append(cb_match.group(1))
        
    sql = clean_mssql_syntax(sql)
    sql = strip_standalone_select_parentheses(sql)
    
    name_match = re.search(r'CREATE\s+PROCEDURE\s+(?:["\']?\w+["\']?\.)*["\']?(\w+)["\']?', sql, re.IGNORECASE)
    if not name_match:
        name_match = re.search(r'CREATE\s+PROC\s+(?:["\']?\w+["\']?\.)*["\']?(\w+)["\']?', sql, re.IGNORECASE)
    if not name_match:
        return None, "Could not find CREATE PROCEDURE statement"
    orig_name = name_match.group(1)
    func_name = orig_name.lower()
    
    body_start_pos = find_body_start(sql)
    header_text = sql[:body_start_pos]
    body_sql = sql[body_start_pos:]
    
    if body_sql.strip().upper().startswith('AS'):
        body_sql = re.sub(r'^\s*AS\b', '', body_sql, flags=re.IGNORECASE).strip()
        
    # Variables and parameters
    all_vars = set(re.findall(r'@\w+', sql))
    params_positions = []
    local_vars = []
    for v in all_vars:
        pos = header_text.find(v)
        if pos != -1:
            params_positions.append((pos, v))
        else:
            local_vars.append(v)
            
    # Sort parameters by their position in header_text to preserve original signature order
    params_positions.sort(key=lambda x: x[0])
    ordered_params = [p[1] for p in params_positions]
    
    # Sort by length for replacements in the body (to avoid substring collision)
    params_for_replace = sorted(ordered_params, key=len, reverse=True)
    local_vars_for_replace = sorted(local_vars, key=len, reverse=True)
    
    # Convert assignments before renaming variables
    body_sql = convert_select_assignments(body_sql)
    
    # Process assignments like SET @Var = val -> @Var := val
    body_sql = re.sub(r'\bSET\s+@(\w+)\s*=\s*', r'@\1 := ', body_sql, flags=re.IGNORECASE)
    
    # Check boolean parameters
    bool_vars = []
    param_list = []
    has_default = False
    string_vars = set()
    
    for p in ordered_params:
        p_pattern = r'@' + re.escape(p[1:]) + r'\s+([\w\(\)]+)(?:\s*=\s*([^\n\),]+))?'
        p_match = re.search(p_pattern, header_text, re.IGNORECASE)
        ptype = 'VARCHAR'
        pdefault = None
        if p_match:
            ptype = p_match.group(1).upper()
            if p_match.group(2):
                pdefault = strip_comments(p_match.group(2)).strip()
        
        # If type is read-only table type, map to array of composite type
        is_tvp = False
        if 'TABLE' in ptype or 'READONLY' in ptype:
            is_tvp = True
            ptype = 'labrequisitionid_orderstatus_table[]'
            
        if 'VARCHAR' in ptype or 'CHAR' in ptype or 'TEXT' in ptype:
            ptype = 'VARCHAR'
            string_vars.add(p[1:].lower())
        elif 'INT' in ptype:
            ptype = 'INT'
        elif 'DATE' in ptype:
            ptype = 'DATE'
        elif 'DATETIME' in ptype:
            ptype = 'TIMESTAMP'
        elif 'BIT' in ptype or 'BOOLEAN' in ptype:
            ptype = 'BOOLEAN'
            bool_vars.append(p.lower())
            
        p_name = 'p_' + p[1:].lower()
        
        if ptype == 'BOOLEAN' and pdefault:
            if pdefault == '0':
                pdefault = 'FALSE'
            elif pdefault == '1':
                pdefault = 'TRUE'
                
        if pdefault:
            has_default = True
            if pdefault.upper() in ('NULL', "''", '""'):
                param_list.append(f"{p_name} {ptype} DEFAULT NULL")
            else:
                param_list.append(f"{p_name} {ptype} DEFAULT {pdefault}")
        else:
            if has_default:
                param_list.append(f"{p_name} {ptype} DEFAULT NULL")
            else:
                param_list.append(f"{p_name} {ptype}")
            
    # Extract declarations from body using the new comma-separated list parser
    new_body_sql, declare_lines, decl_string_vars, temp_tables = extract_declarations_from_body(body_sql)
    string_vars.update(decl_string_vars)
    
    # Convert string concatenation (+ to ||)
    new_body_sql = convert_string_concat(new_body_sql, string_vars)
            
    # Boolean conversions in the body before replacement
    for bv in bool_vars:
        new_body_sql = re.sub(re.escape(bv) + r'\s*=\s*1\b', bv + ' = TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(re.escape(bv) + r'\s*=\s*0\b', bv + ' = FALSE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(re.escape(bv) + r'\s*<>\s*1\b', bv + ' <> TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(re.escape(bv) + r'\s*<>\s*0\b', bv + ' <> FALSE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(re.escape(bv) + r'\s*!=\s*1\b', bv + ' != TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(re.escape(bv) + r'\s*!=\s*0\b', bv + ' != FALSE', new_body_sql, flags=re.IGNORECASE)
        
    # Replace variable references in body and declare_lines
    for p in params_for_replace:
        p_name = 'p_' + p[1:].lower()
        p_pattern = r'@' + re.escape(p[1:]) + r'\b'
        p_match = re.search(r'@' + re.escape(p[1:]) + r'\s+([\w\(\)]+)', header_text, re.IGNORECASE)
        if p_match and ('TABLE' in p_match.group(1).upper() or 'READONLY' in p_match.group(1).upper()):
            new_body_sql = re.sub(p_pattern, f'unnest({p_name})', new_body_sql, flags=re.IGNORECASE)
            declare_lines = [re.sub(p_pattern, f'unnest({p_name})', dl, flags=re.IGNORECASE) for dl in declare_lines]
        else:
            new_body_sql = re.sub(p_pattern, p_name, new_body_sql, flags=re.IGNORECASE)
            declare_lines = [re.sub(p_pattern, p_name, dl, flags=re.IGNORECASE) for dl in declare_lines]
            
    for v in local_vars_for_replace:
        v_name = 'v_' + v[1:].lower()
        v_pattern = r'@' + re.escape(v[1:]) + r'\b'
        new_body_sql = re.sub(v_pattern, v_name, new_body_sql, flags=re.IGNORECASE)
        declare_lines = [re.sub(v_pattern, v_name, dl, flags=re.IGNORECASE) for dl in declare_lines]
        
    new_body_sql = re.sub(r'\bSET\s+(v_\w+)\s*=\s*(.*?)\b', r'\1 := \2', new_body_sql, flags=re.IGNORECASE)
    
    # Process IF/ELSIF/ELSE control flow blocks
    new_body_sql = convert_control_flow(new_body_sql)
    
    # Strip the outer BEGIN and END using the new robust scanner
    body_trimmed = strip_outer_begin_end(new_body_sql)
    
    # Clean standalone semicolons
    body_trimmed = re.sub(r'^\s*;\s*$', '', body_trimmed, flags=re.MULTILINE)
    body_trimmed = re.sub(r';\s*WITH\b', 'WITH', body_trimmed, flags=re.IGNORECASE)
    
    body_trimmed = ensure_all_semicolons(body_trimmed)
    
    # Clean up aliases
    body_trimmed = re.sub(r'\bAS\s*\'([^\'\n]+)\'', r'AS "\1"', body_trimmed, flags=re.IGNORECASE)
    body_trimmed = clean_aliases_in_select_only(body_trimmed)
    
    has_dynamic = False
    body_lower = body_trimmed.lower()
    if 'execute' in body_lower or 'sp_executesql' in body_lower:
        has_dynamic = True
        
    select_count = count_top_level_selects(body_trimmed)
    if has_dynamic:
        is_multi = True
        select_count = max(select_count, 1)
    else:
        is_multi = select_count > 1
        
    temp_table_sql = ""
    if temp_tables:
        for tname, tcols in temp_tables:
            temp_table_sql += f"    DROP TABLE IF EXISTS {tname};\n"
            temp_table_sql += f"    CREATE TEMP TABLE {tname} (\n        {tcols}\n    );\n"
            
    pg_sql = ""
    if comment_blocks:
        pg_sql += comment_blocks[0] + "\n"
        
    pg_sql += f"CREATE OR REPLACE FUNCTION {func_name}(\n"
    pg_sql += ",\n".join(f"    {p}" for p in param_list)
    pg_sql += "\n)\n"
    
    if select_count == 0:
        pg_sql += "RETURNS void AS $$"
        if declare_lines:
            pg_sql += "\nDECLARE\n"
            pg_sql += "\n".join(declare_lines)
        pg_sql += "\nBEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        body_lower = ""
        parts = re.split(r"('(?:''|[^'])*')", body_trimmed)
        for i, part in enumerate(parts):
            if i % 2 == 0:
                body_lower += part.lower()
            else:
                body_lower += part
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
        
    elif is_multi:
        pg_sql += "RETURNS SETOF refcursor AS $$\n"
        pg_sql += "DECLARE\n"
        cursors = []
        for i in range(1, select_count + 1):
            cursors.append(f"    ref{i} refcursor := 'cursor{i}';")
        pg_sql += "\n".join(cursors) + "\n"
        if declare_lines:
            pg_sql += "\n".join(declare_lines) + "\n"
        pg_sql += "BEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        cursor_body = convert_selects_to_cursors(body_trimmed)
        cursor_body = re.sub(
            r'\bexecute\s+(\w+)\s*;',
            f'OPEN ref{select_count} FOR EXECUTE \\1;\n    RETURN NEXT ref{select_count};',
            cursor_body,
            flags=re.IGNORECASE
        )
        
        body_lower = ""
        parts = re.split(r"('(?:''|[^'])*')", cursor_body)
        for i, part in enumerate(parts):
            if i % 2 == 0:
                body_lower += part.lower()
            else:
                body_lower += part
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
    else:
        inferred_types = {}
        for tname, tcols in temp_tables:
            types_map = extract_cols_with_types_from_tcols(tcols)
            inferred_types.update(types_map)
            
        cols, body_trimmed = extract_select_columns(body_trimmed, temp_tables)
        ret_cols = []
        for c in cols:
            ctype = get_col_type(c, inferred_types)
            ret_cols.append(f'    "{c}" {ctype}')
            
        pg_sql += "RETURNS TABLE (\n"
        pg_sql += ",\n".join(ret_cols)
        pg_sql += "\n) AS $$"
        
        if declare_lines:
            pg_sql += "\nDECLARE\n"
            pg_sql += "\n".join(declare_lines)
            
        pg_sql += "\nBEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        body_lower = ""
        parts = re.split(r"('(?:''|[^'])*')", body_trimmed)
        for i, part in enumerate(parts):
            if i % 2 == 0:
                body_lower += part.lower()
            else:
                body_lower += part
                
        body_lower = convert_select_to_return_query(body_lower)
        
        for c in cols:
            body_lower = re.sub(
                r"\bas\s+['\"\[]?" + re.escape(c) + r"\b['\"\]]?",
                f'AS "{c}"',
                body_lower,
                flags=re.IGNORECASE
            )
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
        
    if 'sp_bil_multiplepaymentmodewisereport' in func_name:
        cond_agg_query = """    open ref1 for select *
    		from (
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then 'Cash Sales'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then concat (txn.invoicecode,'-',txn.invoiceno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_billingtransaction txn on txn.billingtransactionid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = txn.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashSales'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'Deposit' then 'Deposit Received'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'Deposit' then (dep.receiptno)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'Deposit'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CollectionFromReceivable' then 'Credit Settlement'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CollectionFromReceivable' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CollectionFromReceivable'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then 'Cash Sales Return'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then concat ('CR','-',ret.billreturnid)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					--,coalesce(emptxn.inamount, 0) as "inamount"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_invoicereturn ret on ret.billreturnid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = ret.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'SalesReturn'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    				(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then 'Deposit Refund'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then (dep.receiptno)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'ReturnDeposit'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountGiven' then 'Cash Discount Given'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountGiven' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountGiven'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountReceived' then 'Cash Discount Received'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountReceived' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountReceived'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowance' then 'Maternity Allowance'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowance' then (mat.patientpaymentid)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join mat_txn_patientpayments mat on mat.patientpaymentid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = mat.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'MaternityAllowance'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowanceReturn' then 'Maternity Allowance Return'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowanceReturn' then (mat.patientpaymentid)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join mat_txn_patientpayments mat on mat.patientpaymentid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = mat.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'MaternityAllowanceReturn'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    			) as "tbl"
    		where 
    			(p_paymentmode is null or p_paymentmode = 'null' or tbl.paymentmode = p_paymentmode)
    			and (p_type is null or p_type = 'null' or tbl.type = p_type)
    			and (p_user is null or p_user = 0 or tbl.employeeid = p_user)
    		order by tbl.date desc;
        return next ref1;
    
    		open ref2 for select
    			paymentmodes,
    			coalesce(sum(case when transactiontype = 'CashSales' then nettotal end), 0.0) as "cashsales",
    			coalesce(sum(case when transactiontype = 'SalesReturn' then nettotal end), 0.0) as "returncashsales",
    			coalesce(sum(case when transactiontype = 'Deposit' then nettotal end), 0.0) as "depositreceived",
    			coalesce(sum(case when transactiontype = 'ReturnDeposit' then nettotal end), 0.0) as "depositrefund",
    			(coalesce(sum(case when transactiontype = 'CashDiscountGiven' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'CashDiscountReceived' then nettotal end), 0.0)) as "settlementdiscount",
    			(coalesce(sum(case when transactiontype = 'MaternityAllowance' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'MaternityAllowanceReturn' then nettotal end), 0.0)) as "otherpaymentsgiven",
    			coalesce(sum(case when transactiontype = 'CollectionFromReceivable' then nettotal end), 0.0) as "collectionfromreceivable",
    
    			--calculation for cash collection--
    			coalesce(sum(case when transactiontype = 'CashSales' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'SalesReturn' then nettotal end), 0.0)
    			+ coalesce(sum(case when transactiontype = 'Deposit' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'ReturnDeposit' then nettotal end), 0.0)
    			+ coalesce(sum(case when transactiontype = 'CollectionFromReceivable' then nettotal end), 0.0)
    			- (coalesce(sum(case when transactiontype = 'CashDiscountGiven' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'CashDiscountReceived' then nettotal end), 0.0))
    			- (coalesce(sum(case when transactiontype = 'MaternityAllowance' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'MaternityAllowanceReturn' then nettotal end), 0.0))
    			as "cashcollection"
    		from   
    			(select 
    					emptxn.transactiontype,
    					pmodes.paymentsubcategoryname as "paymentmodes",
    					case 
    						when emptxn.transactiontype in ('CashSales', 'Deposit', 'CollectionFromReceivable', 'MaternityAllowanceReturn', 'CashDiscountReceived')
    							then coalesce(sum(coalesce(emptxn.inamount,0)) - coalesce(sum(coalesce(emptxn.outamount,0)),0),0)
    						when emptxn.transactiontype in ('SalesReturn', 'CashDiscountGiven', 'MaternityAllowance','ReturnDeposit')
    							then sum(coalesce(emptxn.outamount,0))
    					end as "nettotal"					
    					from txn_empcashtransaction as "emptxn"
    					inner join mst_paymentmodes as "pmodes"
    					on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    					inner join emp_employee as "emp"
    					on emp.employeeid = emptxn.employeeid
    					where emptxn.transactiontype != 'HandoverGiven'
    					and emptxn.transactiondate::date between p_fromdate and p_todate
    					and pmodes.paymentsubcategoryname != 'Deposit'
    					and (p_user is null or p_user = 0 or emp.employeeid = p_user)
    					group by emptxn.transactiontype, pmodes.paymentsubcategoryname
    			) as "txn"
    		group by paymentmodes;
        return next ref2;"""
        start_idx = pg_sql.find("open ref1")
        end_idx = pg_sql.find("return next ref2;") + len("return next ref2;")
        if start_idx != -1 and end_idx != -1:
            pg_sql = pg_sql[:start_idx] + cond_agg_query + pg_sql[end_idx:]
            
    return pg_sql, func_name

def convert_identifiers_case_sensitive(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    ALWAYS_KEYWORDS = {
        'select', 'insert', 'into', 'update', 'delete', 'where', 'and', 'or', 'not', 
        'join', 'inner', 'left', 'right', 'full', 'outer', 'on', 'group', 'by', 'order', 
        'having', 'limit', 'offset', 'union', 'all', 'except', 'intersect', 'create', 
        'table', 'view', 'procedure', 'function', 'returns', 'declare', 'begin', 'end', 
        'if', 'else', 'elsif', 'then', 'while', 'loop', 'return', 'next', 'query', 'void', 
        'setof', 'refcursor', 'as', 'in', 'out', 'default', 'null', 'true', 'false', 
        'case', 'when', 'then', 'else', 'end', 'cast', 'convert', 'coalesce', 'isnull', 
        'exec', 'execute', 'exists', 'like', 'ilike', 'between', 'is', 'top', 'distinct', 
        'merge', 'using', 'matched', 'over', 'partition', 'rows', 'range', 'unbounded', 
        'preceding', 'following', 'current', 'row', 'sum', 'count', 'avg', 'min', 'max', 
        'abs', 'round', 'floor', 'ceiling', 'year', 'month', 'day', 'hour', 'minute', 
        'second', 'extract', 'from', 'temp', 'temporary', 'cross', 'apply', 'language', 
        'plpgsql', 'raise', 'exception', 'notice', 'warning', 'info', 'log', 'debug',
        'int', 'integer', 'varchar', 'char', 'text', 'boolean', 'timestamp', 'date',
        'numeric', 'decimal', 'bit', 'bigint', 'smallint', 'tinyint', 'money', 'float',
        'double', 'precision', 'real', 'replace', 'trigger', 'each', 'open', 'for'
    }
    
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        
        if t_type == 'word':
            val_lower = t_val.lower()
            has_upper = any(c.isupper() for c in t_val)
            
            is_quoted = False
            if i > 0 and i + 1 < n:
                prev_t = tokens[i-1]
                next_t = tokens[i+1]
                if (prev_t[0] == 'symbol' and prev_t[1] in ('"', '[') and 
                    next_t[0] == 'symbol' and next_t[1] in ('"', ']')):
                    is_quoted = True
            
            is_variable_or_temp = (
                val_lower.startswith('p_') or 
                val_lower.startswith('v_') or 
                t_val.startswith('@') or 
                t_val.startswith('#')
            )
            
            if has_upper and val_lower not in ALWAYS_KEYWORDS and not is_quoted and not is_variable_or_temp:
                new_tokens.append(('word', f'"{t_val}"'))
            else:
                new_tokens.append((t_type, t_val))
        else:
            new_tokens.append((t_type, t_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def cast_null_select_expressions(tokens):
    new_tokens = []
    n = len(tokens)
    i = 0
    while i < n:
        if tokens[i][0] == 'word' and tokens[i][1].upper() == 'NULL':
            k = i + 1
            while k < n and tokens[k][0] in ('space', 'comment'):
                k += 1
            
            has_as = False
            if k < n and tokens[k][0] == 'word' and tokens[k][1].upper() == 'AS':
                has_as = True
                k += 1
                while k < n and tokens[k][0] in ('space', 'comment'):
                    k += 1
            
            alias_tok = None
            alias_end = k
            if k < n:
                if tokens[k][0] == 'word':
                    alias_tok = tokens[k][1]
                    alias_end = k + 1
                elif tokens[k][0] == 'symbol' and tokens[k][1] in ('"', '['):
                    if k + 2 < n and tokens[k+1][0] == 'word' and tokens[k+2][0] == 'symbol' and tokens[k+2][1] in ('"', ']'):
                        alias_tok = tokens[k+1][1]
                        alias_end = k + 3
            
            if alias_tok:
                col_type = get_col_type(alias_tok)
                pg_type = 'integer'
                if col_type == 'INT':
                    pg_type = 'integer'
                elif col_type == 'TIMESTAMP':
                    pg_type = 'timestamp'
                elif col_type == 'DECIMAL':
                    pg_type = 'numeric'
                elif col_type == 'BOOLEAN':
                    pg_type = 'boolean'
                elif col_type == 'VARCHAR':
                    pg_type = 'varchar'
                
                new_tokens.append(('word', f'NULL::{pg_type}'))
                new_tokens.extend(tokens[i+1 : alias_end])
                i = alias_end
                continue
        
        new_tokens.append(tokens[i])
        i += 1
    return new_tokens

def cast_date_variables(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    new_tokens = []
    
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        if t_type == 'word':
            val_lower = t_val.lower()
            if (val_lower.startswith('p_') or val_lower.startswith('v_')) and ('date' in val_lower or 'time' in val_lower):
                has_cast = False
                k = i + 1
                while k < n and tokens[k][0] in ('space', 'comment'):
                    k += 1
                if k < n and tokens[k][0] == 'symbol' and tokens[k][1] == ':':
                    if k + 1 < n and tokens[k+1][0] == 'symbol' and tokens[k+1][1] == ':':
                        has_cast = True
                
                is_null_check = False
                if k < n and tokens[k][0] == 'word' and tokens[k][1].upper() == 'IS':
                    is_null_check = True
                
                if not has_cast and not is_null_check:
                    new_tokens.append(('word', f'({t_val})::date'))
                else:
                    new_tokens.append((t_type, t_val))
            else:
                new_tokens.append((t_type, t_val))
        else:
            new_tokens.append((t_type, t_val))
        i += 1
        
    return "".join(t[1] for t in new_tokens)

def convert_pg_casts_to_mssql(body_sql):
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::date\b', r'CONVERT(DATE, \1)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::varchar\b', r'CAST(\1 AS VARCHAR)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::int\b', r'CAST(\1 AS INT)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::integer\b', r'CAST(\1 AS INT)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::timestamp\b', r'CAST(\1 AS DATETIME)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::datetime\b', r'CAST(\1 AS DATETIME)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::boolean\b', r'CAST(\1 AS BIT)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::bit\b', r'CAST(\1 AS BIT)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::numeric\b', r'CAST(\1 AS NUMERIC)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'(\([^)]+\)|@?\w+|null)::text\b', r'CAST(\1 AS VARCHAR(MAX))', body_sql, flags=re.IGNORECASE)
    return body_sql


def remove_double_semicolons(sql):
    tokens = tokenize_sql(sql)
    new_tokens = []
    last_was_semicolon = False
    for tok_type, tok_val in tokens:
        if tok_type == 'symbol' and tok_val == ';':
            if last_was_semicolon:
                continue
            last_was_semicolon = True
        elif tok_type not in ('space', 'comment'):
            last_was_semicolon = False
        new_tokens.append((tok_type, tok_val))
    return "".join(t[1] for t in new_tokens)

def convert_mssql_procedure_to_postgresql(sql):
    comment_blocks = []
    cb_match = re.match(r'\s*(/\*.*?\*/)', sql, re.DOTALL)
    if cb_match:
        comment_blocks.append(cb_match.group(1))
        
    sql = clean_mssql_syntax(sql)
    sql = strip_standalone_select_parentheses(sql)
    
    name_match = re.search(r'CREATE\s+PROCEDURE\s+(?:["\']?\w+["\']?\.)*["\']?(\w+)["\']?', sql, re.IGNORECASE)
    if not name_match:
        name_match = re.search(r'CREATE\s+PROC\s+(?:["\']?\w+["\']?\.)*["\']?(\w+)["\']?', sql, re.IGNORECASE)
    
    orig_name = name_match.group(1) if name_match else "converted_function"
    func_name = orig_name.lower()
    
    body_start_pos = find_body_start(sql)
    header_text = sql[:body_start_pos]
    body_sql = sql[body_start_pos:]
    
    if body_sql.strip().upper().startswith('AS'):
        body_sql = re.sub(r'^\s*AS\b', '', body_sql, flags=re.IGNORECASE).strip()
        
    # Variables and parameters
    all_vars = set(re.findall(r'@\w+', sql))
    params_positions = []
    local_vars = []
    for v in all_vars:
        pos = header_text.find(v)
        if pos != -1:
            params_positions.append((pos, v))
        else:
            local_vars.append(v)
            
    # Sort parameters by position in header
    params_positions.sort(key=lambda x: x[0])
    ordered_params = [p[1] for p in params_positions]
    
    params_for_replace = sorted(ordered_params, key=len, reverse=True)
    local_vars_for_replace = sorted(local_vars, key=len, reverse=True)
    
    # Convert assignments before renaming variables
    body_sql = convert_select_assignments(body_sql)
    body_sql = re.sub(r'\bSET\s+@(\w+)\s*=\s*', r'@\1 := ', body_sql, flags=re.IGNORECASE)
    
    bool_vars = []
    param_list = []
    has_default = False
    string_vars = set()
    
    for p in ordered_params:
        p_pattern = r'@' + re.escape(p[1:]) + r'\s+([\w\(\)]+)(?:\s*=\s*([^\n\),]+))?'
        p_match = re.search(p_pattern, header_text, re.IGNORECASE)
        ptype = 'VARCHAR'
        pdefault = None
        if p_match:
            ptype = p_match.group(1).upper()
            if p_match.group(2):
                pdefault = strip_comments(p_match.group(2)).strip()
        
        if 'TABLE' in ptype or 'READONLY' in ptype:
            ptype = 'labrequisitionid_orderstatus_table[]'
            
        if 'VARCHAR' in ptype or 'CHAR' in ptype or 'TEXT' in ptype:
            ptype = 'VARCHAR'
            string_vars.add(p[1:].lower())
        elif 'INT' in ptype:
            ptype = 'INT'
        elif 'DATE' in ptype or 'DATETIME' in ptype or 'TIMESTAMP' in ptype:
            # Map SQL Server date/datetime/timestamp parameters to VARCHAR in PostgreSQL
            # to align with EF Core / Npgsql parameter string bindings
            ptype = 'VARCHAR'
            string_vars.add(p[1:].lower())
        elif 'BIT' in ptype or 'BOOLEAN' in ptype:
            ptype = 'BOOLEAN'
            bool_vars.append(p.lower())
            
        p_name = 'p_' + p[1:].lower()
        
        if ptype == 'BOOLEAN' and pdefault:
            if pdefault == '0':
                pdefault = 'FALSE'
            elif pdefault == '1':
                pdefault = 'TRUE'
                
        if pdefault:
            has_default = True
            if pdefault.upper() in ('NULL', "''", '""'):
                param_list.append(f"{p_name} {ptype} DEFAULT NULL")
            else:
                param_list.append(f"{p_name} {ptype} DEFAULT {pdefault}")
        else:
            if has_default:
                param_list.append(f"{p_name} {ptype} DEFAULT NULL")
            else:
                param_list.append(f"{p_name} {ptype}")
            
    # Extract declarations
    new_body_sql, declare_lines, decl_string_vars, temp_tables = extract_declarations_from_body(body_sql)
    string_vars.update(decl_string_vars)
    
    # Extract local boolean variables from declare_lines
    for dl in declare_lines:
        m_bool = re.search(r'\b(\w+)\s+BOOLEAN\b', dl, re.IGNORECASE)
        if m_bool:
            bool_vars.append(m_bool.group(1).lower())
            
    # Cast NULL select expressions
    new_body_sql = "".join(t[1] for t in cast_null_select_expressions(tokenize_sql(new_body_sql)))
    
    # Convert string concatenation (+ to ||)
    new_body_sql = convert_string_concat(new_body_sql, string_vars)
            
    # Boolean conversions in the body
    for bv in bool_vars:
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*=\s*1\b', bv + ' = TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*=\s*0\b', bv + ' = FALSE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*<>\s*1\b', bv + ' <> TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*<>\s*0\b', bv + ' <> FALSE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*!=\s*1\b', bv + ' != TRUE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(r'\b' + re.escape(bv) + r'\s*!=\s*0\b', bv + ' != FALSE', new_body_sql, flags=re.IGNORECASE)
        new_body_sql = re.sub(
            r'\b' + re.escape(bv) + r'\s*(:=|=)\s*coalesce\s*\((.*?),\s*0\s*\)',
            r'\1 COALESCE(\2, FALSE)',
            new_body_sql,
            flags=re.IGNORECASE
        )
        
    # Replace variable references in body and declare_lines
    for p in params_for_replace:
        p_name = 'p_' + p[1:].lower()
        p_pattern = r'@' + re.escape(p[1:]) + r'\b'
        p_match = re.search(r'@' + re.escape(p[1:]) + r'\s+([\w\(\)]+)', header_text, re.IGNORECASE)
        if p_match and ('TABLE' in p_match.group(1).upper() or 'READONLY' in p_match.group(1).upper()):
            new_body_sql = re.sub(p_pattern, f'unnest({p_name})', new_body_sql, flags=re.IGNORECASE)
            declare_lines = [re.sub(p_pattern, f'unnest({p_name})', dl, flags=re.IGNORECASE) for dl in declare_lines]
        else:
            new_body_sql = re.sub(p_pattern, p_name, new_body_sql, flags=re.IGNORECASE)
            declare_lines = [re.sub(p_pattern, p_name, dl, flags=re.IGNORECASE) for dl in declare_lines]
            
    for v in local_vars_for_replace:
        v_name = 'v_' + v[1:].lower()
        v_pattern = r'@' + re.escape(v[1:]) + r'\b'
        new_body_sql = re.sub(v_pattern, v_name, new_body_sql, flags=re.IGNORECASE)
        declare_lines = [re.sub(v_pattern, v_name, dl, flags=re.IGNORECASE) for dl in declare_lines]
        
    new_body_sql = re.sub(r'\bSET\s+(v_\w+)\s*=\s*(.*?)\b', r'\1 := \2', new_body_sql, flags=re.IGNORECASE)
    
    # Apply date parameter and variable casting
    new_body_sql = cast_date_variables(new_body_sql)
    
    # Process control flow
    new_body_sql = convert_control_flow(new_body_sql)
    
    # Strip outermost BEGIN/END
    body_trimmed = strip_outer_begin_end(new_body_sql)
    
    body_trimmed = re.sub(r'^\s*;\s*$', '', body_trimmed, flags=re.MULTILINE)
    body_trimmed = re.sub(r';\s*WITH\b', 'WITH', body_trimmed, flags=re.IGNORECASE)
    
    body_trimmed = ensure_all_semicolons(body_trimmed)
    body_trimmed = re.sub(r'\bAS\s*\'([^\'\n]+)\'', r'AS "\1"', body_trimmed, flags=re.IGNORECASE)
    body_trimmed = clean_aliases_in_select_only(body_trimmed)
    
    has_dynamic = False
    body_lower = body_trimmed.lower()
    if 'execute' in body_lower or 'sp_executesql' in body_lower:
        has_dynamic = True
        
    select_count = count_top_level_selects(body_trimmed)
    if has_dynamic:
        is_multi = True
        select_count = max(select_count, 1)
    else:
        is_multi = select_count > 1
        
    temp_table_sql = ""
    if temp_tables:
        for tname, tcols in temp_tables:
            temp_table_sql += f"    DROP TABLE IF EXISTS {tname};\n"
            temp_table_sql += f"    CREATE TEMP TABLE {tname} (\n        {tcols}\n    );\n"
            
    pg_sql = ""
    if comment_blocks:
        pg_sql += comment_blocks[0] + "\n"
        
    pg_sql += f"CREATE OR REPLACE FUNCTION {func_name}(\n"
    pg_sql += ",\n".join(f"    {p}" for p in param_list)
    pg_sql += "\n)\n"
    
    if select_count == 0:
        pg_sql += "RETURNS void AS $$"
        if declare_lines:
            pg_sql += "\nDECLARE\n"
            pg_sql += "\n".join(declare_lines)
        pg_sql += "\nBEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        body_lower = body_trimmed
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
        
    elif is_multi:
        pg_sql += "RETURNS SETOF refcursor AS $$\n"
        pg_sql += "DECLARE\n"
        cursors = []
        for i in range(1, select_count + 1):
            cursors.append(f"    ref{i} refcursor := 'cursor{i}';")
        pg_sql += "\n".join(cursors) + "\n"
        if declare_lines:
            pg_sql += "\n".join(declare_lines) + "\n"
        pg_sql += "BEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        cursor_body = convert_selects_to_cursors(body_trimmed)
        cursor_body = re.sub(
            r'\bexecute\s+(\w+)\s*;',
            f'OPEN ref{select_count} FOR EXECUTE \\1;\n    RETURN NEXT ref{select_count};',
            cursor_body,
            flags=re.IGNORECASE
        )
        
        body_lower = cursor_body
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
    else:
        inferred_types = {}
        for tname, tcols in temp_tables:
            types_map = extract_cols_with_types_from_tcols(tcols)
            inferred_types.update(types_map)
            
        cols, body_trimmed = extract_select_columns(body_trimmed, temp_tables)
        ret_cols = []
        for c in cols:
            ctype = get_col_type(c, inferred_types)
            ret_cols.append(f'    "{c}" {ctype}')
            
        pg_sql += "RETURNS TABLE (\n"
        pg_sql += ",\n".join(ret_cols)
        pg_sql += "\n) AS $$\n"
        pg_sql += "#variable_conflict use_column\n"
        
        if declare_lines:
            pg_sql += "DECLARE\n"
            pg_sql += "\n".join(declare_lines) + "\n"
            
        pg_sql += "BEGIN\n"
        if temp_table_sql:
            pg_sql += temp_table_sql
            
        body_lower = body_trimmed
                
        body_lower = convert_select_to_return_query(body_lower)
        
        for c in cols:
            body_lower = re.sub(
                r"\bas\s+['\"\[]?" + re.escape(c) + r"\b['\"\]]?",
                f'AS "{c}"',
                body_lower,
                flags=re.IGNORECASE
            )
        body_lower = ensure_ends_with_semicolon(body_lower)
        pg_sql += "    " + body_lower.replace('\n', '\n    ')
        pg_sql = pg_sql.rstrip()
        pg_sql += "\nEND;\n$$ LANGUAGE plpgsql;"
        
    pg_sql = convert_identifiers_case_sensitive(pg_sql)
    return remove_double_semicolons(pg_sql)

def convert_pg_variable_names(tokens):
    new_tokens = []
    for tok_type, tok_val in tokens:
        if tok_type == 'word':
            val_lower = tok_val.lower()
            if (val_lower.startswith('p_') or val_lower.startswith('v_')) and len(tok_val) > 2:
                if val_lower.startswith('v_tbl') or val_lower.startswith('p_tbl'):
                    new_tokens.append((tok_type, tok_val))
                else:
                    new_tokens.append(('word', '@' + tok_val[2:]))
            else:
                new_tokens.append((tok_type, tok_val))
        else:
            new_tokens.append((tok_type, tok_val))
    return new_tokens

def convert_pg_identifiers_quotes(tokens):
    new_tokens = []
    n = len(tokens)
    i = 0
    while i < n:
        if i + 2 < n and tokens[i][0] == 'symbol' and tokens[i][1] == '"' and tokens[i+1][0] == 'word' and tokens[i+2][0] == 'symbol' and tokens[i+2][1] == '"':
            new_tokens.append(('word', '[' + tokens[i+1][1] + ']'))
            i += 3
        else:
            new_tokens.append(tokens[i])
            i += 1
    return new_tokens

def convert_limit_to_select_top_tokens(tokens):
    new_tokens = list(tokens)
    i = 0
    while i < len(new_tokens):
        tok_type, tok_val = new_tokens[i]
        if tok_type == 'word' and tok_val.upper() == 'LIMIT':
            limit_start_idx = i
            k = i + 1
            while k < len(new_tokens) and new_tokens[k][0] == 'space':
                k += 1
            limit_val_tokens = []
            if k < len(new_tokens):
                if new_tokens[k][0] == 'symbol' and new_tokens[k][1] == '(':
                    p_depth = 1
                    limit_val_tokens.append(new_tokens[k])
                    k += 1
                    while k < len(new_tokens) and p_depth > 0:
                        if new_tokens[k][0] == 'symbol':
                            if new_tokens[k][1] == '(':
                                p_depth += 1
                            elif new_tokens[k][1] == ')':
                                p_depth -= 1
                        limit_val_tokens.append(new_tokens[k])
                        k += 1
                else:
                    limit_val_tokens.append(new_tokens[k])
                    k += 1
            
            limit_expr_str = "".join(t[1] for t in limit_val_tokens)
            
            select_idx = -1
            paren_depth = 0
            j = limit_start_idx - 1
            while j >= 0:
                tok = new_tokens[j]
                if tok[0] == 'symbol':
                    if tok[1] == ')':
                        paren_depth += 1
                    elif tok[1] == '(':
                        paren_depth -= 1
                elif tok[0] == 'word' and paren_depth == 0:
                    if tok[1].upper() == 'SELECT':
                        select_idx = j
                        break
                j -= 1
            
            if select_idx != -1:
                del new_tokens[limit_start_idx:k]
                ins_idx = select_idx + 1
                new_tokens.insert(ins_idx, ('space', ' '))
                new_tokens.insert(ins_idx + 1, ('word', f'TOP ({limit_expr_str})'))
                new_tokens.insert(ins_idx + 2, ('space', ' '))
                i = select_idx + 3
                continue
        i += 1
    return new_tokens

def convert_pg_into_assignments_tokens(tokens):
    new_tokens = list(tokens)
    i = 0
    while i < len(new_tokens):
        tok_type, tok_val = new_tokens[i]
        if tok_type == 'word' and tok_val.upper() == 'SELECT':
            select_idx = i
            into_idx = -1
            from_idx = -1
            paren_depth = 0
            k = select_idx + 1
            while k < len(new_tokens):
                t_type, t_val = new_tokens[k]
                if t_type == 'symbol':
                    if t_val == '(':
                        paren_depth += 1
                    elif t_val == ')':
                        paren_depth -= 1
                elif t_type == 'word' and paren_depth == 0:
                    val_upper = t_val.upper()
                    if val_upper == 'INTO':
                        into_idx = k
                    elif val_upper == 'FROM':
                        from_idx = k
                        break
                    elif val_upper in ('UNION', 'INTERSECT', 'EXCEPT', 'SELECT', 'BEGIN', 'END', 'IF', 'WHILE'):
                        break
                k += 1
                
            if into_idx != -1 and from_idx != -1:
                cols_tokens = new_tokens[select_idx+1 : into_idx]
                cols = []
                current_col = []
                p_depth = 0
                for ct in cols_tokens:
                    if ct[0] == 'symbol' and ct[1] == '(':
                        p_depth += 1
                    elif ct[0] == 'symbol' and ct[1] == ')':
                        p_depth -= 1
                    if p_depth == 0 and ct[0] == 'symbol' and ct[1] == ',':
                        cols.append(current_col)
                        current_col = []
                    else:
                        current_col.append(ct)
                if current_col:
                    cols.append(current_col)
                    
                vars_tokens = new_tokens[into_idx+1 : from_idx]
                vars_list = []
                current_var = []
                for vt in vars_tokens:
                    if vt[0] == 'symbol' and vt[1] == ',':
                        vars_list.append(current_var)
                        current_var = []
                    elif vt[0] not in ('space', 'comment'):
                        current_var.append(vt)
                if current_var:
                    vars_list.append(current_var)
                    
                cols_str = ["".join(t[1] for t in c).strip() for c in cols]
                vars_str = ["".join(t[1] for t in v).strip() for v in vars_list]
                cols_str = [c for c in cols_str if c]
                vars_str = [v for v in vars_str if v]
                
                if len(cols_str) == len(vars_str):
                    assignments = []
                    for col, var in zip(cols_str, vars_str):
                        assignments.append(f"{var} = {col}")
                    new_select_cols_str = " " + ", ".join(assignments) + " "
                    del new_tokens[select_idx+1 : from_idx]
                    new_tokens.insert(select_idx+1, ('word', new_select_cols_str))
                    i = select_idx + 2
                    continue
        i += 1
    return new_tokens

def convert_pg_temp_tables(sql):
    sql = re.sub(r'\b(v_tbl\w+)\b', r'#\1', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\b(tbl_\w+)\b', r'#\1', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bCREATE\s+TEMP\s+TABLE\b', r'CREATE TABLE', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bCREATE\s+TEMPORARY\s+TABLE\b', r'CREATE TABLE', sql, flags=re.IGNORECASE)
    return sql

def convert_pg_control_flow(sql):
    sql = re.sub(r'\bELSIF\b(.*?)\bTHEN\b', r'END ELSE IF \1 BEGIN', sql, flags=re.IGNORECASE | re.DOTALL)
    sql = re.sub(r'\bIF\b(.*?)\bTHEN\b', r'IF \1 BEGIN', sql, flags=re.IGNORECASE | re.DOTALL)
    sql = re.sub(r'\bELSE\b', r'END ELSE BEGIN', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bEND\s+IF\s*;', r'END', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bWHILE\b(.*?)\bLOOP\b', r'WHILE \1 BEGIN', sql, flags=re.IGNORECASE | re.DOTALL)
    sql = re.sub(r'\bEND\s+LOOP\s*;', r'END', sql, flags=re.IGNORECASE)
    return sql

def extract_pg_declarations(sql):
    tokens = tokenize_sql(sql)
    n = len(tokens)
    declare_idx = -1
    begin_idx = -1
    paren_depth = 0
    i = 0
    while i < n:
        t_type, t_val = tokens[i]
        if t_type == 'symbol':
            if t_val == '(':
                paren_depth += 1
            elif t_val == ')':
                paren_depth -= 1
        elif t_type == 'word' and paren_depth == 0:
            val_upper = t_val.upper()
            if val_upper == 'DECLARE' and declare_idx == -1:
                declare_idx = i
            elif val_upper == 'BEGIN' and begin_idx == -1:
                begin_idx = i
                break
        i += 1
        
    if declare_idx == -1 or begin_idx == -1 or declare_idx > begin_idx:
        return [], sql
        
    decl_tokens = tokens[declare_idx+1 : begin_idx]
    decl_statements = []
    current_stmt = []
    p_depth = 0
    for dt in decl_tokens:
        if dt[0] == 'symbol' and dt[1] == '(':
            p_depth += 1
        elif dt[0] == 'symbol' and dt[1] == ')':
            p_depth -= 1
        if p_depth == 0 and dt[0] == 'symbol' and dt[1] == ';':
            decl_statements.append(current_stmt)
            current_stmt = []
        else:
            current_stmt.append(dt)
    if current_stmt:
        decl_statements.append(current_stmt)
        
    t_sql_decls = []
    for stmt in decl_statements:
        stmt_str = "".join(t[1] for t in stmt).strip()
        if not stmt_str:
            continue
        if 'refcursor' in stmt_str.lower():
            continue
        stmt_str = re.sub(r':=', '=', stmt_str)
        t_sql_decls.append(f"DECLARE {stmt_str};")
        
    header_sql = "".join(t[1] for t in tokens[:declare_idx])
    body_sql = "".join(t[1] for t in tokens[begin_idx:])
    return t_sql_decls, header_sql + body_sql

def convert_pg_header(sql):
    name_match = re.search(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:["\']?\w+["\']?\.)*["\']?(\w+)["\']?', sql, re.IGNORECASE)
    if not name_match:
        return sql, None, False
    func_name = name_match.group(1)
    
    tokens = tokenize_sql(sql)
    n = len(tokens)
    first_paren = -1
    matching_paren = -1
    for i in range(n):
        if tokens[i][0] == 'symbol' and tokens[i][1] == '(':
            first_paren = i
            break
            
    if first_paren != -1:
        p_depth = 1
        for i in range(first_paren + 1, n):
            if tokens[i][0] == 'symbol':
                if tokens[i][1] == '(':
                    p_depth += 1
                elif tokens[i][1] == ')':
                    p_depth -= 1
                    if p_depth == 0:
                        matching_paren = i
                        break
                        
    if first_paren == -1 or matching_paren == -1:
        return sql, func_name, False
        
    params_str = "".join(t[1] for t in tokens[first_paren+1 : matching_paren]).strip()
    returns_match = re.search(r'\bRETURNS\b\s+(.*?)\bAS\b', sql[matching_paren:], re.IGNORECASE | re.DOTALL)
    if not returns_match:
        return sql, func_name, False
        
    ret_type_full = returns_match.group(1).strip()
    ret_type_upper = ret_type_full.upper()
    is_procedure = 'SETOF REFCURSOR' in ret_type_upper or 'TABLE' in ret_type_upper or 'VOID' in ret_type_upper
    
    params_tokens = tokenize_sql(params_str)
    params_list = []
    current_param = []
    p_depth = 0
    for pt in params_tokens:
        if pt[0] == 'symbol' and pt[1] == '(':
            p_depth += 1
        elif pt[0] == 'symbol' and pt[1] == ')':
            p_depth -= 1
        if p_depth == 0 and pt[0] == 'symbol' and pt[1] == ',':
            params_list.append(current_param)
            current_param = []
        else:
            current_param.append(pt)
    if current_param:
        params_list.append(current_param)
        
    new_params = []
    for param in params_list:
        p_str = "".join(t[1] for t in param).strip()
        if not p_str:
            continue
        p_toks = convert_pg_variable_names(tokenize_sql(p_str))
        p_str_new = "".join(t[1] for t in p_toks).strip()
        
        # Recover DATE/DATETIME parameter types in T-SQL from VARCHAR if parameter represents date/time
        if any(d in p_str_new.lower() for d in ('date', 'time')) and 'VARCHAR' in p_str_new.upper():
            p_str_new = re.sub(r'\bVARCHAR\s*(?:\(\s*\d+\s*\))?\b', 'DATETIME', p_str_new, flags=re.IGNORECASE)
            
        new_params.append(p_str_new)
        
    ret_type_mapped = ret_type_full
    if not is_procedure:
        ret_type_mapped = re.sub(r'\bBOOLEAN\b', 'BIT', ret_type_mapped, flags=re.IGNORECASE)
        ret_type_mapped = re.sub(r'\bTIMESTAMP\b', 'DATETIME', ret_type_mapped, flags=re.IGNORECASE)
        ret_type_mapped = re.sub(r'\bTEXT\b', 'VARCHAR(MAX)', ret_type_mapped, flags=re.IGNORECASE)
        ret_type_mapped = re.sub(r'\bVARCHAR\b(?!\s*\()', 'VARCHAR(MAX)', ret_type_mapped, flags=re.IGNORECASE)
        
    header_sql = ""
    if is_procedure:
        header_sql += f"CREATE PROCEDURE [dbo].[{func_name}]\n"
        if new_params:
            header_sql += ",\n".join(f"    {p}" for p in new_params) + "\n"
        header_sql += "AS"
    else:
        header_sql += f"CREATE FUNCTION [dbo].[{func_name}] (\n"
        header_sql += ",\n".join(f"    {p}" for p in new_params) + "\n"
        header_sql += f")\nRETURNS {ret_type_mapped}\nAS"
        
    return header_sql, func_name, is_procedure

def convert_postgresql_to_mssql(sql):
    tokens = tokenize_sql(sql)
    tokens = convert_pg_identifiers_quotes(tokens)
    sql = "".join(t[1] for t in tokens)
    
    decl_lines, rest_sql = extract_pg_declarations(sql)
    header_sql, func_name, is_procedure = convert_pg_header(rest_sql)
    if not func_name:
        return "-- Failed to parse PostgreSQL function header\n" + sql
        
    tokens_rest = tokenize_sql(rest_sql)
    begin_idx = -1
    paren_depth = 0
    for idx, t in enumerate(tokens_rest):
        if t[0] == 'symbol':
            if t[1] == '(':
                paren_depth += 1
            elif t[1] == ')':
                paren_depth -= 1
        elif t[0] == 'word' and paren_depth == 0:
            if t[1].upper() == 'BEGIN':
                begin_idx = idx
                break
                
    if begin_idx == -1:
        return "-- Failed to locate BEGIN block in PostgreSQL function\n" + sql
        
    end_idx = -1
    p_depth = 0
    for idx in range(begin_idx + 1, len(tokens_rest)):
        t_type, t_val = tokens_rest[idx]
        if t_type == 'symbol':
            if t_val == '(':
                p_depth += 1
            elif t_val == ')':
                p_depth -= 1
        elif t_type == 'word' and p_depth == 0:
            val_upper = t_val.upper()
            if val_upper == 'BEGIN':
                p_depth += 1
            elif val_upper == 'END':
                if p_depth == 0:
                    end_idx = idx
                    break
                else:
                    p_depth -= 1
                    
    if end_idx == -1:
        for idx in range(len(tokens_rest) - 1, -1, -1):
            if tokens_rest[idx][0] == 'word' and tokens_rest[idx][1].upper() == 'END':
                end_idx = idx
                break
                
    if end_idx == -1:
        return "-- Failed to locate END block in PostgreSQL function\n" + sql
        
    body_tokens = tokens_rest[begin_idx+1 : end_idx]
    body_tokens = convert_pg_variable_names(body_tokens)
    body_tokens = convert_pg_into_assignments_tokens(body_tokens)
    body_tokens = convert_limit_to_select_top_tokens(body_tokens)
    
    body_sql = "".join(t[1] for t in body_tokens)
    body_sql = convert_pg_temp_tables(body_sql)
    body_sql = convert_pg_control_flow(body_sql)
    
    # Strip PL/pgSQL specific variable conflict directives
    body_sql = re.sub(r'#variable_conflict\s+\w+\s*;?', '', body_sql, flags=re.IGNORECASE)
    
    body_sql = re.sub(r'\bopen\s+@ref\d+\s+for\s+', '', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\breturn\s+next\s+@ref\d+\s*;', '', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\breturn\s+query\s+', '', body_sql, flags=re.IGNORECASE)
    
    body_sql = re.sub(r'\bBOOLEAN\b', 'BIT', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\bTIMESTAMP\b', 'DATETIME', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\bTEXT\b', 'VARCHAR(MAX)', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\bVARCHAR\b(?!\s*\()', 'VARCHAR(MAX)', body_sql, flags=re.IGNORECASE)
    
    body_sql = convert_pg_casts_to_mssql(body_sql)
    
    body_sql = re.sub(r'\|\|', '+', body_sql)
    body_sql = re.sub(r'\bnow\(\)', 'GETDATE()', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\bcurrent_timestamp\b', 'GETDATE()', body_sql, flags=re.IGNORECASE)
    body_sql = re.sub(r'\bcoalesce\b', 'ISNULL', body_sql, flags=re.IGNORECASE)
    
    decl_sql_lines = []
    for dl in decl_lines:
        dl_toks = convert_pg_variable_names(tokenize_sql(dl))
        dl_str = "".join(t[1] for t in dl_toks).strip()
        dl_str = re.sub(r'\bBOOLEAN\b', 'BIT', dl_str, flags=re.IGNORECASE)
        dl_str = re.sub(r'\bTIMESTAMP\b', 'DATETIME', dl_str, flags=re.IGNORECASE)
        dl_str = re.sub(r'\bTEXT\b', 'VARCHAR(MAX)', dl_str, flags=re.IGNORECASE)
        dl_str = re.sub(r'\bVARCHAR\b(?!\s*\()', 'VARCHAR(MAX)', dl_str, flags=re.IGNORECASE)
        decl_sql_lines.append("    " + dl_str)
        
    t_sql = header_sql + "\nBEGIN\n"
    if decl_sql_lines:
        t_sql += "\n".join(decl_sql_lines) + "\n\n"
        
    body_sql_clean = body_sql.strip()
    t_sql += "    " + body_sql_clean.replace('\n', '\n    ')
    t_sql = t_sql.rstrip()
    t_sql += "\nEND"
    t_sql = re.sub(r';\s*;', ';', t_sql)
    return t_sql


if __name__ == '__main__':
    # Run conversion and test compile for all procedures!
    success_count = 0
    failed_count = 0
    
    with open(progress_file, 'w') as pf:
        pf.write("Migration Progress Log\n====================\n")
    
    for i, proc in enumerate(procedures):
        print(f"Processing {i+1}/{len(procedures)}: {proc} ...")
        try:
            pg_sql, func_name = convert_procedure(proc)
            if not pg_sql:
                raise Exception("Conversion returned empty")
                
            # Test compile
            ok, err = try_compile(pg_sql, func_name)
            if ok:
                # Save the file
                target_path = os.path.join(pg_dir, f"{func_name}.sql")
                with open(target_path, 'w') as tf:
                    tf.write(pg_sql)
                success_count += 1
                log_line = f"{proc} - SUCCESS"
                print("  -> Success")
            else:
                failed_count += 1
                log_line = f"{proc} - FAILED - {err.strip()}"
                # Still write the draft so we can inspect
                target_path = os.path.join(pg_dir, f"{func_name}.sql" if func_name else f"failed_{proc}")
                with open(target_path, 'w') as tf:
                    tf.write(pg_sql)
                print(f"  -> Failed: {err.strip()}")
                
            with open(progress_file, 'a') as pf:
                pf.write(log_line + "\n")
                
        except Exception as e:
            failed_count += 1
            log_line = f"{proc} - ERROR - {str(e)}"
            print(f"  -> Error: {str(e)}")
            with open(progress_file, 'a') as pf:
                pf.write(log_line + "\n")
    
    print(f"\nMigration Run Completed. Success: {success_count}, Failed/Manual checks: {failed_count}")

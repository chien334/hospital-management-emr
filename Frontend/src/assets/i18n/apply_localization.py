import os
import re
import json

# Paths
WORKSPACE_DIR = '/Users/macbbook/SourceCodes/hospital-management-emr'
LABS_DIR = f'{WORKSPACE_DIR}/Frontend/src/app/labs'
EXTRACTED_JSON_PATH = f'{WORKSPACE_DIR}/Frontend/src/assets/i18n/extracted_labs_strings.json'
TRANSLATION_MAP_PATH = f'{WORKSPACE_DIR}/Frontend/src/assets/i18n/translation_map.json'
TEMP_VI_PATH = f'{WORKSPACE_DIR}/Frontend/src/assets/i18n/temp_vi_labs.json'
TEMP_EN_PATH = f'{WORKSPACE_DIR}/Frontend/src/assets/i18n/temp_en_labs.json'

def get_param_name(expr, idx):
    # Remove pipes or formatting
    expr_clean = expr.split('|')[0].strip()
    # Remove parenthesis if any
    expr_clean = re.sub(r'\(.*?\)', '', expr_clean).strip()
    # Split by dots or question-mark-dots
    parts = re.split(r'[\.\?]', expr_clean)
    parts = [p.strip() for p in parts if p.strip()]
    if parts:
        last_part = parts[-1]
        # Check if it is a valid identifier
        if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', last_part):
            return last_part
    return f"param{idx}"

def make_interp_pattern(interp):
    pat = re.escape(interp)
    # Replace any sequence of escaped spaces or raw spaces/newlines with a single \s*
    pat = re.sub(r'(?:\\ )+', r'\\s*', pat)
    pat = re.sub(r'\s+', r'\\s*', pat)
    pat = re.sub(r'(?:\\s\*)+', r'\\s*', pat)
    return pat

def process_interpolations(eng_text, vi_text):
    interps = re.findall(r'\{\{.*?\}\}', eng_text, re.DOTALL)
    
    param_bindings = {}
    param_json_eng = eng_text
    param_json_vi = vi_text
    
    for idx, interp in enumerate(interps):
        expr = interp[2:-2].strip()
        param_name = get_param_name(expr, idx)
        
        # Avoid duplicate param names
        orig_param_name = param_name
        counter = 1
        while param_name in param_bindings and param_bindings[param_name] != expr:
            param_name = f"{orig_param_name}{counter}"
            counter += 1
            
        param_bindings[param_name] = expr
        
        # Replace in English JSON value
        param_json_eng = param_json_eng.replace(interp, f"{{{{{param_name}}}}}")
        
        # Replace in Vietnamese JSON value (handling whitespace variations)
        escaped_interp = make_interp_pattern(interp)
        param_json_vi = re.sub(escaped_interp, f"{{{{{param_name}}}}}", param_json_vi, flags=re.DOTALL)
        
    return param_json_eng, param_json_vi, param_bindings

# Abbreviation updates for Vietnamese
abbrev_updates = {
    "FILTER_SMS": "Lọc tin nhắn (SMS):",
    "SEND_SMS": "Gửi tin nhắn (SMS)",
    "PDF_SMS": "Tệp PDF & Tin nhắn (PDF & SMS)",
    "UPLOAD_PDF": "Tải lên tệp PDF (PDF)",
    "SMS_MESSAGE": "Nội dung tin nhắn (SMS)",
    "EXPORT_WITH_SMS": "Xuất cùng tin nhắn (SMS)",
    "UPLOAD_TO_IMU": "Tải lên Cục Quản lý Thông tin Y tế (IMU - Information Management Unit)",
    "GOV_LABREPORTITEM_NAME": "Tên mục báo cáo phòng xét nghiệm Chính phủ (Gov. Lab Report Item):",
    "ENTER_GOV_LAB_REPORT_NAME": "Nhập tên báo cáo phòng xét nghiệm Chính phủ (Gov. Lab Report Name)",
    "DEFAULT_HISTOCYTO_SIGNATORIES": "Người ký Giải phẫu bệnh/Tế bào học mặc định (Histo/Cyto Signatories):",
    "IS_SMS_APPLICABLE": "Có áp dụng tin nhắn (SMS) không?",
    "IS_LIS_APPLICABLE": "Có áp dụng hệ thống thông tin phòng xét nghiệm (LIS - Laboratory Information System) không?",
    "BARCODE_NO": "Số mã vạch (Barcode No.)",
    "BARCODE_NO_1": "Số mã vạch (Barcode No.)",
    "ER": "Khoa cấp cứu (ER - Emergency Room)",
    "AD": "(Dương lịch - AD)",
    "BS": "(Lịch Nepal - BS)",
    "CHANGE_DATE_FORMAT_TO_ADBS": "Thay đổi định dạng ngày thành Dương lịch/Lịch Nepal (AD/BS)",
    "CLICK_TO_CHANGE_PRESCRIBER_DR": "Nhấn vào đây để thay đổi Bác sĩ kê đơn (Dr.)",
    "RN": "Số thứ tự chạy mẫu (RN - Run Number): {{SampleCodeFormatted}}"
}

def safe_replace(text, eng, token):
    pattern = re.escape(eng)
    if eng[0].isalnum() or eng[0] == '_':
        pattern = r'\b' + pattern
    if eng[-1].isalnum() or eng[-1] == '_':
        pattern = pattern + r'\b'
    regex = re.compile(pattern)
    return regex.sub(token, text)

def main():
    print("Loading extracted strings and translation map...")
    with open(EXTRACTED_JSON_PATH, 'r', encoding='utf-8') as f:
        extracted = json.load(f)
    with open(TRANSLATION_MAP_PATH, 'r', encoding='utf-8') as f:
        translation_map = json.load(f)

    # 1. Update Vietnamese values for abbreviations
    for key, vi_val in abbrev_updates.items():
        if key in translation_map:
            translation_map[key]['vietnamese'] = vi_val
            print(f"Updated abbreviation for {key}")

    # 2. Build list of replacements and generate JSON values
    replacements = []
    replacements_map = {}
    en_labs_block = {}
    vi_labs_block = {}

    # Custom new keys from translation_map
    for key, val in translation_map.items():
        eng = val['english']
        vi = val['vietnamese']
        
        param_eng, param_vi, bindings = process_interpolations(eng, vi)
        
        en_labs_block[key] = param_eng
        vi_labs_block[key] = param_vi
        
        if bindings:
            bind_str = ", ".join([f"{k}: {v}" for k, v in bindings.items()])
            repl_expr = "{{ 'LABS." + key + "' | translate: { " + bind_str + " } }}"
        else:
            repl_expr = "{{ 'LABS." + key + "' | translate }}"
            
        repl_info = {
            'english': eng,
            'repl_expr': repl_expr,
            'key': f"LABS.{key}",
            'bindings': bindings,
            'is_reusable': False
        }
        replacements.append(repl_info)
        replacements_map[eng] = repl_info

    # Reusable keys from extracted_labs_strings
    for eng, info in extracted.items():
        if info['reusable']:
            repl_expr = "{{ '" + info['reusable'] + "' | translate }}"
            repl_info = {
                'english': eng,
                'repl_expr': repl_expr,
                'key': info['reusable'],
                'bindings': {},
                'is_reusable': True
            }
            replacements.append(repl_info)
            replacements_map[eng] = repl_info

    # Sort replacements by English length descending to avoid substring replacement bugs
    replacements.sort(key=lambda x: len(x['english']), reverse=True)

    # Write temp JSON files
    print(f"Writing {TEMP_EN_PATH}...")
    with open(TEMP_EN_PATH, 'w', encoding='utf-8') as f:
        json.dump({"LABS": en_labs_block}, f, indent=2, ensure_ascii=False)

    print(f"Writing {TEMP_VI_PATH}...")
    with open(TEMP_VI_PATH, 'w', encoding='utf-8') as f:
        json.dump({"LABS": vi_labs_block}, f, indent=2, ensure_ascii=False)

    # Regex to split HTML into text parts (even indices) and tag/comment/script/style parts (odd indices)
    # This handles comparison operators > in attributes by only matching > that is not in quotes.
    tag_or_comment_re = re.compile(
        r'(<!--.*?-->|<script\b.*?</script>|<style\b.*?</style>|<[^>"\']*(?:"[^"]*"|\'[^\']*\'|[^>"\'])*>)',
        re.DOTALL | re.IGNORECASE
    )

    # Walk HTML files
    html_files = []
    for root, dirs, files in os.walk(LABS_DIR):
        for file in files:
            if file.endswith('.html'):
                html_files.append(os.path.join(root, file))

    print(f"Found {len(html_files)} HTML files in labs module. Localizing...")

    total_files_changed = 0
    total_replacements_made = 0

    for filepath in html_files:
        rel_path = os.path.relpath(filepath, LABS_DIR)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        parts = tag_or_comment_re.split(content)
        file_changed = False

        # 3. Replace in text nodes (even indices)
        interp_re = re.compile(r'(\{\{.*?\}\})', re.DOTALL)
        for idx in range(0, len(parts), 2):
            text_part = parts[idx]
            if not text_part.strip():
                continue

            # Split text_part by interpolations to protect expressions inside {{ ... }}
            text_subparts = interp_re.split(text_part)
            for sub_idx in range(0, len(text_subparts), 2):
                subpart = text_subparts[sub_idx]
                if not subpart.strip():
                    continue

                # Token mapping to protect replacements
                tokens = {}
                temp_text = subpart

                for r_idx, repl in enumerate(replacements):
                    eng = repl['english']
                    if eng not in temp_text:
                        continue

                    token = f"__TOKEN_{r_idx}__"
                    replaced_text = safe_replace(temp_text, eng, token)
                    if replaced_text != temp_text:
                        tokens[token] = repl['repl_expr']
                        temp_text = replaced_text
                        total_replacements_made += 1
                        file_changed = True

                # Restore tokens
                for token, expr in tokens.items():
                    temp_text = temp_text.replace(token, expr)
                text_subparts[sub_idx] = temp_text

            parts[idx] = "".join(text_subparts)

        # 4. Replace in attributes inside tags (odd indices)
        attr_pattern = re.compile(
            r'(?<!\[)\b(placeholder|title|btn-text|label|tooltip|tooltip-html-unsafe)\s*=\s*(["\'])(.*?)\2',
            re.DOTALL | re.IGNORECASE
        )

        for idx in range(1, len(parts), 2):
            tag_part = parts[idx]
            # Skip comments, script, style blocks
            if tag_part.startswith('<!--') or tag_part.lower().startswith('<script') or tag_part.lower().startswith('<style'):
                continue

            def replace_attr(match):
                nonlocal file_changed, total_replacements_made
                attr_name = match.group(1)
                quote = match.group(2)
                attr_val = match.group(3).strip()
                
                if attr_val in replacements_map:
                    repl_info = replacements_map[attr_val]
                    key = repl_info['key']
                    bindings = repl_info['bindings']
                    
                    if bindings:
                        bind_str = ", ".join([f"{k}: {v}" for k, v in bindings.items()])
                        new_attr = "[" + attr_name + "]=\"'" + key + "' | translate: { " + bind_str + " }\""
                    else:
                        new_attr = "[" + attr_name + "]=\"'" + key + "' | translate\""
                    
                    total_replacements_made += 1
                    file_changed = True
                    return new_attr
                return match.group(0)

            parts[idx] = attr_pattern.sub(replace_attr, tag_part)

        if file_changed:
            new_content = "".join(parts)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            total_files_changed += 1
            print(f"Localized: {rel_path}")

    print(f"Finished localization. Modified {total_files_changed} files, made {total_replacements_made} replacements.")

if __name__ == '__main__':
    main()

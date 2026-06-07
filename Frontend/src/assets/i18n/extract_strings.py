import os
import re
import json
from html.parser import HTMLParser

# Path setup
LABS_DIR = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/app/labs'
COMMON_EN_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/en.json'
OUTPUT_JSON_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/extracted_labs_strings.json'

# Load existing COMMON and GRID_HEADERS keys
try:
    with open(COMMON_EN_PATH, 'r', encoding='utf-8') as f:
        en_json = json.load(f)
        COMMON = en_json.get("COMMON", {})
        GRID_HEADERS = en_json.get("GRID_HEADERS", {})
except Exception as e:
    print(f"Error loading en.json: {e}")
    COMMON = {}
    GRID_HEADERS = {}

# Invert maps to find matches by value
COMMON_VALS = {v.strip().lower(): k for k, v in COMMON.items()}
GRID_VALS = {v.strip().lower(): k for k, v in GRID_HEADERS.items()}

# Regex to find Angular expressions {{...}}
INTERPOLATION_RE = re.compile(r'\{\{.*?\}\}')

class LabHTMLParser(HTMLParser):
    def __init__(self, filepath):
        super().__init__()
        self.filepath = filepath
        self.strings = []
        self.in_script_or_style = False

    def handle_starttag(self, tag, attrs):
        if tag in ['script', 'style']:
            self.in_script_or_style = True
            return

        for attr, val in attrs:
            if attr in ['placeholder', 'title', 'btn-text', 'label', 'tooltip', 'tooltip-html-unsafe']:
                # Skip if empty or contains only interpolation or starts with [attr]
                if not val:
                    continue
                trimmed = val.strip()
                if trimmed and not (trimmed.startswith('{{') and trimmed.endswith('}}')):
                    # Check if it has letters
                    if any(c.isalpha() for c in trimmed):
                        self.strings.append({
                            'type': 'attribute',
                            'tag': tag,
                            'name': attr,
                            'value': trimmed
                        })

    def handle_endtag(self, tag):
        if tag in ['script', 'style']:
            self.in_script_or_style = False

    def handle_data(self, data):
        if self.in_script_or_style:
            return
        
        # Clean text data
        # We need to preserve dynamic expressions, but extract raw text around them.
        # If the text has interpolation, we might need to handle it.
        # Let's extract the clean strings that contain letters.
        
        # Let's strip whitespace
        cleaned = data.strip()
        if not cleaned:
            return
        
        # If it's just an interpolation (e.g. {{x}}), skip
        if cleaned.startswith('{{') and cleaned.endswith('}}') and cleaned.count('{{') == 1:
            return
            
        # Check if the string has letters
        if not any(c.isalpha() for c in cleaned):
            return
            
        self.strings.append({
            'type': 'text',
            'value': cleaned
        })

def scan_files():
    all_found = {}
    for root, dirs, files in os.walk(LABS_DIR):
        for file in files:
            if file.endswith('.html'):
                filepath = os.path.join(root, file)
                rel_path = os.path.relpath(filepath, LABS_DIR)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    parser = LabHTMLParser(rel_path)
                    parser.feed(content)
                    if parser.strings:
                        all_found[rel_path] = parser.strings
                except Exception as e:
                    print(f"Error parsing {rel_path}: {e}")
    
    # Analyze and group strings
    unique_strings = {}
    for file, items in all_found.items():
        for item in items:
            val = item['value']
            # Normalize key
            norm = val.strip()
            if norm not in unique_strings:
                # Check reuse
                norm_lower = norm.lower()
                reusable = None
                if norm_lower in COMMON_VALS:
                    reusable = f"COMMON.{COMMON_VALS[norm_lower]}"
                elif norm_lower in GRID_VALS:
                    reusable = f"GRID_HEADERS.{GRID_VALS[norm_lower]}"
                
                unique_strings[norm] = {
                    'occurrences': [{'file': file, 'type': item['type']}],
                    'reusable': reusable
                }
            else:
                unique_strings[norm]['occurrences'].append({'file': file, 'type': item['type']})
                
    # Save results
    with open(OUTPUT_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(unique_strings, f, indent=2, ensure_ascii=False)
        
    print(f"Scanned {len(all_found)} files. Found {len(unique_strings)} unique strings.")

if __name__ == '__main__':
    scan_files()

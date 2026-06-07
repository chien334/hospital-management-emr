import json
import re
import urllib.request
import urllib.parse
import ssl
import time

INPUT_JSON_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/extracted_labs_strings.json'
COMMON_EN_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/en.json'
MAP_OUTPUT_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/translation_map.json'

# Load existing translations
try:
    with open(COMMON_EN_PATH, 'r', encoding='utf-8') as f:
        en_json = json.load(f)
        COMMON = en_json.get("COMMON", {})
        GRID_HEADERS = en_json.get("GRID_HEADERS", {})
except Exception as e:
    COMMON = {}
    GRID_HEADERS = {}

COMMON_VALS = {v.strip().lower(): k for k, v in COMMON.items()}
GRID_VALS = {v.strip().lower(): k for k, v in GRID_HEADERS.items()}

# Helper function to check if string contains letters after removing interpolations
def has_letters_outside_interpolation(s):
    s_clean = re.sub(r'\{\{.*?\}\}', '', s)
    return any(c.isalpha() for c in s_clean)

# Helper function to generate keys
def generate_key(s):
    # Remove interpolation
    s_clean = re.sub(r'\{\{.*?\}\}', '', s)
    # Remove non-alphanumeric except space
    s_clean = re.sub(r'[^\w\s]', '', s_clean)
    # Trim and normalize spaces
    s_clean = ' '.join(s_clean.split())
    # Convert to uppercase snake case
    key = s_clean.upper().replace(' ', '_')
    # Limit length
    if len(key) > 50:
        key = key[:50].rstrip('_')
    # Handle numbers or empty keys
    if not key or not key[0].isalpha():
        key = "KEY_" + key if key else "VAL"
    return key

# Translation function
def translate_en_to_vi(text):
    if not text.strip():
        return ""
    # Preserve interpolations by replacing them with place holders like {0}, {1} etc.
    interpolations = re.findall(r'\{\{.*?\}\}', text)
    temp_text = text
    for i, interp in enumerate(interpolations):
        temp_text = temp_text.replace(interp, f" {{{i}}} ")
    
    try:
        url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=" + urllib.parse.quote(temp_text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        context = ssl._create_unverified_context()
        with urllib.request.urlopen(req, context=context, timeout=10) as response:
            res = json.loads(response.read().decode('utf-8'))
            translated = "".join([part[0] for part in res[0] if part[0]])
            
            # Put the interpolations back
            for i, interp in enumerate(interpolations):
                # Google Translate might have changed spacing around {i} or { i } or {0}
                # Let's use regex to replace {i} or similar
                pattern = re.compile(rf'\s*\{{\s*{i}\s*\}}\s*')
                translated = pattern.sub(interp, translated)
            return translated.strip()
    except Exception as e:
        print(f"Error translating '{text}': {e}")
        return text

def build_map():
    with open(INPUT_JSON_PATH, 'r', encoding='utf-8') as f:
        unique_strings = json.load(f)

    translation_map = {}
    
    # Pre-populate with reusables
    for s, info in unique_strings.items():
        if info['reusable']:
            # It's reusable, no translation needed
            continue
        
        # Check if it has letters outside interpolation
        if not has_letters_outside_interpolation(s):
            continue
            
        # Ignore some obvious non-words or symbols
        if s.strip() in ['X', 'x', '+', '-', ':', '/', '\\']:
            continue
            
        key = generate_key(s)
        
        # Avoid duplicate keys
        base_key = key
        counter = 1
        while key in translation_map or key in COMMON or key in GRID_HEADERS:
            key = f"{base_key}_{counter}"
            counter += 1
            
        translation_map[key] = {
            'english': s,
            'vietnamese': ''
        }

    print(f"Total strings requiring translation: {len(translation_map)}")
    
    # Translate
    count = 0
    for key, item in translation_map.items():
        eng = item['english']
        print(f"[{count+1}/{len(translation_map)}] Translating: {eng}")
        vi = translate_en_to_vi(eng)
        item['vietnamese'] = vi
        count += 1
        # Throttle a bit to be polite to the API
        time.sleep(0.1)

    # Save mapping
    with open(MAP_OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(translation_map, f, indent=2, ensure_ascii=False)
        
    print(f"Translation map saved to {MAP_OUTPUT_PATH}")

if __name__ == '__main__':
    build_map()

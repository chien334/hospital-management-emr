import json
import re

TO_TRANSLATE_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/to_translate.json'

with open(TO_TRANSLATE_PATH, 'r', encoding='utf-8') as f:
    strings = json.load(f)

def clean_string(s):
    # Remove interpolation block
    s_clean = re.sub(r'\{\{.*?\}\}', '', s)
    # Remove non-alphanumeric chars except space and basic chars
    s_clean = re.sub(r'[^\w\s]', '', s_clean)
    # Trim and normalize spacing
    s_clean = ' '.join(s_clean.split())
    return s_clean.strip()

normalized = {}
for s in strings:
    cleaned = clean_string(s)
    if not cleaned:
        continue
    if cleaned not in normalized:
        normalized[cleaned] = []
    normalized[cleaned].append(s)

print(f"Total original strings: {len(strings)}")
print(f"Total normalized unique strings: {len(normalized)}")

# Let's write the normalized mapping to see the unique ones
with open('/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/normalized_strings.json', 'w', encoding='utf-8') as f:
    json.dump(normalized, f, indent=2, ensure_ascii=False)

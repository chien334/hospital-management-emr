import json

INPUT_JSON_PATH = '/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/extracted_labs_strings.json'

with open(INPUT_JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

reusable = []
to_translate = []

for val, info in data.items():
    if info['reusable']:
        reusable.append((val, info['reusable']))
    else:
        to_translate.append(val)

print(f"Total: {len(data)}")
print(f"Reusable: {len(reusable)}")
print(f"To translate: {len(to_translate)}")

# Let's write the to_translate list to a temporary file
with open('/Users/macbbook/SourceCodes/hospital-management-emr/Frontend/src/assets/i18n/to_translate.json', 'w', encoding='utf-8') as f:
    json.dump(to_translate, f, indent=2, ensure_ascii=False)

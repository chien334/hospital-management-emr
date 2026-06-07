import urllib.request
import urllib.parse
import json
import ssl

def translate_en_to_vi(text):
    if not text.strip():
        return ""
    try:
        url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=" + urllib.parse.quote(text)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        context = ssl._create_unverified_context()
        with urllib.request.urlopen(req, context=context, timeout=10) as response:
            res = json.loads(response.read().decode('utf-8'))
            translated = "".join([part[0] for part in res[0] if part[0]])
            return translated
    except Exception as e:
        print(f"Error translating '{text}': {e}")
        return ""

if __name__ == '__main__':
    # Test
    print("Testing translation:")
    print("Search ->", translate_en_to_vi("Search"))
    print("Select your Lab Type ->", translate_en_to_vi("Select your Lab Type"))

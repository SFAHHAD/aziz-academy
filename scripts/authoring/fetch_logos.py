import json
import urllib.request
import urllib.parse
from html.parser import HTMLParser

class SearchParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.article_link = None
        self.in_article = False

    def handle_starttag(self, tag, attrs):
        if tag == 'article':
            self.in_article = True
        if self.in_article and tag == 'a' and not self.article_link:
            for k, v in attrs:
                if k == 'href':
                    self.article_link = v

class PostParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.img_src = None

    def handle_starttag(self, tag, attrs):
        if tag == 'img' and not self.img_src:
            src = None
            is_logo = False
            for k, v in attrs:
                if k == 'src': src = v
                if k == 'alt' and 'Logo' in v: is_logo = True
            
            if src and 'wp-content/uploads' in src:
                self.img_src = src

def get_logo_url(brand):
    print(f"Fetching {brand}...")
    try:
        url = f"https://logos-world.net/?s={urllib.parse.quote(brand)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req).read().decode('utf-8')
        
        parser = SearchParser()
        parser.feed(html)
        
        if parser.article_link:
            req2 = urllib.request.Request(parser.article_link, headers={'User-Agent': 'Mozilla/5.0'})
            html2 = urllib.request.urlopen(req2).read().decode('utf-8')
            
            p2 = PostParser()
            p2.feed(html2)
            if p2.img_src:
                return p2.img_src
    except Exception as e:
        print(f"Error {brand}: {e}")
    return None

def main():
    file_path = 'assets/data/logos.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for item in data:
        url = get_logo_url(item['brand'])
        if url:
            item['logo_url'] = url
            print(f"Found: {url}")
        else:
            print("Not found.")
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    main()

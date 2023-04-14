from magic_google import MagicGoogle

mg = MagicGoogle()
for url in mg.search_url(query='www.spiritysdx.top', num=3, language="en"):
    with open("gdlog", "w") as fp:
        fp.write(url)

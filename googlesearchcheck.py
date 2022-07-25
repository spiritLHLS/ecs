from magic_google import MagicGoogle

mg = MagicGoogle()
for url in mg.search_url(query='二叉树的博客', num=1, language="en"):
    with open("gdlog", "w") as fp:
        fp.write(url)

# Biafra Ahanonu
# 2020.07.19 [18:52:54]
# Run the following commands within Anaconda prompt or similar python environment to make the following docs.
# Changelog
	# 2020.09.28 [22:35:51] - Added ssl module.
	# 2020.09.28 [22:42:51] - Added support to automatically install missing packages. Disabled as user should do this.
	# 2021.04.05 [16:12:12] - Since all_docs uses includes, yaml extra variables are not evaluated. This is a quick way to replace them.

import subprocess
import sys
from bs4 import BeautifulSoup
import re
# import socket
# import ssl

# def install(package):
#     subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# install('mkdocs')
# install('mdx_truly_sane_lists')
# install('pymdown-extensions')
# pip install mkdocs
# pip install mdx_truly_sane_lists
# pip install pymdown-extensions
# pip install mkdocs-macros-plugin
# pip install mkdocs-markdownextradata-plugin
# pip install markdown-include

# If you want to view the docs before building
# mkdocs serve

# Build the documents
# mkdocs build
subprocess.check_call([sys.executable, "-m", "mkdocs", "build"])


# Since all_docs uses includes, yaml extra variables are not evaluated. This is a quick way to replace them.
f = open('site/all_docs/index.html','r')
html = f.read()
f.close()
soup = BeautifulSoup(html)

extraDict = {
  '{{ site.name }}': 'CIAtah',
  '{{ site.namelow }}': 'ciatah',
  '{{ site.nameold }}': 'calciumImagingAnalysis',
  '{{ code.mainclass }}': 'ciatah',
  '{{</span> <span class="n">code</span><span class="p">.</span><span class="n">mainclass</span> <span class="p">}}': 'ciatah'
}
for key in extraDict:
	target = soup.find_all(text=re.compile(re.escape(key)))
	# target = soup.find_all(text=re.compile(r'{{ site.name }}'))
	for v in target:
	    v.replace_with(v.replace(key,extraDict[key]))

# print soup
f = open('site/all_docs/index.html','w')
soup_string = str(soup)
soup_string = soup_string.replace('{{</span> <span class="n">code</span><span class="p">.</span><span class="n">mainclass</span> <span class="p">}}', 'ciatah')
f.write(soup_string)
f.close()
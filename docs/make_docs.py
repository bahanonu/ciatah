# Biafra Ahanonu
# 2020.07.19 [18:52:54]
# Run the following commands within Anaconda prompt or similar python environment to make the following docs.

import subprocess
import sys

def install(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

install('mkdocs')
install('mdx_truly_sane_lists')
install('pymdown-extensions')
# pip install mkdocs
# pip install mdx_truly_sane_lists
# pip install pymdown-extensions

# If you want to view the docs before building
# mkdocs serve

# Build the documents
# mkdocs build
subprocess.check_call([sys.executable, "-m", "mkdocs", "build"])
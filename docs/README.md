# CIAtah documentation

This directory contains the documentation for `CIAtah` that can be built from the Markdown files using `Python 3.7` or greater.

## Instructions

The documentation can always be found at https://bahanonu.github.io/calciumImagingAnalysis/.

Run `make_docs_local.py`, e.g. `python -m make_docs_local.py` in the command line, to make the documents to view locally.

Run `make_docs.py`, e.g. `python -m make_docs.py` in the command line, to make the documents for online, e.g. where each page is a directory with a `index.html` file.

## Dependencies

Run the below `pip` commands to make sure all dependencies are installed.

```
pip install mkdocs

pip install mdx_truly_sane_lists

pip install pymdown-extensions
```
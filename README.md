# latex-tech-pub

Support repo for the book *Technical Publishing with LaTeX*.
Information on the book is available at [Leanpub](https://leanpub.com/latex-tech-pub).

# Usage

Copy `build-latex.ps1` and/or `build-latex.sh` to a location in your
path. Alternatively, symlink to these files.

## Simple usage

`> build-latex.ps1 -all main` --or-- `> build-latex -all main`

`$ build-latex.sh --all main`

Builds PDF, HTML, ePub, and Markdown documents from the `main.tex` file.
Uses `main-print.tex`, `main-pdf.tex`, `main-web.tex`, `main-md.tex`, and `main-epub.tex` files instead if they exist.

## List of options

`> Get-Help build-latex`

`$ build-latex.sh --help`

Displays the help file with all of the available options.

# Software used

## Required software

- `pdflatex`, `biber`, and `makeglossaries` for PDF output
- `pandoc` or `tex4ebook` for ePub output
- `pandoc` or `make4ht` for HTML output
- `pandoc` for Markdown output

## Optional software

- `latexmk` for PDF output (used by default if found in path)
- `tidy` for ePub and HTML output

# Changelog

| Release | Date | Author | Changes |
| --- | --- | --- | --- |
| 00.00.06 | 2023-Feb-18 | akulcsar | Split print-ready PDF into its own option. Add items related to automatically building figures to the README to-do list. Add version string. |
| 00.00.05 | 2022-Aug-11 | akulcsar | Build web sites, ePubs, and Markdown files. Add post-clean flag. Support multiple main files. |
| 00.00.04 | 2022-Jul-16 | akulcsar | Support latexmk and LuaLaTeX. |
| 00.00.03 | 2022-Jul-12 | akulcsar | Add interactive mode. |
| 00.00.02 | 2022-Jun-26 | akulcsar | Repackage as a single script with functions. |
| 00.00.01 | 2022-Jun-20 | akulcsar | Initial version with PDF support and sample book. |

# To Do

| Work item | PowerShell | bash |
| --- | --- | --- |
| Sample book | 00.00.01 | 00.00.01 |
| ... Multiple chapters | 00.00.01 | 00.00.01 |
| ... Bibliography | 00.00.01 | 00.00.01 |
| ... Index | 00.00.01 | 00.00.01 |
| ... Glossary | 00.00.01 | 00.00.01 |
| Builds | | |
| ... Online PDF build | 00.00.01 | 00.00.01 |
| ... Printed PDF build | 00.00.06 | 00.00.06 |
| ... ePub3 build (tex4ebook) | 00.00.05 | 00.00.05 |
| ... ePub3 build (pandoc) | 00.00.05 | 00.00.05 |
| ... HTML build (make4ht) | 00.00.05 | 00.00.05 |
| ... HTML build (pandoc) | 00.00.05 | 00.00.05 |
| ... Markdown build | 00.00.05 | 00.00.05 |
| Return to original directory when done | 00.00.03 | 00.00.03 |
| pandoc option | 00.00.05 | 00.00.05 |
| Support configuration file for alternate binary locations | | |
| Support multiple main files with suffixes | 00.00.05 | 00.00.05 |
| ...For print-ready PDF, look for -print.tex then -pdf.tex | 00.00.05 | 00.00.05 |
| ...For PDF, look for -pdf.tex | 00.00.05 | 00.00.05 |
| ...For ePub, look for -epub.tex then -web.tex | 00.00.05 | 00.00.05 |
| ...For Markdown, look for -md.tex then -web.tex | 00.00.05 | 00.00.05 |
| ...For HTML, look for -web.tex | 00.00.05 | 00.00.05 |
| Model --clean routine after PowerShell version | N/A | |
| Allow --help to be called without requiring main file | N/A | 00.00.01 |
| Add --post-clean flag to cleanup after builds | 00.00.05 | 00.00.05 |
| Automatically generate figure files | | |
| ... Microsoft PXT (MakeCode) block-based language | | |
| ... Plant UML figures | | |
| ... Mermaid figures | | |
| ... TikZ figures | | |

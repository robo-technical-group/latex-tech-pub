# latex-tech-pub

Support repo for the book *Technical Publishing with LaTeX*.
Information on the book is available at [Leanpub](https://leanpub.com/latex-tech-pub).

# Usage

Copy `build-latex.ps1` and/or `build-latex.sh` to a location in your
path. Alternatively, symlink to these files.

## Simple usage

`> build-latex.ps1 -all main`
`$ build-latex.sh --all main`

Builds PDF, HTML, and ePub documents from the `main.tex` file.

## List of options

`> build-latex.ps1 -help`
`$ build-latex.sh --help`

Displays the help file with all of the available options.

# Changelog

| Release | Date | Author | Changes |
| --- | --- | --- | --- |
| 00.00.04 | 2022-Jul-16 | akulcsar | Support latexmk and LuaLaTeX. |
| 00.00.03 | 2022-Jul-12 | akulcsar | Add interactive mode. |
| 00.00.02 | 2022-Jun-26 | akulcsar | Repackage as a single script with functions. |
| 00.00.01 | 2022-Jun-20 | akulcsar | Initial version with PDF support. |

# To Do

| Work item | PowerShell | bash |
| --- | --- | --- |
| Sample book | 1 | 1 |
| ... Multiple chapters | 1 | 1 |
| ... Bibliography | 1 | 1 |
| ... Index | 1 | 1 |
| ... Glossary | 1 | 1 |
| PDF build | 1 | 1 |
| ePub3 build | | |
| HTML build | | |

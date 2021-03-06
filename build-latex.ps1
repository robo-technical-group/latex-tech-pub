<#
.SYNOPSIS

Build multiple LaTeX targets from a single source.

.DESCRIPTION

Build multiple LaTeX targets from a single source.
Output files are located in the latex.out directory.

.PARAMETER MainFile
Main TeX file to compile.

.PARAMETER All
Same as --figures --pdf --epub --html.

.PARAMETER Clean
Deletes the output directory before building.

.PARAMETER Epub
Builds the ePub files.

.PARAMETER Figures
Builds any figure files located in the working directory.

.PARAMETER Html
Builds the web site files.

.PARAMETER Interactive
Runs the LaTeX executables in interactive mode.

.PARAMETER Luatex
Use LuaTeX engine instead of LaTeX engine.

.PARAMETER Pdf
Builds the PDF file.

.PARAMETER Quick
Runs just one pass of pdflatex, et al.

.PARAMETER Xetex
Use XeTeX engine instead of LaTeX engine.
#>

######################################################################
# 2022-Jun-20 Initial version.
# 2022-Jun-26 Repackage as a single script with functions.
# 2022-Jul-12 Add interactive mode; return to original work directory.
# 2022-Jul-16 Support `latexmk` and LuaLaTeX.
######################################################################
# TODO
# - [X] Add -clean -figures -pdf -epub -html switches.
# - [X] Do not automatically clean the output directory.
# - [X] Rename to `build.ps1`.
# - [X] Remove bin directory; incorporate as functions instead.
# - [X] Remove -contentdir option;
#       automatically duplicate directory structure;
#       ignore latex.out directory.
# - [X] Verify access to required executables.
# - [X] Add interactive mode.
# - [X] Support XeLaTeX.
# - [X] Remove Start-Process; revert to direct calls.
# - [X] Move executable names into variables to allow for alternate
#       specification (e.g. executable not in path).
# - [X] Return to original working directory after work has finished.
# - [X] Use `latexmk` if available.
# - [X] Rename to `build-latex` to allow placement in PATH.
# - [X] Support LuaLaTeX.
######################################################################
# BSD 3-Clause License
#
# Copyright (c) 2022, Robo Technical Group, LLC
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
######################################################################

param (
    [Parameter(Mandatory,Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$MainFile,
    [switch]$All,
    [switch]$Clean,
    [switch]$Figures,
    [switch]$Interactive,
    [switch]$Pdf,
    [switch]$Epub,
    [switch]$Html,
    [switch]$Luatex,
    [switch]$Quick,
    [switch]$Xetex
)

# Executables
# Modify (e.g. supply full path) as needed for executables not located in your path.
Set-Variable Biber -Option ReadOnly -Value "biber"
Set-Variable LatexMk -Option ReadOnly -Value "latexmk"
Set-Variable LuaLatex -Option ReadOnly -Value "lualatex"
Set-Variable MakeGlossaries -Option ReadOnly -Value "makeglossaries"
Set-Variable MakeIndex -Option ReadOnly -Value "makeindex"
Set-Variable PdfLatex -Option ReadOnly -Value "pdflatex"
Set-Variable XeLatex -Option ReadOnly -Value "xelatex"

# Functions
function Build-Pdf {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir,
        [switch] $Quick
    )

    Build-OutputDir $OutputDir

    If (Test-Executables @($LatexMk)) {
        Build-Pdf-LatexMk $MainFile -OutputDir $OutputDir -Quick:$Quick
    } Else {
        Build-Pdf-PdfLatex $MainFile -OutputDir $OutputDir -Quick:$Quick
    }
}

function Build-Pdf-LatexMk {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir,
        [switch] $Quick
    )

    $InvExpr = $LatexMk +
        ($Xetex ? " -pdfxe" : ($Luatex ? " -pdflua" : " -pdf")) +
        (
            $VerbosePreference -eq [System.Management.Automation.ActionPreference]::SilentlyContinue ?
            "" :
            " -verbose"
        ) +
        (
            $Interactive ? "" :
            (
                $VerbosePreference -eq [System.Management.Automation.ActionPreference]::SilentlyContinue ?
                    " -interaction=batchmode" :
                    " -interaction=nonstopmode"
            )
        ) + 
        " -file-line-error -output-directory=""$OutputDir"" $MainFile"
    Invoke-String $InvExpr
}

# TODO
# - [X] Add -quick switch (just run one pass of pdflatex)
function Build-Pdf-PdfLatex {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir,
        [switch] $Quick
    )

    $PdfExe = $Xetex ? $XeLatex : ($Luatex ? $LuaLatex : $PdfLatex)
    $InvExpr = ""
    If (Test-Executables @($PdfExe, $MakeIndex, $Biber, $MakeGlossaries)) {
        Write-Output "Starting PDF first pass."
        $InvExpr = $PdfExe +
            (
                $Interactive ? "" :
                (
                    $VerbosePreference -eq [System.Management.Automation.ActionPreference]::SilentlyContinue ?
                        " -interaction=batchmode" :
                        " -interaction=nonstopmode"
                )
            ) + " -file-line-error -output-directory=""$OutputDir"" $MainFile"
        Invoke-String $InvExpr
        If (! $Quick) {
            Write-Output "Building index."
            $InvExpr = $MakeIndex + " -o $OutputDir/$MainFile.ind -t $OutputDir/$MainFile.ind.log $OutputDir/$MainFile"
            Invoke-String $InvExpr -RedirectErrorStream

            Write-Output "Building bibliography."
            $InvExpr = $Biber + " --input-directory=""$OutputDir"" --output-directory=""$OutputDir"" $MainFile"
            Invoke-String $InvExpr

            Write-Output "Building glossary."
            $InvExpr = $MakeGlossaries + " -d $OutputDir $MainFile"
            Invoke-Expression $InvExpr | Tee-Object -Append $LogFile | Write-Verbose

            Write-Output "Starting PDF second pass."
            $InvExpr = $PdfExe +
                ($Interactive ? "" : " -interaction=nonstopmode") +
                " -file-line-error -output-directory=""$OutputDir"" $MainFile"
            Invoke-String $InvExpr

            Write-Output "Starting PDF third pass."
            Invoke-String $InvExpr
        }
    }
}

function Build-OutputDi {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    If (!(Test-Path $OutputDir)) {
        New-Item $OutputDir -ItemType Directory
    }
    If (!(Test-Path $OutputDir)) {
        Write-Output ("Cannot create output directory" + $OutputDir + "; aborting.")
        Exit 1
    }
    
    Write-Verbose "Duplicate folder structure so that pdflatex can output .aux files."
    ForEach ($dir in (Get-ChildItem -Directory -Path $MainFileLocation)) {
        If ($dir.Name -ne "latex.out") {
            Write-Verbose "Duplicating folder $dir to output directory $OutputDir."
            # -Force removes errors when a directory already exists.
            Copy-Item $dir.FullName $OutputDir -Filter {PSIsContainer} -Recurse -Force
        }
    }
}

function Invoke-String {
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,
        [switch]$RedirectErrorStream
    )

    Write-Verbose ("Executing $Command" +
        ($RedirectErrorStream ? " with redirected error stream" : ""))
    If ($Interactive) {
        If ($RedirectErrorStream) {
            Invoke-Expression $Command 2>&1 | Tee-Object -Append $LogFile
        } Else {
            Invoke-Expression $Command | Tee-Object -Append $LogFile
        }
    } Else {
        If ($RedirectErrorStream) {
            Invoke-Expression $Command 2>&1 | Tee-Object -Append $LogFile | Write-Verbose
        } Else {
            Invoke-Expression $Command | Tee-Object -Append $LogFile | Write-Verbose
        }
    }
}

function Remove-OutDir {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDir
    )
    
    If (Test-Path $OutputDir) {
        Remove-Item -Recurse $OutputDir
        If (Test-Path $OutputDir) {
            Write-Error ("Could not delete directory " + $OutputDir + "; aborting.")
            Exit 254
        }
    } Else {
        Write-Verbose ($OutputDir + " does not exist.")
    }
}

function Remove-TempFiles {
    $patterns = @(
        # Patterns taken from standard TeX .gitignore file generated by GitHub
        ## Core latex/pdflatex auxiliary files:
        "*.aux",
        "*.lof",
        "*.log",
        "*.lot",
        "*.fls",
        "*.out",
        "*.toc",
        "*.fmt",
        "*.fot",
        "*.cb",
        "*.cb2",
        ".*.lb",

        ## Intermediate documents:
        "*.dvi",
        "*.xdv",
        "*-converted-to.*",

        ## Generated if empty string is given at "Please type another file name for output:"
        ".pdf",

        ## Bibliography auxiliary files (bibtex/biblatex/biber):
        "*.bbl",
        "*.bcf",
        "*.blg",
        "*-blx.aux",
        "*-blx.bib",
        "*.run.xml",

        ## Build tool auxiliary files:
        "*.fdb_latexmk",
        "*.synctex",
        "*.synctex(busy)",
        "*.synctex.gz",
        "*.synctex.gz(busy)",
        "*.pdfsync",

        ## Auxiliary and intermediate files from other packages:
        # algorithms
        "*.alg",
        "*.loa",

        # achemso
        "acs-*.bib",

        # amsthm
        "*.thm",

        # beamer
        "*.nav",
        "*.pre",
        "*.snm",
        "*.vrb",

        # changes
        "*.soc",

        # comment
        "*.cut",

        # cprotect
        "*.cpt",

        # elsarticle (documentclass of Elsevier journals)
        "*.spl",

        # endnotes
        "*.ent",

        # fixme
        "*.lox",

        # feynmf/feynmp
        "*.mf",
        "*.mp",
        "*.t[1-9]",
        "*.t[1-9][0-9]",
        "*.tfm",

        #(r)(e)ledmac/(r)(e)ledpar
        "*.end",
        "*.?end",
        "*.[1-9]",
        "*.[1-9][0-9]",
        "*.[1-9][0-9][0-9]",
        "*.[1-9]R",
        "*.[1-9][0-9]R",
        "*.[1-9][0-9][0-9]R",
        "*.eledsec[1-9]",
        "*.eledsec[1-9]R",
        "*.eledsec[1-9][0-9]",
        "*.eledsec[1-9][0-9]R",
        "*.eledsec[1-9][0-9][0-9]",
        "*.eledsec[1-9][0-9][0-9]R",

        # glossaries
        "*.acn",
        "*.acr",
        "*.glg",
        "*.glo",
        "*.gls",
        "*.glsdefs",
        "*.lzo",
        "*.lzs",

        # uncomment this for glossaries-extra (will ignore makeindex's style files!)
        # "*.ist",

        # gnuplottex
        "*-gnuplottex-*",

        # gregoriotex
        "*.gaux",
        "*.gtex",

        # htlatex
        "*.4ct",
        "*.4tc",
        "*.idv",
        "*.lg",
        "*.trc",
        "*.xref",

        # hyperref
        "*.brf",

        # knitr
        "*-concordance.tex",
        # TODO Comment the next line if you want to keep your tikz graphics files
        "*.tikz",
        "*-tikzDictionary",

        # listings
        "*.lol",

        # luatexja-ruby
        "*.ltjruby",

        # makeidx
        "*.idx",
        "*.ilg",
        "*.ind",

        # minitoc
        "*.maf",
        "*.mlf",
        "*.mlt",
        "*.mtc[0-9]*",
        "*.slf[0-9]*",
        "*.slt[0-9]*",
        "*.stc[0-9]*",

        # minted
        "_minted*",
        "*.pyg",

        # morewrites
        "*.mw",

        # nomencl
        "*.nlg",
        "*.nlo",
        "*.nls",

        # pax
        "*.pax",

        # pdfpcnotes
        "*.pdfpc",

        # sagetex
        "*.sagetex.sage",
        "*.sagetex.py",
        "*.sagetex.scmd",

        # scrwfile
        "*.wrt",

        # sympy
        "*.sout",
        "*.sympy",
        "sympy-plots-for-*.tex/",

        # pdfcomment
        "*.upa",
        "*.upb",

        # pythontex
        "*.pytxcode",
        "pythontex-files-*/",

        # tcolorbox
        "*.listing",

        # thmtools
        "*.loe",

        # TikZ & PGF
        "*.dpth",
        "*.md5",
        "*.auxlock",

        # todonotes
        "*.tdo",

        # vhistory
        "*.hst",
        "*.ver",

        # easy-todo
        "*.lod",

        # xcolor
        "*.xcp",

        # xmpincl
        "*.xmpi",

        # xindy
        "*.xdy",

        # xypic precompiled matrices and outlines
        "*.xyc",
        "*.xyd",

        # endfloat
        "*.ttt",
        "*.fff",

        # Latexian
        "TSWLatexianTemp*",

        ## Editors:
        # WinEdt
        "*.bak",
        "*.sav",

        # Texpad
        ".texpadtmp",

        # LyX
        "*.lyx~",

        # Kile
        "*.backup",

        # gummi
        ".*.swp",

        # KBibTeX
        "*~[0-9]*",

        # TeXnicCenter
        "*.tps",

        # auto folder when using emacs and auctex
        "./auto/*",
        "*.el",

        # expex forward references with \gathertags
        "*-tags.tex",

        # standalone packages
        "*.sta",

        # Makeindex log files
        "*.lpz"
    )

    ForEach ($p In $patterns) {
        Write-Verbose "Deleting $p."
        Get-ChildItem * -Include $p -Recurse | Remove-Item
    }

    # Remove HTML files at project root
    $patterns = @("*.css", "*.html", "*.out.ps", "*.tmp", "*.svg")
    ForEach ($p In $patterns) {
        Write-Verbose "Deleting $p (project root only)."
        Get-ChildItem * -Include $p | Remove-Item
    }
}

function Test-Executables {
    param (
        [string[]]$Executables
    )

    $retval = $true

    foreach ($exe in $Executables) {
        $test = Get-Command $exe
        If ($null -eq $test) {
            Write-Error ("Cannot find a required executable $exe.")
            $retval = $false
        }
    }

    return $retval
}

# Main

# Other global variables
$Ext = [System.IO.Path]::GetExtension($MainFile)
If ([string]::IsNullOrWhiteSpace($Ext)) {
    $Ext = ".tex"
}
$LogFile = $OutDir + "\build.log"
$MainFileFullPath = Resolve-Path ($MainFile + $Ext)
$MainFileLocation = Split-Path $MainFileFullPath
$MainFile = [System.IO.Path]::GetFileNameWithoutExtension($MainFileFullPath)
$OutDir = "./latex.out"
$StartLocation = Get-Location

Write-Verbose "Main file is ${MainFileFullPath}."
Write-Verbose "Main file located at ${MainFileLocation}."
Write-Verbose "Considering main file to be ${MainFile}."

Set-Location $MainFileLocation

If ($All) {
    Write-Verbose "Activating all build functions."
    $Figures = $true
    $Pdf = $true
    $Epub = $true
    $Html = $true
}

If ($Clean) {
    Remove-TempFiles
}

If ($Pdf) {
    Build-Pdf -OutputDir ($OutDir + "/pdf") $MainFile -Quick:$Quick
}

Set-Location $StartLocation

<#
.SYNOPSIS

Build multiple LaTeX targets from a single source.

.DESCRIPTION

Build multiple LaTeX targets from a single source.
Output files are located in the latex.out directory.

.PARAMETER MainFile
Main TeX file to compile.

.PARAMETER All
Same as --figures --pdf --print --epub --html --markdown.

.PARAMETER Clean
Runs the cleanup routines before building.

.PARAMETER Epub
Builds the ePub files.

.PARAMETER Figures
Builds any figure files located in the working directory.

.PARAMETER Html
Builds the web site files. Synonymous with -Web.

.PARAMETER Interactive
Runs the LaTeX executables in interactive mode.

.PARAMETER Luatex
Use LuaTeX engine instead of LaTeX engine.

.PARAMETER Markdown
Builds Markdown files.

.PARAMETER Pandoc
Use Pandoc when creating web sites and e-books.

.PARAMETER Pdf
Builds the PDF file (meant for online viewing).

.PARAMETER Print
Builds the print-ready PDF file.

.PARAMETER PostClean
Runs the cleanup routines after building.

.PARAMETER Quick
Runs just one pass of pdflatex, et al.

.PARAMETER Xetex
Use XeTeX engine instead of LaTeX engine.

.PARAMETER Web
Builds the web site files. Synonymous with -Html.

.NOTES
  Version: 0.0.6
  Author:  Alex Kulcsar
  Date:    18 February 2023
#>

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
    [switch]$Pandoc,
    [switch]$Pdf,
    [switch]$PostClean,
    [switch]$Epub,
    [switch]$Html,
    [switch]$Luatex,
    [switch]$Markdown,
    [switch]$Quick,
    [switch]$Xetex,
    [switch]$Web
)

# Executables
# Modify (e.g., supply full path) as needed for executables not located in your path.
Set-Variable Biber -Option ReadOnly -Value "biber"
Set-Variable LatexMk -Option ReadOnly -Value "latexmk"
Set-Variable LuaLatex -Option ReadOnly -Value "lualatex"
Set-Variable Make4ht -Option ReadOnly -Value "make4ht"
Set-Variable MakeGlossaries -Option ReadOnly -Value "makeglossaries"
Set-Variable MakeIndex -Option ReadOnly -Value "makeindex"
Set-Variable PandocExe -Option ReadOnly -Value "pandoc"
Set-Variable PdfLatex -Option ReadOnly -Value "pdflatex"
Set-Variable Tex4Ebook -Option ReadOnly -Value "tex4ebook"
Set-Variable Tidy -Option Readonly -Value "tidy"
Set-Variable XeLatex -Option ReadOnly -Value "xelatex"

# Functions
function Build-Ebook {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    Build-OutputDir $OutputDir -NoRecurse
    If ($Pandoc) {
        Build-Ebook-Pandoc $MainFile -OutputDir $OutputDir
    } Else {
        Build-Ebook-Tex4Ebook $MainFile -OutputDir $OutputDir
    }
}

function Build-Ebook-Pandoc {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    If (Test-Executables @($PandocExe)) {
        $ConfigFile = "pandoc-epub.yaml"
        $InvExpr = "pandoc --from=latex --output=""" + $OutputDir + "/" + $MainFile + ".epub"" " + (
            (Test-Path $ConfigFile) ? ("--defaults=" + $ConfigFile + " ")
            : "--mathml --to=epub3 "
        ) + $MainFile + ".tex"

        Write-Output "Building e-book."
        Invoke-String $InvExpr
    }
}

function Build-Ebook-Tex4Ebook {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    If (Test-Executables @($Tex4Ebook)) {
        $ConfigFile = "tex4ebookrc"
        $InvExpr = $Tex4Ebook + " --format epub3" + (
            (Test-Path $ConfigFile) ? " --build-file " + $ConfigFile : ""
        ) + " " + $MainFile

        Write-Output "Building e-book."
        Invoke-String $InvExpr

        $EpubFile = $MainFile + ".epub"
        If (Test-Path $EpubFile) {
            Write-Verbose "Moving ePub file to output directory."
            Move-Item $EpubFile (Join-Path $OutputDir $EpubFile) -Force
        }
    }
}

function Build-Markdown {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    Build-OutputDir $OutputDir -NoRecurse
    If (Test-Executables @($PandocExe)) {
        $ConfigFile = "pandoc-md.yaml"
        $InvExpr = "pandoc --from=latex --output=""" + $OutputDir + "/" + $MainFile + ".md"" " + (
            (Test-Path $ConfigFile) ? ("--defaults=" + $ConfigFile + " ")
            : "--to=markdown "
        ) + $MainFile + ".tex"

        Write-Output "Building markdown files."
        Invoke-String $InvExpr
    }
}

function Build-Pdf {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    Build-OutputDir $OutputDir

    If ((Test-Executables @($LatexMk)) -and (!($Quick))) {
        Build-Pdf-LatexMk $MainFile -OutputDir $OutputDir
    } Else {
        Build-Pdf-PdfLatex $MainFile -OutputDir $OutputDir
    }
}

function Build-Pdf-LatexMk {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
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

function Build-Pdf-PdfLatex {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
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

function Build-OutputDir {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir,
        [switch] $NoRecurse
    )

    If (!(Test-Path $OutputDir)) {
        New-Item $OutputDir -ItemType Directory
    }
    If (!(Test-Path $OutputDir)) {
        Write-Output ("Cannot create output directory" + $OutputDir + "; aborting.")
        Exit 1
    }
    
    If (!($NoRecurse)) {
        Write-Verbose "Duplicate folder structure so that pdflatex can output .aux files."
        ForEach ($dir in (Get-ChildItem -Directory -Path $MainFileLocation)) {
            If ($dir.Name -ne "latex.out") {
                Write-Verbose "Duplicating folder $dir to output directory $OutputDir."
                # -Force removes errors when a directory already exists.
                Copy-Item $dir.FullName $OutputDir -Filter {PSIsContainer} -Recurse -Force
            }
        }
    }
}

function Build-Web {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    Build-OutputDir $OutputDir -NoRecurse
    If ($Pandoc) {
        Build-Web-Pandoc $MainFile -OutputDir $OutputDir
    } Else {
        Build-Web-Make4ht $MainFile -OutputDir $OutputDir
    }
}

function Build-Web-Make4ht {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    If (Test-Executables @($Make4ht)) {
        $ConfigFile = "make4htrc"
        $TidyFilter = (Test-Executables @($Tidy)) ? "+tidy " : " "
        $InvExpr = $Make4ht + " --output-dir """ + $OutputDir + """ --utf8" + (
            (Test-Path $ConfigFile) ? " --build-file " + $ConfigFile + " --format html5 " + $MainFile
            : " --format html5+common_domfilters" + $TidyFilter + $MainFile +  """mathjax,2"""
        )

        Write-Output "Building web files."
        Invoke-String $InvExpr
    }
}

function Build-Web-Pandoc {
    param (
        [Parameter(Mandatory,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $MainFile,
    
        [Parameter(Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputDir
    )

    If (Test-Executables @($PandocExe)) {
        $ConfigFile = "pandoc-web.yaml"
        $InvExpr = "pandoc --from=latex --to=html5 --output=""" + $OutputDir + "/" + $MainFile + ".html"" " + (
            (Test-Path $ConfigFile) ? ("--defaults=" + $ConfigFile + " ")
            : "--standalone --mathjax "
        ) + $MainFile + ".tex"

        Write-Output "Building web files."
        Invoke-String $InvExpr
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
        "*.ist",

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

    # Remove HTML and eBook files at project root
    $patterns = @("*.css", "*.epub", "*.epub3,", "*.mobi", "*.html",
        "*.ncx", "content.opf", "*.out.ps", "*.png", "*.tmp", "*.svg",
        "*.xhtml")
    ForEach ($p In $patterns) {
        Write-Verbose "Deleting $p (project root only)."
        Get-ChildItem * -Include $p | Remove-Item
    }

    # Remove eBook folders
    $patterns = @("*-epub3", "*-epub", "*-mobi")
    ForEach ($p in $patterns) {
        Write-Verbose "Deleting $p folders (project root only)."
        Get-ChildItem * -Filter $p | Remove-Item -Recurse -Force
    }
}

function Test-Alternates() {
    param (
        [string[]]$Suffixes
    )

    $toReturn = $RealMain
    foreach ($suffix in $Suffixes) {
        $testfile = $RealMain + $suffix
        If (Test-Path $testfile) {
            $toReturn = Split-Path -LeafBase $testfile
            break
        }
    }

    return $toReturn
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

function Write-Variables() {
    Write-Verbose "Current state:"
    Write-Verbose "MainFileFullPath = $MainFileFullPath"
    Write-Verbose "MainFileLocation = $MainFileLocation"
    Write-Verbose "MainFile = $MainFile"
    Write-Verbose "Ext = $Ext"
    Write-Verbose "OutDir = $OutDir"
    Write-Verbose "LogFile = $LogFile"
    Write-Verbose "RealMain = $RealMain"
    Write-Verbose ("Main file exists? " + (Test-Path ($MainFile + $Ext)))
    Write-Verbose ""
}

# Main
# Other global variables
$Ext = [System.IO.Path]::GetExtension($MainFile)
If ([string]::IsNullOrWhiteSpace($Ext)) {
    $Ext = ".tex"
}
$OutDir = "./latex.out"
$LogFile = $OutDir + "\build.log"
$MainFileLocation = Split-Path $MainFile
If ([string]::IsNullOrWhiteSpace($MainFileLocation)) {
    $MainFileLocation = (Resolve-Path ".")
} Else {
    $MainFileLocation = (Resolve-Path $MainFileLocation)
}
$MainFile = Split-Path -LeafBase $MainFile
$MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
$RealMain = $MainFile
$StartLocation = Get-Location


If ($All) {
    Write-Verbose "Activating all build functions."
    $Figures = $true
    $Pdf = $true
    $Print = $true
    $Epub = $true
    $Web = $true
    $Markdown = $true
}

If ($Html) {
    $Web = $true
}

# Last test before starting
If (-Not(Test-Path $MainFileLocation -PathType Container)) {
    Write-Error "Main file location '$MainFileLocation' does not exist; aborting."
    Exit 1
}

Write-Variables
Set-Location $MainFileLocation

If ($Clean) {
    Remove-TempFiles
}

If ($Pdf) {
    Write-Output "Building PDF for online viewing."
    $MainFile = Test-Alternates @("-pdf.tex")
    $MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
    Write-Variables
    If (Test-Path $MainFileFullPath -PathType Leaf) {
        Build-Pdf -OutputDir ($OutDir + "/pdf") $MainFile
    } Else {
        Write-Error "Unable to find main file '$MainFileFullPath'; skipping build."
    }
}

If ($Print) {
    Write-Output "Building print-ready PDF."
    $MainFile = Test-Alternates @("-print.tex", "-pdf.tex")
    $MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
    Write-Variables
    If (Test-Path $MainFileFullPath -PathType Leaf) {
        Build-Pdf -OutputDir ($OutDir + "/print") $MainFile
    } Else {
        Write-Error "Unable to find main file '$MainFileFullPath'; skipping build."
    }
}

If ($Web) {
    Write-Output "Building web site."
    $MainFile = Test-Alternates @("-web.tex")
    $MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
    Write-Variables
    If (Test-Path $MainFileFullPath -PathType Leaf) {
        Build-Web -OutputDir ($OutDir + "/html") $MainFile
    } Else {
        Write-Error "Unable to find main file '$MainFileFullPath'; skipping build."
    }
}

If ($Epub) {
    Write-Output "Building e-book."
    $MainFile = Test-Alternates @("-epub.tex", "-web.tex")
    $MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
    Write-Variables
    If (Test-Path $MainFileFullPath -PathType Leaf) {
        Build-Ebook -OutputDir ($OutDir + "/epub") $MainFile
    } Else {
        Write-Error "Unable to find main file '$MainFileFullPath'; skipping build."
    }
}

If ($Markdown) {
    Write-Output "Building Markdown files."
    $MainFile = Test-Alternates @("-md.tex", "-web.tex")
    $MainFileFullPath = Join-Path $MainFileLocation ($MainFile + $Ext)
    Write-Variables
    If (Test-Path $MainFileFullPath -PathType Leaf) {
        Build-Markdown -OutputDir ($OutDir + "/md") $MainFile
    } Else {
        Write-Error "Unable to find main file '$MainFileFullPath'; skipping build."
    }
}

If ($PostClean) {
    Remove-TempFiles
}

Set-Location $StartLocation

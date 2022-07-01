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

.PARAMETER Pdf
Builds the PDF file.

.PARAMETER Quick
Runs just one pass of pdflatex, et al.

.PARAMETER Xetex
Use XeLaTeX engine instead of PdfLaTex engine for PDF output.
#>

######################################################################
# 2022-Jun-20 Initial version
# 2022-Jun-26 Repackage as a single script with functions
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
# - [ ] Add interactive mode (automatically activate verbose mode).
# - [X] Support XeLaTeX.
# - [X] Remove Start-Process; revert to direct calls.
# - [X] Move executable names into variables to allow for alternate
#       specification (e.g. executable not in path).
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
    [switch]$Pdf,
    [switch]$Epub,
    [switch]$Html,
    [switch]$Quick,
    [switch]$Xetex
)

# Executables
# Modify (e.g. supply full path) as needed for executables not located in your path.
<#
readonly biber=$(which biber)
readonly makeindex=$(which makeindex)
readonly makeglossaries=$(which makeglossaries)
readonly pdflatex=$(which pdflatex)
readonly tree=$(which tree)
readonly xelatex=$(which xelatex)
#>
Set-Variable Biber -Option ReadOnly -Value "biber"
Set-Variable MakeGlossaries -Option ReadOnly -Value "makeglossaries"
Set-Variable MakeIndex -Option ReadOnly -Value "makeindex"
Set-Variable PdfLatex -Option ReadOnly -Value "pdflatex"
Set-Variable XeLatex -Option ReadOnly -Value "xelatex"

# Functions

# TODO
# - [X] Add -quick switch (just run one pass of pdflatex)
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

    $PdfExe = $Xetex ? $XeLatex : $PdfLatex
    If (Test-Executables @($PdfExe, $MakeIndex, $Biber, $MakeGlossaries)) {
        Write-Output "Starting PDF first pass."
        If ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
            Invoke-Expression ($PdfExe + " -interaction=nonstopmode -file-line-error -output-directory $OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
        } Else {
            Invoke-Expression ($PdfExe + " -interaction=batchmode -file-line-error -output-directory $OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
        }
        If (! $Quick) {
            Write-Output "Building index."
            Invoke-Expression ($MakeIndex + " -o $OutputDir/$MainFile.ind -t $OutputDir/$MainFile.ind.log $OutputDir/$MainFile") 2>&1 | Tee-Object -Append $LogFile | Write-Verbose
            Write-Output "Building bibliography."
            Invoke-Expression ($Biber + " --input-directory=$OutputDir --output-directory=$OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
            Write-Output "Building glossary."
            Invoke-Expression ($MakeGlossaries + " -d $OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
            Write-Output "Starting PDF second pass."
            Invoke-Expression ($PdfExe + " -interaction=nonstopmode -file-line-error -output-directory $OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
            Write-Output "Starting PDF third pass."
            Invoke-Expression ($PdfExe + " -interaction=nonstopmode -file-line-error -output-directory $OutputDir $MainFile") | Tee-Object -Append $LogFile | Write-Verbose
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
$MainFileFullPath = Resolve-Path ($MainFile + $Ext)
$MainFileLocation = Split-Path $MainFileFullPath
$MainFile = [System.IO.Path]::GetFileNameWithoutExtension($MainFileFullPath)
$OutDir = "./latex.out"
$LogFile = $OutDir + "\build.log"

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
    Remove-OutDir $OutDir
}

If ($Pdf) {
    Build-Pdf -OutputDir ($OutDir + "/pdf") $MainFile -Quick:$Quick
}


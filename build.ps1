# 2022-Jun-20 Initial version
# 2022-Jun-26 Repackage as a single script with functions

# TODO
# - [X] Add -clean -figures -pdf -epub -html switches.
# - [X] Do not automatically clean the output directory.
# - [X] Rename to `build.ps1`.
# - [X] Remove bin directory; incorporate as functions instead.

param (
    [Parameter(Mandatory,Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$MainFile,
    [string]$ContentDir,
    [switch]$All,
    [switch]$Clean,
    [switch]$Figures,
    [switch]$Pdf,
    [switch]$Epub,
    [switch]$Html,
    [switch]$Quick
)

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
        [string] $ContentDir,
        [switch] $Quick
    )
    
    If (!(Test-Path $OutputDir)) {
        New-Item $OutputDir -ItemType Directory
    }
    If (!(Test-Path $OutputDir)) {
        Write-Output ("Cannot create output directory" + $OutputDir + "; aborting.")
        Exit 1
    }
    
    Write-Verbose "Duplicate content folder structure so that pdflatex can output .aux files."
    If (!([string]::IsNullOrWhiteSpace($ContentDir))) {
        If (Test-Path $ContentDir) {
            Copy-Item $ContentDir $OutputDir -Filter {PSIsContainer} -Recurse -Force
        } Else {
            Write-Error ("Content directory " + $ContentDir + " does not exist; aborting.")
            Exit 1
        }
    }
    
    pdflatex --output-dir $OutputDir $MainFile
    If (! $Quick) {
        makeindex -o $OutputDir/$MainFile.ind  -t $OutputDir/$MainFile.ind.log $OutputDir/$MainFile
        biber --input-directory=$OutputDir --output-directory=$OutputDir $MainFile
        makeglossaries -d $OutputDir $MainFile
        pdflatex --output-dir $OutputDir $MainFile
        pdflatex --output-dir $OutputDir $MainFile
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
            exit 254
        }
    } Else {
        Write-Verbose ($OutputDir + " does not exist.")
    }
}

# Main

$Ext = [System.IO.Path]::GetExtension($MainFile)
If ([string]::IsNullOrWhiteSpace($Ext)) {
    $Ext = ".tex"
} Else {
    $MainFile = [System.IO.Path]::GetFileNameWithoutExtension($MainFile)
}

$OutDir = "./latex.out"

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
    If ([string]::IsNullOrWhiteSpace($ContentDir)) {
        Build-Pdf -OutputDir ($OutDir + "/pdf") $MainFile -Quick:$Quick
    } Else {
        Build-Pdf -OutputDir ($OutDir + "/pdf") -ContentDir $ContentDir $MainFile -Quick:$Quick
    }
}


param (
    [Parameter(Mandatory,Position=0)]
    [ValidateNotNullOrEmpty()]
    $MainFile = "main",

    [Parameter(Mandatory,Position=1)]
    [ValidateNotNullOrEmpty()]
    $OutputDir,

    $ContentDir
)

If (!(Test-Path $OutputDir)) {
    New-Item $OutputDir -ItemType Directory
}
If (!(Test-Path $OutputDir)) {
    Write-Output ("Cannot create output directory" + $OutputDir + "; aborting.")
    exit 1
}

# Duplicate content folder structure so that pdflatex can output .aux files
If (!([string]::IsNullOrWhiteSpace($ContentDir))) {
    If (Test-Path $ContentDir) {
        Copy-Item $ContentDir $OutputDir -Filter {PSIsContainer} -Recurse
    } Else {
        Write-Error ("Content directory " + $ContentDir + " does not exist; aborting.")
        exit 1
    }
}

pdflatex --output-dir $OutputDir $MainFile
makeindex -o $OutputDir/$MainFile.ind  -t $OutputDir/$MainFile.ind.log $OutputDir/$MainFile
biber --input-directory=$OutputDir --output-directory=$OutputDir $MainFile
makeglossaries -d $OutputDir $MainFile
pdflatex --output-dir $OutputDir $MainFile
pdflatex --output-dir $OutputDir $MainFile

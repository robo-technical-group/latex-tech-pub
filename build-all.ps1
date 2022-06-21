param (
    [Parameter(Mandatory,Position=0)]
    [ValidateNotNullOrEmpty()]
    $MainFile = "main",

    $ContentDir
)

$Ext = [System.IO.Path]::GetExtension($MainFile)
If ([string]::IsNullOrWhiteSpace($Ext)) {
    $Ext = ".tex"
} Else {
    $MainFile = [System.IO.Path]::GetFileNameWithoutExtension($MainFile)
}
$OutDir = "./latex.out"
.\bin\clean.ps1 $OutDir
If ([string]::IsNullOrWhiteSpace($ContentDir)) {
    .\bin\build-pdf.ps1 -outputdir ($OutDir + "/pdf") $MainFile
} else {
    .\bin\build-pdf.ps1 -outputdir ($OutDir + "/pdf") -contentdir $ContentDir $MainFile
}

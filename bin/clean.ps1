param (
    [Parameter(Mandatory,Position=0)]
    [ValidateNotNullOrEmpty()]
    $OutputDir = "latex.out"
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

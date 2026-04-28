# In TeamCity, run this script from the same working directory as your build.
# This assumes your .NET Pack step outputted to a folder named "artifacts"
$SourcePath = ".\artifacts"
$PermPath = "\\your-server\shared-drive\teamnuget"

# 1. Dynamically grab the newly built package(s) from the local agent
$Packages = Get-ChildItem -Path $SourcePath -Filter *.nupkg

if ($Packages.Count -eq 0) {
    Write-Error "No .nupkg files found in $SourcePath. Did the pack step fail?"
    exit 1
}

foreach ($Pkg in $Packages) {
    Write-Host "Validating $($Pkg.Name)..."
    
    # 2. Verification (Check if file is structurally sound by unzipping its manifest)
    $IsValid = Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::OpenRead($Pkg.FullName).Entries | Where-Object Name -eq "$($Pkg.BaseName).nuspec"
    
    if (-not $IsValid) {
        Write-Error "Package $($Pkg.Name) failed validation. It may be corrupted."
        exit 1
    }
    Write-Host "Validation passed."
}

# 3. Robocopy Promotion
Write-Host "Starting Robocopy to $PermPath..."

# /MOV moves files and deletes from source
# /R:5 /W:5 retry logic
# /NP prevents flooding the TeamCity log with percentage trackers
robocopy $SourcePath $PermPath *.nupkg /MOV /R:5 /W:5 /NP

# 4. Handle Robocopy Exit Codes
# Robocopy is notorious for returning non-zero exit codes even on success.
# Anything below 8 means success (1 means files copied, 0 means no change, 3 means some copied/some extra).
$roboExitCode = $LASTEXITCODE

if ($roboExitCode -ge 8) {
    Write-Error "Robocopy failed with exit code $roboExitCode."
    exit 1
} else {
    Write-Host "Promotion complete! Robocopy exited with code $roboExitCode."
    exit 0
}
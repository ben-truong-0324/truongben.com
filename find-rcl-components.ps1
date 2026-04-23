param (
    [string]$SearchPath = ".",
    [string]$ComponentName = "rcl-card",
    [string]$ExportPath = "RclComponentReport.csv"
)

Write-Host "Scanning for '$ComponentName' in $SearchPath..." -ForegroundColor Cyan

# Define the regex pattern to catch both HTML tags and Markdown custom containers
# \b ensures we match 'rcl-card' and not 'rcl-card-extended'
$pattern = "(<${ComponentName}\b)|(:::${ComponentName}\b)"

# Gather all views and markdown files
$files = Get-ChildItem -Path $SearchPath -Include *.cshtml, *.md -Recurse -File

$results = @()

foreach ($file in $files) {
    # Select-String is highly optimized for this kind of file reading
    $matches = Select-String -Path $file.FullName -Pattern $pattern -CaseSensitive:$false
    
    foreach ($match in $matches) {
        $results += [PSCustomObject]@{
            Component  = $ComponentName
            FileType   = if ($file.Extension -eq '.md') { 'Markdown' } else { 'Razor View' }
            FileName   = $file.Name
            RelativePath = $file.FullName.Replace((Resolve-Path $SearchPath).Path + "\", "")
            LineNumber = $match.LineNumber
            LineText   = $match.Line.Trim()
        }
    }
}

if ($results.Count -gt 0) {
    # Output to the console for a quick visual check
    $results | Format-Table FileType, RelativePath, LineNumber -AutoSize
    
    # Export to a CSV for your manual records
    $results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Found $($results.Count) instances. Report saved to $ExportPath" -ForegroundColor Green
} else {
    Write-Host "No instances of '$ComponentName' found." -ForegroundColor Yellow
}


.\Find-RclComponents.ps1 -ComponentName "rcl-card"

.\Find-RclComponents.ps1 -SearchPath ".\Pages" -ComponentName "rcl-button" -ExportPath "button-inventory.csv"
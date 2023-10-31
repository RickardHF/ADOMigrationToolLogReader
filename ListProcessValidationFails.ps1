[CmdletBinding()]
param (
    [Parameter()]
    $FilePath,
    [Parameter()]
    $collectionURL = 'http://localhost:8080/tfs/DefaultCollection',
    [Parameter()]
    $DryRun = $true
)

$ErrorPattern = "Validation failed for project "
$Pattern = "Validation failed for project (.+?) with "

$Errors = Get-Content $FilePath | Select-String -Pattern $ErrorPattern

$Projects = @()

foreach ($Error in $Errors) {
    $Project = $null

    if ($Error -match $Pattern) {
        $Project = $Matches[1]
    }

    $Projects += $Project
}

Write-Host "Found $($Projects.Count) projects with validation errors"

foreach ($Project in $Projects) {
    Write-Host "Project '$Project' has validation errors"
}
[CmdletBinding()]
param (
    [Parameter()]
    $FilePath,
    [Parameter()]
    $OutFilePath,
    [Parameter()]
    $DryRun = $true
)

# Read CSV
$WorkItems = Import-Csv -Path $FilePath

# Get the work item types
$TeamProjects = $WorkItems | Select-Object -ExpandProperty "Team Project" -Unique

Write-Host "Found $($TeamProjects.Count) team projects"

foreach ($TeamProject in $TeamProjects) {
    Write-Host "Team project '$TeamProject'"
}

$Projects = @()

foreach ($TeamProject in $TeamProjects) {
    $Projects += [PSCustomObject]@{
        Project = $TeamProject
    }
}

$Projects | Export-Csv -Path $OutFilePath -NoTypeInformation
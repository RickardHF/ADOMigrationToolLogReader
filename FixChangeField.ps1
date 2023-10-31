[CmdletBinding()]
param (
    [Parameter()]
    $FilePath,
    [Parameter()]
    $collectionURL = 'http://localhost:8080/tfs/DefaultCollection',
    [Parameter()]
    $DryRun = $true
)

$ErrorPattern = "VS403443"
$FieldPattern = "you must rename field '([A-Za-z.]+)"
$ToPattern = "' to '([^']*)'"

$Errors = Get-Content $FilePath | Select-String -Pattern $ErrorPattern

$RenameFields = @()

foreach ($Error in $Errors) {
    $Field = $null
    $To = $null

    if ($Error -match $FieldPattern) {
        $Field = $Matches[1]
    }

    if ($Error -match $ToPattern) {
        $To = $Matches[1]
    }

    $RenameFields += [PSCustomObject]@{
        Field = $Field
        To = $To
    }
}

Write-Host "Found $($RenameFields.Count) fields to rename"

foreach ($RenameField in $RenameFields) {
    Write-Host "Renaming $($RenameField.Field) to '$($RenameField.To)'"

    if (! $DryRun) {
        witadmin changefield /collection:$collectionURL /n:$($RenameField.Field) /name:"$($RenameField.To)"
    } else {
        Write-Host "Dry run, skipping renaming"
    }
}
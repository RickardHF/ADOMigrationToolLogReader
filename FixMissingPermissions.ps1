[CmdletBinding()]
param (
    [Parameter()]
    $FilePath,
    [Parameter()]
    $collectionURL = 'http://localhost:8080/tfs/DefaultCollection',
    [Parameter()]
    $DryRun = $true
)

$GroupPattern = "Group:(\S+)"
$ScopePattern = "Scope:([A-Za-z0-9-]+)"
$PermissionPattern = "Permission:([\S]+)"
$ErrorPattern = "ISVError:100014 An expected permission is missing."

$Errors = Get-Content $FilePath | Select-String -Pattern $ErrorPattern

$MissingPermissions = @()

foreach ($Error in $Errors) {
    $Permission = $null
    $Group = $null
    $Scope = $null

    if ($Error -match $PermissionPattern) {
        $Permission = $Matches[1]
    }

    if ($Error -match $GroupPattern) {
        $Group = $Matches[1]
    }

    if ($Error -match $ScopePattern) {
        $Scope = $Matches[1]
    }

    $MissingPermissions += [PSCustomObject]@{
        Permission = $Permission
        Group = $Group
        Scope = $Scope
    }
}

Write-Host "Found $($MissingPermissions.Count) missing permissions"

foreach ($MissingPermission in $MissingPermissions) {
    Write-Host "Missing $($MissingPermission.Permission) to $($MissingPermission.Group) on $($MissingPermission.Scope)"
}

if (! $DryRun) {
    Write-Host "Granting permissions"
    
    foreach ($MissingPermission in $MissingPermissions) {
        Write-Host "Granting $($MissingPermission.Permission) to $($MissingPermission.Group) on $($MissingPermission.Scope)"
        
        $permission = $MissingPermission.Permission
        $SID = $MissingPermission.Group
        $Scope = $MissingPermission.Scope

        TFSSecurity /a+ Identity $Scope $permission sid:$SID ALLOW /collection:$collectionURL
    }
} else {
    Write-Host "Dry run, skipping granting permissions"
    Write-Host "TFSSecurity /a+ Identity $Scope $permission sid:$SID ALLOW /collection:$collectionURL"
}
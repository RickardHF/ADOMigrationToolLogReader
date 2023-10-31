[CmdletBinding()]
param (
    [Parameter()]
    $LogFilePath,
    [Parameter()]
    $configurationDatabaseName = 'Tfs_Configuration',
    [Parameter()]
    $DryRun = $true
)

$ErrorPattern = "ISVError:300005"

$Errors = Get-Content $LogFilePath | Select-String -Pattern $ErrorPattern

$EverywherePermissions = @()

$MemberSidPattern = "MemberSid:([A-Za-z.]+);([A-Za-z0-9-]+)"
$GroupSidPattern = "GroupSid:([A-Za-z0-9-]+)"
$ScopePattern = "ScopeId:([A-Za-z0-9-]+)"
$MemberIDPattern = "MemberId:([A-Za-z0-9-]+)"

foreach ($Error in $Errors) {
    $MemberType = $null
    $MemberSID = $null
    $GroupSID = $null
    $ScopeID = $null
    $MemberID = $null

    if ($Error -match $GroupSidPattern) {
        $GroupSID = $Matches[1]
    }

    if ($Error -match $ScopePattern) {
        $ScopeID = $Matches[1]
    }

    if ($Error -match $MemberIDPattern) {
        $MemberID = $Matches[1]
    } elseif ($Error -match $MemberSidPattern) {
        $MemberType = $Matches[1]
        $MemberSID = $Matches[2]
    }

    $EverywherePermissions += [PSCustomObject]@{
        MemberType = $MemberType
        MemberSID = $MemberSID
        GroupSID = $GroupSID
        ScopeID = $ScopeID
        MemberID = $MemberID
    }
}

foreach ($EverywherePermission in $EverywherePermissions) {

    $Query = ""

    if ($EverywherePermission.MemberID -eq $null) {
        $Query = @"
USE [$configurationDatabaseName]

DECLARE @MemberSID varchar(256) = '$($EverywherePermission.MemberSID)'
DECLARE @GroupSID varchar(256) = '$($EverywherePermission.GroupSID)'
DECLARE @MemberType varchar(256) = '$($EverywherePermission.MemberType)'
DECLARE @ScopeID uniqueidentifier = '$($EverywherePermission.ScopeID)'

DECLARE @MemberID uniqueidentifier
SET @MemberID = (SELECT Id from dbo.tbl_Identity WHERE Sid = @MemberSID)

DECLARE @p6 dbo.typ_GroupMembershipTable

INSERT INTO @p6 VALUES (@GroupSID, @MemberType, @MemberID, 0)

EXEC prc_UpdateGroupMembership @partitionId=1,@scopeId=@ScopeID,@idempotent=1,@incremental=1,@insertInactiveUpdates=0,@updates=@p6,@eventAuthor='9EE20697-5343-43FC-8FC5-3D5D455D21C5'
"@
    } else {
        $Query = @"
USE [$configurationDatabaseName]

DECLARE @p6 dbo.typ_GroupMembershipTable

INSERT INTO @p6 VALUES ('$($EverywherePermission.GroupSID)', 'Microsoft.TeamFoundation.Identity', '$($EverywherePermission.MemberID)', 0)
EXEC prc_UpdateGroupMembership @partitionId=1,@scopeId='$($EverywherePermissions.ScopeID)',@idempotent=1,@incremental=1,@insertInactiveUpdates=0,@updates=@p6,@eventAuthor='9EE20697-5343-43FC-8FC5-3D5D455D21C5',@updateGroupAudit=0
"@
    }

    if ($DryRun) {
        Write-Host "Query: $Query"
    } else {
        Write-Host "Executing query"
    }

}

#!/usr/bin/env pwsh
Write-Host @"
##############################################################################################################
#
# Microsoft Azure
# Training account creation
#
##############################################################################################################
"@

$region = "emea"
$userEmail = "jvh@jvh.be"
$displayName = "Joeri"


if (Get-Module -ListAvailable -Name "Microsoft.Graph") {
    Write-Host "Microsoft.Graph module installed."
} 
else {
    Write-Host "Microsoft.Graph module not installed."
    Install-Module -Name Microsoft.Graph
    Import-Module Microsoft.Graph
}

$clientId = "***REMOVED***"
$clientSecret = "***REMOVED***"
$tenantId = "***REMOVED***"

$securePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object PSCredential -ArgumentList $clientId, $securePassword

#Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential 

Connect-MgGraph -TenantId $tenantId -clientId $clientId -Scopes Group.ReadWrite.All, GroupMember.Read.All, User.Read.All, Files.Read.All 

$groupName = "${region}-trainers"
$groupExists = Get-MgGroup -Filter "displayName eq '$groupName'"

if ($null -eq $groupExists) {
    $group = New-MgGroup -DisplayName $groupName -MailEnabled $false -SecurityEnabled $true -MailNickname $groupName -Description "Custom Group"
}

$invitation = New-MgInvitation -InvitedUserDisplayName $displayName -InvitedUserEmailAddress $userEmail -InviteRedirectUrl "https://myapplications.microsoft.com"

# Role: Application Administrator
$roleId = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
Add-MgDirectoryRoleMember -Id $roleId -RefObjectId $invitation.InvitedUser.Id

Add-MgGroupMember -GroupId $group.Id -Members @($invitation.InvitedUser.Id)


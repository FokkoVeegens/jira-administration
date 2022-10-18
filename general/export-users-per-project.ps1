# Will export to a CSV file
# The CSV file will contain information on project, role, group and user

$ErrorActionPreference = 'Stop'
$pat = Get-Content -Path ".\pat.txt"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pat))
$basicAuthValue = "Basic $encodedCreds"
$baseurl = "https://YOUR_JIRA_SERVER/jira/rest/api/latest"
$Headers = @{ 
    "Authorization" = $basicAuthValue;
}
$exportfile = "C:\temp\usersperproject.csv"

Class Entry {
    [string]$Username
    [string]$UserDisplayName
    [string]$ProjectKey
    [string]$ProjectName
    [string]$Role
    [string]$Group
}

function Get-JsonOutput($path)
{
    return (Invoke-Webrequest -Uri "$baseurl/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json
} 

function Get-Projects()
{
    return Get-JsonOutput -path "project?expand=description,lead,url,projectKeys"
}

function Get-ProjectRoles($projectKey)
{
    return Get-JsonOutput -path "project/$projectKey/role"
}

function Get-RoleMembers($projectKey, [string]$roleUri)
{
    $roleId = $roleUri.Substring($roleUri.LastIndexOf("/") + 1)
    return Get-JsonOutput -path "project/$projectKey/role/$roleId"
}

function Get-GroupMembers($groupName)
{
    $groupMembers = $null
    try {
        $groupName = [System.Web.HttpUtility]::UrlEncode($groupName)
        $groupMembers = Get-JsonOutput -path "group/member?groupname=$groupName"
    }
    catch {
        $errormessage = ($_.ErrorDetails.Message | ConvertFrom-Json).errorMessages[0]
        Write-Host "`tWARNING: $errormessage" -ForegroundColor Yellow
    }
    return $groupMembers
}

$projects = Get-Projects | Where-Object { $_.name -notlike "Projekt ist  geschlossen !!!*" }
$entries = New-Object System.Collections.ArrayList
foreach ($project in $projects) {
    Write-Host "Processing project '$($project.name)'"
    $rolesoutput = Get-ProjectRoles -projectKey $project.key
    $roles = $rolesoutput | Get-Member -MemberType NoteProperty
    foreach ($role in $roles) {
        Write-Host "`tRole: $($role.name)"
        $members = Get-RoleMembers -projectKey $project.key -roleUri $rolesoutput."$($role.name)"
        foreach ($member in $members.actors) {
            if ($member.type -eq "atlassian-group-role-actor")
            {
                $groupmembers = Get-GroupMembers -groupName $member.name
                if ($null -eq $groupmembers)
                {
                    continue
                }
                foreach ($groupmember in $groupmembers) {
                    $entry = New-Object Entry
                    $entry.Username = $groupmember.name
                    $entry.UserDisplayName = $groupmember.displayName
                    $entry.ProjectKey = $project.key
                    $entry.ProjectName = $project.name
                    $entry.Role = $role.name
                    $entry.Group = $member.name
                    $entries.Add($entry) | Out-Null
                }
            }
            else 
            {
                $entry = New-Object Entry
                $entry.Username = $groupmember.name
                $entry.UserDisplayName = $groupmember.displayName
                $entry.ProjectKey = $project.key
                $entry.ProjectName = $project.name
                $entry.Role = $role.name
                $entries.Add($entry) | Out-Null
            }
        }
    }
}

$entries | Export-Csv -Path $exportfile -UseCulture -Encoding utf8

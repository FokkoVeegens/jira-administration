# Will retrieve the amount of revisions (changes) to issues within multiple Jira projects
# Replace YOUR_JIRA_SERVER with your own
# Replace the list of projects ($ProjectsFilter) with your own
# Verify the $MaxResults setting, which might need a different number
# Note: this script might have serious impact on the performance of your Jira server. Handle with care

$pat = Get-Content -Path ".\pat.txt"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pat))
$basicAuthValue = "Basic $encodedCreds"
$baseurl = "https://YOUR_JIRA_SERVER/jira/rest/api/latest"
$Headers = @{ 
    "Authorization" = $basicAuthValue;
}
$MaxResults = 9000 # Maximum amount of issues to retrieve
$ErrorActionPreference = 'Stop'
$ProjectsFilter = @("PROJECT1","PROJECT2","PROJECT3")

function Get-JsonOutput($path)
{
    return (Invoke-Webrequest -Uri "$baseurl/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json -Depth 10
} 

function Get-Projects()
{
    return Get-JsonOutput -path "project"
}

function Get-ProjectIssueCount ($projectKey)
{
    $issues = (Get-JsonOutput -path "search?jql=project=$projectKey&maxResults=$($MaxResults)&expand=changelog&fields=id").issues
    $revisionstats = $issues | Select-Object -ExpandProperty changelog | Select-Object -ExpandProperty total | Measure-Object -Sum
    return $revisionstats.Sum
}

$projects = Get-Projects
$SelectedProjects = $projects | Where-Object { $_.key -in $ProjectsFilter }
foreach ($project in $SelectedProjects)
{
    $revisioncount = Get-ProjectIssueCount -projectKey $project.key
    Write-Host "$($project.id),$($project.name),$($project.key),$($revisioncount)"
}

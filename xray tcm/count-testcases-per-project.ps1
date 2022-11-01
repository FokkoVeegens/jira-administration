$ErrorActionPreference = 'Stop'
$pat = Get-Content -Path ".\pat.txt"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pat))
$basicAuthValue = "Basic $encodedCreds"
$baseurlxray = "https://YOUR_JIRA_SERVER/jira/rest/raven/1.0/api"
$baseurl = "https://YOUR_JIRA_SERVER/jira/rest/api/latest"
$Headers = @{ 
    "Authorization" = $basicAuthValue;
}

function Get-JsonOutput($path)
{
    return (Invoke-Webrequest -Uri "$baseurl/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json
} 

function Get-JsonOutputXray($path)
{
    return (Invoke-Webrequest -Uri "$baseurlxray/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json
} 

function Get-Projects()
{
    return Get-JsonOutput -path "project"
}

function Get-ProjectTestcaseCount ($projectKey)
{
    return (Get-JsonOutputXray -path "test?jql=project=$projectKey").Count
}

$projects = Get-Projects
foreach ($project in $projects)
{
    $testcasecount = Get-ProjectTestcaseCount -projectKey $project.key
    Write-Host "$($project.id),$($project.name),$($project.key),$($testcasecount)"
}

$pat = Get-Content -Path ".\pat.txt"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pat))
$basicAuthValue = "Basic $encodedCreds"
$baseurl = "https://YOUR_JIRA_SERVER/jira/rest/api/latest"
$Headers = @{ 
    "Authorization" = $basicAuthValue;
}

function Get-JsonOutput($path)
{
    return (Invoke-Webrequest -Uri "$baseurl/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json
} 

function Get-Projects()
{
    return Get-JsonOutput -path "project"
}

function Get-ProjectIssueCount ($projectKey)
{
    return (Get-JsonOutput -path "search?jql=project=$projectKey&maxResults=1").total
}

$projects = Get-Projects
foreach ($project in $projects)
{
    $issuecount = Get-ProjectIssueCount -projectKey $project.key
    Write-Host "$($project.id),$($project.name),$($project.key),$($issuecount)"
}

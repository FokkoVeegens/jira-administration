$pat = Get-Content -Path ".\pat-jira.txt"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pat))
$basicAuthValue = "Basic $encodedCreds"
$baseurl = "https://YOUR_JIRA_SERVER/jira/rest/api/latest"
$Headers = @{ 
    "Authorization" = $basicAuthValue;
}
$exportfile = "C:\temp\projects.csv"

function Get-JsonOutput($path)
{
    return (Invoke-Webrequest -Uri "$baseurl/$path" -Method GET -ContentType "application/json" -Headers $Headers).content | ConvertFrom-Json
} 

function Get-Projects()
{
    return Get-JsonOutput -path "project?expand=description,lead,url,projectKeys"
}

$projects = Get-Projects

$projects | `
    Select-Object -Property id, key, name, @{Name='lead';Expression={$_.lead.displayName}}, @{Name='leadIsActive';Expression={$_.lead.active}}, description, projectTypeKey, @{Name='category';Expression={$_.projectCategory.name}} |`
    Export-Csv -Path $exportfile -UseCulture -Encoding UTF8

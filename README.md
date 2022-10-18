# jira-administration
This project contains scripts that are useful to extract, insert and manipulate data from, into and in Jira.

# Configuration

Generally I put variables at the top, that need to be configured prior to running the script. One you might run into is the following:
```PowerShell
$pat = Get-Content -Path ".\pat.txt"
```
You'll need a pat.txt file in the working folder, containing username and password, separated by a colon (e.g.: `johndoe:password123`) and nothing else. It will be used for authentication.

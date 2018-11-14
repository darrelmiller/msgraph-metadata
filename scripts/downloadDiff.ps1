﻿# This script is intended to be run from the root of the Graph_Metadata repo.

# Working with git in VSTS builds
# https://stackoverflow.com/questions/37937984/git-refusing-to-merge-unrelated-histories-on-rebase
# https://medium.com/gettimely/automating-git-merges-with-powershell-and-vsts-546ee0dc0c04

param([parameter(Mandatory = $true)][String]$endpointVersion)

# Contains Format-Xml function.
Import-Module .\scripts\utility.ps1 -Force

# Are we on master? If not, we will want our changes committed on master.
$branch = &git rev-parse --abbrev-ref HEAD
Write-Host "Current branch: $branch"
if ($branch -ne "master") {
    git checkout master | Write-Host
    $branch = &git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $branch"
    git pull origin master --allow-unrelated-histories | Write-Host
}

# Download the metadata from livesite. 
$url = "http://graph.microsoft.com/{0}/`$metadata" -f $endpointVersion
$metadataFileName = "{0}_metadata.xml" -f $endpointVersion
$pathToLiveMetadata = "{0}\{1}" -f ($pwd).path, $metadataFileName
$client = new-object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.DownloadFile($url, $pathToLiveMetadata)
Write-Host "Downloaded metadata from $url to $pathToLiveMetadata" -ForegroundColor DarkGreen

# Format the metadata to make it easy for us hoomans to read and perform non-tag line based diffs.
$content = Format-Xml (Get-Content $pathToLiveMetadata) 
[IO.File]::WriteAllLines($pathToLiveMetadata, $content)
Write-Host "Wrote $metadataFileName to disk." -ForegroundColor DarkGreen

# Discover if there are changes between the downloaded file and what is in git.
[array]$result = git status --porcelain

# Check for expected and unexpected changes.
if ($result |Where {$_ -match '^\?\?'}) {
    Write-Error "Unexpected untracked file[s] exists. We shouldn't be adding new files via this script. Only modifying existing files."
} 
elseif ($result |Where {$_ -notmatch '^\?\?'}) {
    Write-Host "Uncommitted changes are present." -ForegroundColor Yellow

    $hasUpdatedMetadata = $false
    Foreach ($r in $result) {
        
        if ($r.Contains($metadataFileName)) {
            $hasUpdatedMetadata = $true 
            Break
        }
    }

    if (!$hasUpdatedMetadata) {
        Write-Error "Exit build. Uncommitted changes are present that do not match the expected file name."
        Exit
    }
}
else {
    # tree is clean
    Write-Host "No changes reported. Build is aborted as succeeded."
    Write-Host "##vso[task.setvariable variable=agent.jobstatus;]canceled"
    Write-Host "##vso[task.complete result=Canceled;]DONE"
    Exit
}

git add $metadataFileName | Write-Host
git commit -m "Updated $metadataFileName from downloadDiff.ps1" | Write-Host
git push origin master | Write-Host
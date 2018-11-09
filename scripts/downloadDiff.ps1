﻿# This script is intended to be run from the root of the Graph_Metadata repo.

param([String]$endpointVersion)

# Contains Format-Xml function.
Import-Module .\scripts\utility.ps1 -Force

if ($endpointVersion -ne 'v1.0' -or $endpointVersion -ne 'beta') {
    $endpointVersion = 'v1.0'
}

# Download the metadata from livesite. 
$url = "http://graph.microsoft.com/{0}/`$metadata" -f $endpointVersion
$metadataFileName = "{0}_metadata.xml" -f $endpointVersion
$pathToLiveMetadata = "D:\repos\Graph_Metadata\{0}" -f $metadataFileName # TODO: get file location via build env variable.
$client = new-object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.DownloadFile($url, $pathToLiveMetadata)

# Format the metadata to make it easy for us hoomans to read and perform non-tag line based diffs.
$content = Format-Xml (Get-Content $pathToLiveMetadata) 
[IO.File]::WriteAllLines($pathToLiveMetadata, $content)

git status --porcelain

# It takes a couple 
Start-Sleep -Milliseconds 10000

# Discover if there are changes between the downloaded file and what is in git.
if(git status --porcelain | Where {$_ -notmatch '^\?\?'}) {
    Write-Host "Exit build, the metadata hasn't been updated."
    Exit # Stop running, no changes identified by git. 
}


Write-Host "fileName $metadataFileName"

#git checkout master
#git add $metadataFileName
# git commit -m 'Updated the metadata from downloadDiff.ps1' | Write-Host
# TODO git push
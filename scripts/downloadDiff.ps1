# This script is intended to be run from the root of the Graph_Metadata repo.

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

$result = git status --porcelain
Write-Host "$result"


if(git status --porcelain |Where {$_ -match $metadataFileName}) {
    Write-Host "foudn change"
}




<#

# Download the metadata from livesite. 
$url = "http://graph.microsoft.com/{0}/`$metadata" -f $endpointVersion
$pathToLiveMetadata = "D:\repos\Graph_Metadata\{0}_metadata.temp.xml" -f $endpointVersion # TODO: get file location via build env variable.
$client = new-object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.DownloadFile($url, $pathToLiveMetadata)

# Format the metadata to make it easy for us hoomans to read and perform non-tag line based diffs.
$content = Format-Xml (Get-Content $pathToLiveMetadata) 
[IO.File]::WriteAllLines($pathToLiveMetadata, $content)

# Read last saved metadata from file.
$pathToSavedMetadata = "{0}_metadata.xml" -f $endpointVersion

# Diff the files. Exit the script if they are the same. 
if((Get-FileHash $pathToLiveMetadata).hash  -eq (Get-FileHash $pathToSavedMetadata).hash) {
    Write-Host "Files are the same, quit the build."
    Exit
}

Write-Host "Files are different, let's generate some code files."

# Replace the existing metadata file's content with the new metadata.
Set-Content -Path $pathToSavedMetadata -Value (Get-Content -Path $pathToLiveMetadata)

# Delete the temporary metadata file.
Remove-Item $pathToLiveMetadata
#>

# TODO: Update the metadata repo with the new metadata file.
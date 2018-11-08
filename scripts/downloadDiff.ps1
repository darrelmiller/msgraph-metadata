# This script is intended to be run from the root of the Graph_Metadata repo.

param([String]$endpointVersion)

# Contains Format-Xml function.
Import-Module .\scripts\utility.ps1 -Force

if ($endpointVersion -ne 'v1.0' -or $endpointVersion -ne 'beta') {
    $endpointVersion = 'v1.0'
}

# Download the metadata from livesite. 
$url = "http://graph.microsoft.com/{0}/`$metadata" -f $endpointVersion
$liveMetadataSavePath = "D:\repos\Graph_Metadata\{0}_metadata.temp.xml" -f $endpointVersion # TODO: get file location via build env variable.
$client = new-object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.DownloadFile($url, $liveMetadataSavePath)

# Format the metadata to make it easy for us hoomans to read and perform non-tag line based diffs.
$content = Format-Xml (Get-Content $liveMetadataSavePath) 
[IO.File]::WriteAllLines($liveMetadataSavePath, $content)

# Read last saved metadata from file.
$pathToSavedFile = "{0}_metadata.xml" -f $endpointVersion
$savedMetadata = Get-Content -Path $pathToSavedFile

# Diff the files. Exit the script if they are the same. 
if((Get-FileHash $liveMetadataSavePath).hash  -eq (Get-FileHash $pathToSavedFile).hash) {
    Write-Host "Files are the same, quit the build."
    Exit
}

Write-Host "Files are different, let's generate some code files."

# TODO: Replace the existing metadata file's content with the new metadata.


# TODO: Delete the temporary metadata file.


# TODO: Update the metadata repo with the new metadata file.


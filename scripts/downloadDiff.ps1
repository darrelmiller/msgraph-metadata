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

# Discover if there are changes between the downloaded file and what is in git.
[array]$result = git status --porcelain

# Check for expected and unexpected changes.
$hasUpdatedMetadata = $false
if($result |Where {$_ -match '^\?\?'}){
    Write-Error "Unexpected untracked file[s] exists. We shouldn't be adding new files via this script. Only modifying existing files."
} 
elseif($result |Where {$_ -notmatch '^\?\?'}) {
    Write-Host "Uncommitted changes are present."

    Foreach ($r in $result) {
        
        if($r.Contains($metadataFileName)) {
            $hasUpdatedMetadata = $true 
            Break
        }
    }

    if(!$hasUpdatedMetadata) {
        Write-Error "Exit build. Uncommitted changes are present that do not match the expected file name."
        Exit
    }
}
else {
    # tree is clean
    Exit
}

# Are we on master? If not, we will want are changes committed on master.
$branch = &git rev-parse --abbrev-ref HEAD
if ($branch -ne "master") {
    git checkout master
}

git add $metadataFileName
git commit -m "Updated $metadataFileName from downloadDiff.ps1"
git push origin master --quiet
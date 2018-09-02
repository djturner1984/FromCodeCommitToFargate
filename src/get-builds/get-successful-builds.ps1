param(
[String] $projectName)

if (!$projectName) {
    Write-Host 'Please pass in parameters'
    return
}

$builds = aws codebuild list-builds-for-project --project-name $projectName | ConvertFrom-Json

Foreach ($buildId in $builds.ids)
{
    $buildDetails = aws codebuild batch-get-builds --ids $buildId | ConvertFrom-Json
    if ($buildDetails.builds[0].buildStatus -eq "SUCCEEDED") {
        return "true"
    }
}

return "false"
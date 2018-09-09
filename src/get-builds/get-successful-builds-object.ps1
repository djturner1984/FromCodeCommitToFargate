param(
[String] $projectName)

if (!$projectName) {
    Write-Host 'Please pass in parameters'
    return
}

$builds = aws codebuild list-builds-for-project --sort-order DESCENDING --project-name $projectName | ConvertFrom-Json

Foreach ($buildId in $builds.ids)
{
    $buildDetails = aws codebuild batch-get-builds --ids $buildId | ConvertFrom-Json
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $timeStamp = $origin.AddSeconds($buildDetails.builds[0].endTime)
    if ($buildDetails.builds[0].buildStatus -eq "SUCCEEDED" -And $timeStamp -gt (Get-Date).AddMinutes(-3).ToUniversalTime()) {
        return $buildDetails.builds[0]
    }
}

return $null
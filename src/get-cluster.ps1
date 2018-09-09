param(
    [String] $projectName,
    [String] $profileName,
    [String] $region)

if (!$projectName -Or !$profileName -Or !$region) {
    Write-Host 'Please pass in parameters'
    return
}

$clusterList = aws ecs list-clusters --profile $profileName --region $region | ConvertFrom-Json

ForEach($cluster in $clusterList.clusterArns) {
    $clusterDetails = aws ecs describe-clusters --cluster $cluster --profile $profileName --region $region | ConvertFrom-Json
    if ($clusterDetails.clusters[0].clusterName -like "*$($projectName)*") {
        return $clusterDetails.clusters[0].clusterName
    }
}

return $null

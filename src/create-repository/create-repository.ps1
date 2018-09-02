param(
[String] $repositoryName)

if (!$repositoryName) {
    Write-Host 'Please pass in parameters'
    return
}


return aws ecr create-repository --repository-name $repositoryName
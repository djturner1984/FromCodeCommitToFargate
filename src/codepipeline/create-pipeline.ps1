param(
[String] $projectName,
[String] $bucketName,
[String] $repositoryName,
[String] $clusterName,
[String] $roleArn,
[String] $profileName,
[String] $region)

if (!$projectName -Or !$bucketName -Or !$repositoryName -Or !$clusterName -Or !$region -Or !$profileName -Or !$roleArn) {
    Write-Host 'Please pass in parameters'
    return
}

$pipelineName = "$($projectName)-pipeline"
$content = (Get-Content ./codepipeline/create-pipeline-template.json)
$content = $content.replace('{PROJECT_NAME}', $projectName)
$content = $content.replace('{REPOSITORY_NAME}', $repositoryName)
$content = $content.replace('{CLUSTER_NAME}', $clusterName)
$content = $content.replace('{BUCKET_NAME}', $bucketName)
$content = $content.replace('{PIPELINE_NAME}', $pipelineName)
$content = $content.replace('{ROLE_ARN}', $roleArn)
$content | Set-Content ./codepipeline/create-pipeline.json


aws codepipeline create-pipeline --cli-input-json file://codepipeline/create-pipeline.json --profile $profileName --region $region
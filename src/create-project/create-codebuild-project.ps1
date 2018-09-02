param(
[String] $projectName,
[String] $profileName,
[String] $codeCommitUrl,
[String] $accountId,
[String] $imageRepoName,
[String] $serviceRole,
[String] $region = "ap-southeast-2",
[String] $imageTag = "latest") #Must be the first statement in your script

if (!$projectName -Or !$profileName -Or !$codeCommitUrl -Or 
    !$accountId -Or !$imageRepoName -Or !$serviceRole) {
    Write-Host 'Please pass in parameters'
    return
}

$content = (Get-Content ./create-project/create-project-template.json)
$content = $content.replace('{PROJECT_NAME}', $projectName)
$content = $content.replace('{CODECOMMIT_URL}', $codeCommitUrl)
$content = $content.replace('{AWS_DEFAULT_REGION}', $region)
$content = $content.replace('{AWS_ACCOUNT_ID}', $accountId)
$content = $content.replace('{IMAGE_REPO_NAME}', $imageRepoName)
$content = $content.replace('{IMAGE_TAG}', $imageTag)
$content = $content.replace('{SERVICE_ROLE}', $serviceRole)
$content | Set-Content ./create-project/create-project.json

Write-Host "running aws codebuild create-project --cli-input-json file://create-project.json --profile $($profileName) --region $($region)"

return aws codebuild create-project --cli-input-json file://create-project/create-project.json --profile $profileName --region $region
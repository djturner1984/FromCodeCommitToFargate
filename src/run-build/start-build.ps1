param(
[String] $projectName,
[String] $profileName,
[String] $region = "ap-southeast-2")

if (!$projectName -Or !$profileName) {
    Write-Host 'Please pass in parameters'
    return
}


aws codebuild start-build --project-name $projectName --profile $profileName --region $region --privileged-mode-override
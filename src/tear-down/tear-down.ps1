param(
[String] $projectName,
[String] $profileName,
[String] $region)

if (!$projectName -Or !$profileName -Or !$region) {
    Write-Host 'Please pass in parameters'
    return
}

#codepipeline
Write-Host "Deleting codepipeline project"
$pipelineName = "$($projectName)-pipeline"
aws codepipeline delete-pipeline --name $pipelineName --profile $profileName --region $region

#ecr
Write-Host "Deleting ecr repository"
aws ecr delete-repository --repository-name $projectName --profile $profileName --region $region --force

#codebuild
Write-Host "Deleting codebuild project"
aws codebuild delete-project --name $projectName --profile $profileName --region $region

#codebuild role
Write-Host "Deleting codebuild role"
$roleName = "$($projectName)-codebuild-role"
$policyName = "$($roleName)-Policy"
aws iam --region $region delete-role-policy --role-name $roleName --policy-name $policyName --profile $profileName
aws iam --region $region delete-role --role-name $roleName --profile $profileName --region $region

#codepipeline role
Write-Host "Deleting codepipeline role"
$roleName = "$($projectName)-codepipeline-role"
$policyName = "$($roleName)-Policy"
aws iam --region $region delete-role-policy --role-name $roleName --policy-name $policyName --profile $profileName
aws iam --region $region delete-role --role-name $roleName --profile $profileName --region $region

#service stack
Write-Host "Deleting service stack"
$serviceStackName = "$($projectName)-stack"
aws cloudformation delete-stack --stack-name $serviceStackName --profile $profileName --region $region

Start-Sleep -s 300

#vpc stack
Write-Host "Deleting vpc stack"
$vpcStackName = "$($projectName)-vpc"
aws cloudformation delete-stack --stack-name $vpcStackName --profile $profileName --region $region

Start-Sleep -s 240


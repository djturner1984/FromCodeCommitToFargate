param(
[String] $projectName,
[String] $profileName,
[String] $region)

if (!$projectName -Or !$profileName -Or !$region) {
    Write-Host 'Please pass in parameters'
    return
}

aws ecr delete-repository --repository-name $projectName --profile $profileName --region $region --force
aws codebuild delete-project --name $projectName --profile $profileName --region $region
$roleName = "$($projectName)-role"
$policyName = "$($roleName)-Policy"
aws iam --region $region delete-role-policy --role-name $roleName --policy-name $policyName --profile $profileName
aws iam --region $region delete-role --role-name $roleName --profile $profileName --region $region
$serviceStackName = "$($projectName)-stack"
aws cloudformation delete-stack --stack-name $serviceStackName --profile $profileName --region $region
Start-Sleep -s 120
$vpcStackName = "$($projectName)-vpc"
aws cloudformation delete-stack --stack-name $vpcStackName --profile $profileName --region $region
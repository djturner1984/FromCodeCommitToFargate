param(
    [String]$profileName,
    [String]$projectName,
    [String]$region)

if (!$profileName -Or !$projectName -Or !$region) {
    Write-Host 'Please pass in profile name'
    return
}

$stackName = "$($projectName)-vpc"
aws cloudformation create-stack --region $region --stack-name $stackName --template-body file://cloudformation/fargate-networking-stacks/public-vpc.yml --capabilities CAPABILITY_IAM --profile $profileName
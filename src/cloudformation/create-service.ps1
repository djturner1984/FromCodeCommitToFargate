param(
    [String] $profileName, 
    [String] $healthCheckUrlPath,     
    [String] $repositoryUrl, 
    [String] $projectName,
    [String] $region) #Must be the first statement in your script

if (!$profileName -Or !$healthCheckUrlPath -Or !$repositoryUrl -Or !$projectName -Or !$region) {
    Write-Host 'Please pass in parameters'
    return
}

$vpcStackName = "$($projectName)-vpc"
$stackName = "$($projectName)-stack"


aws cloudformation create-stack --stack-name $stackName --template-body file://cloudformation/service-stacks/public-subnet-public-loadbalancer.yml --parameters ParameterKey=StackName,ParameterValue=$vpcStackName ParameterKey=ServiceName,ParameterValue=$projectName `
ParameterKey=ImageUrl,ParameterValue=$repositoryUrl ParameterKey=DesiredCount,ParameterValue=1 ParameterKey=HealthCheckUrlPath,ParameterValue=$healthCheckUrlPath --profile $profileName --region $region
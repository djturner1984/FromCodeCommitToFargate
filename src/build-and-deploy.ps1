param(
[String] $projectName,
[String] $profileName,
[String] $healthCheckUrlPath,
[String] $region = "ap-southeast-2")

if (!$projectName -Or !$profileName -Or !$healthCheckUrlPath) {
    Write-Host 'Usage run.ps1 [projectName] [profileName] [healthCheckUrlPath] [region]'
    return
}

Write-Host "Running with run.ps1 $($projectName) $($profileName) $($healthCheckUrlPath) $($region)"
try {
    # Getting ECR Repository
    Write-Host 'Getting ECR Repository'
    $ecrRepo = aws ecr describe-repositories --repository-names $projectName --profile $profileName --region $region | ConvertFrom-Json

    if (!$ecrRepo.repositories -Or !$ecrRepo.repositories.Length -gt 1) {
        throw "Unexpected number of ECR repositories for $($projectName)" 
        return
    }
    $ecrRepository = $ecrRepo.repositories[0]

    # Start a build
    Write-Host 'Starting a build'
    aws codebuild start-build --project-name $projectName --profile $profileName --region $region --privileged-mode-override

    # wait for successful build
    For ($i=0; $i -lt 30; $i++) {
        $build = .\get-builds\get-successful-builds-object.ps1 $projectName
        if ($build) {
            break
        }
        else {
            Write-Host 'no successful build found yet, will wait'
            Start-Sleep -s 60
        }
    }

    $build = .\get-builds\get-successful-builds-object.ps1 $projectName
    if ($build) {
        Write-Host 'found successful build.'
    }
    else {
        Write-Host 'timed out waiting for build.'
        return
    }
    $builds = aws codebuild list-builds-for-project --sort-order DESCENDING --project-name $projectName | ConvertFrom-Json
    $buildName = "$($projectName)-$($builds.ids.Length)"
    $vpcStackName = "$($buildName)-vpc"
    # Create a VPC
    Write-Host 'Creating VPC'
    .\cloudformation\create-vpc.ps1 $profileName $buildName $region

    Start-Sleep -s 180
    Write-Host 'Waiting for vpc stack'
    aws cloudformation wait stack-exists --stack-name $vpcStackName --profile $profileName --region $region
    # Create fargate service
    Write-Host 'Creating Service'
    .\cloudformation\create-service.ps1 $profileName $healthCheckUrlPath $ecrRepository.repositoryUri $buildName $region
} catch {
    $errorMessage = $_.Exception.Message
    $failedItem = $_.Exception.ItemName
    Write-Host "Error occured: $($errorMessage) - item: $($failedItem)"
    #./tear-down/tear-down.ps1 $projectName $profileName $region
    return
}
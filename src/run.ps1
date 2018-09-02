param(
[String] $projectName,
[String] $profileName,
[String] $codeCommitUrl,
[String] $accountId,
[String] $healthCheckUrlPath,
[String] $region = "ap-southeast-2",
[String] $imageTag = "latest")

if (!$projectName -Or !$profileName -Or 
    !$codeCommitUrl -Or !$accountId -Or !$healthCheckUrlPath) {
    Write-Host 'Usage run.ps1 [projectName] [profileName] [codeCommitUrl] [accountId] [healthCheckUrlPath] [region] [imageTag]'
    return
}

Write-Host "Running with run.ps1 $($projectName) $($profileName) $($codeCommitUrl) $($accountId) $($healthCheckUrlPath) $($region) $($imageTag)"
try {
    # Create ECR Repository
    Write-Host 'Creating ECR Repository'
    $ecrRepo = .\create-repository\create-repository.ps1 $projectName | ConvertFrom-Json

    
    if (!$ecrRepo.repository.repositoryName) {
        throw "Error getting repository for $($projectName)" 
        return
    }
    $ecrRepositoryName = $ecrRepo.repository.repositoryName

    # Create role
    Write-Host 'Creating Role'
    $roleName = "$($projectName)-role"

    $role = .\create-role\create-iam-role.ps1 $roleName $profileName $region | ConvertFrom-Json

    if (!$role.Role.Arn) {
        throw "Error creating role for $($projectName)"
        return
    }

    Write-Host "Waiting for role to be ready"
    Start-Sleep -s 10
    # Code build project
    Write-Host 'Creating CodeBuild project for repo ' $ecrRepo.repository.repositoryName
    .\create-project\create-codebuild-project.ps1 $projectName $profileName $codeCommitUrl $accountId $ecrRepositoryName $role.Role.Arn

    Write-Host "Waiting for build to be ready"
    Start-Sleep -s 10
    # Start a build
    Write-Host 'Starting a build'
    aws codebuild start-build --project-name $projectName --profile $profileName --region $region --privileged-mode-override

    # wait for successful build
    For ($i=0; $i -lt 30; $i++) {
        $buildResult = .\get-builds\get-successful-builds.ps1 $projectName
        if ($buildResult -eq "true") {
            break
        }
        else {
            Write-Host 'no successful build found yet, will wait'
            Start-Sleep -s 60
        }
    }

    $buildResult = .\get-builds\get-successful-builds.ps1 $projectName
    if ($buildResult -eq "true") {
        Write-Host 'found successful build.'
    }
    else {
        Write-Host 'timed out waiting for build.'
        return
    }

    $vpcStackName = "$($projectName)-vpc"
    # Create a VPC
    Write-Host 'Creating VPC'
    .\cloudformation\create-vpc.ps1 $profileName $projectName $region

    Start-Sleep -s 180
    Write-Host 'Waiting for vpc stack'
    aws cloudformation wait stack-exists --stack-name $vpcStackName --profile $profileName --region $region
    # Create fargate service
    Write-Host 'Creating Service'
    .\cloudformation\create-service.ps1 $profileName $healthCheckUrlPath $ecrRepo.repository.repositoryUri $projectName $region
} catch {
    $errorMessage = $_.Exception.Message
    $failedItem = $_.Exception.ItemName
    Write-Host "Error occured: $($errorMessage) - item: $($failedItem)"
    ./tear-down/tear-down.ps1 $projectName $profileName $region
    return
}
param(
[String] $projectName,
[String] $profileName,
[String] $codeCommitRepoName,
[String] $accountId,
[String] $healthCheckUrlPath,
[String] $bucketName,
[String] $region = "ap-southeast-2",
[String] $imageTag = "latest")

if (!$projectName -Or !$profileName -Or 
    !$codeCommitRepoName -Or !$accountId -Or !$healthCheckUrlPath -Or !$bucketName) {
    Write-Host 'Usage run.ps1 [projectName] [profileName] [codeCommitUrl] [accountId] [healthCheckUrlPath] [bucketName] [region] [imageTag]'
    return
}

Write-Host "Running with run.ps1 $($projectName) $($profileName) $($codeCommitRepoName) $($accountId) $($healthCheckUrlPath) $($region) $($imageTag)"
try {
    # Get code commit details
    $repo = aws codecommit get-repository --repository-name $codeCommitRepoName --profile $profileName --region $region | ConvertFrom-Json
    if (!$repo.repositoryMetadata) {
        throw "Error getting codecommit repository for $($codeCommitRepoName)" 
        return
    }

    $codeCommitUrl = $repo.repositoryMetadata.cloneUrlHttp

    # Create ECR Repository
    Write-Host 'Creating ECR Repository'
    $ecrRepo = .\create-repository\create-repository.ps1 $projectName | ConvertFrom-Json

    
    if (!$ecrRepo.repository.repositoryName) {
        throw "Error getting repository for $($projectName)" 
        return
    }
    $ecrRepositoryName = $ecrRepo.repository.repositoryName

    # Create role
    Write-Host 'Creating Role for codebuild'
    $roleName = "$($projectName)-codebuild-role"

    $role = .\create-role\create-iam-role.ps1 $roleName $profileName $region | ConvertFrom-Json

    if (!$role.Role.Arn) {
        throw "Error creating role for $($projectName)"
        return
    }

    Write-Host "Waiting for role to be ready"
    Start-Sleep -s 10
    # Code build project
    Write-Host 'Creating CodeBuild project for repo ' $ecrRepo.repository.repositoryName
    .\create-project\create-codebuild-project.ps1 $projectName $profileName $codeCommitUrl $accountId $ecrRepositoryName $role.Role.Arn $bucketName

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

    Start-Sleep -s 300
    Write-Host 'Waiting for vpc stack'
    aws cloudformation wait stack-exists --stack-name $vpcStackName --profile $profileName --region $region
    # Create fargate service
    Write-Host 'Creating Service'
    .\cloudformation\create-service.ps1 $profileName $healthCheckUrlPath $ecrRepo.repository.repositoryUri $projectName $region

    Start-Sleep -s 300
    Write-Host 'Waiting for service stack'
    $stackName = "$($projectName)-stack"
    aws cloudformation wait stack-exists --stack-name $stackName --profile $profileName --region $region
    $clusterName = .\get-cluster.ps1 $projectName $profileName $region
    
    Write-Host 'Creating Role for codepipeline'
    $roleName = "$($projectName)-codepipeline-role"
    $codepipelineRole = .\create-role\create-codepipeline-role.ps1 $roleName $profileName $region | ConvertFrom-Json
    Write-Host "Waiting for role to be ready"
    Start-Sleep -s 10
    .\codepipeline\create-pipeline.ps1 $projectName $bucketName $codeCommitRepoName $clusterName $codepipelineRole.Role.Arn $profileName $region
} catch {
    $errorMessage = $_.Exception.Message
    $failedItem = $_.Exception.ItemName
    Write-Host "Error occured: $($errorMessage) - item: $($failedItem)"
    ./tear-down/tear-down.ps1 $projectName $profileName $region
    return
}
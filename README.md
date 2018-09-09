# FromCodeCommitToFargate
This set of scripts will bring a .net core codecommit repository with docker set up all the to a fargate ECS deployment

This will do the following:
1. Create an ECR docker repository
2. Create a role to be used for a codebuild repository
3. Create codebuild project
4. Start a build
5. Waits for successful build
6. Creates a VPC (CloudFormation)
7. Creates an ECS cluster of fargate tasks
8. Creates codepipeline integration (will build and deploy on every commit)

To kick it off run the following command:

run.ps1 [projectName] [profileName] [codeCommitUrl] [accountId] [healthCheckUrlPath] [bucketName] [region] [imageTag]

To tear down your stack when finished run the following command:

.\tear-down\tear-down.ps1 [projectName] [profileName] [region]


You can make this work by creating a codecommit repository from this example: https://github.com/djturner1984/FromCodeCommitToFargate-ExampleProject

Prerequisites:

AWS CLI

AWS CLI profile with enough permissions

CodeCommit repository with dockerfile

Buildspec.yml in your repository

An S3 bucket for artifacts

Limitations:
Not completely idempotent yet

Doesn't teardown completely (cloudwatch logs etc.)

No Route 53 integration yet

Not setup for https yet

References:
Cloudformation templates come from: https://github.com/nathanpeck/aws-cloudformation-fargate (slightly modified to support health check path)

AWS' own documentation on doing this via the CLI

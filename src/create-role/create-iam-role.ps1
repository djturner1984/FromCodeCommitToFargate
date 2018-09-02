param(
    [String] $roleName,
    [String] $profileName,
    [String] $region)

if (!$roleName -Or !$profileName -Or !$region) {
    Write-Host 'Please pass in role name'
    return
}

$existingRole = aws iam get-role --role-name $roleName --profile $profileName
if (!$existingRole) {
    aws iam --region $region create-role --role-name $roleName --assume-role-policy-document file://create-role/codebuild-assume-role.json --profile $profileName
} else {
    write-host 'Role' $roleName 'already exists'
}

$policyName = "$($roleName)-policy"

return aws iam put-role-policy --role-name $roleName --policy-name $policyName --policy-document file://create-role/codebuild-put-role-policy.json --profile $profileName
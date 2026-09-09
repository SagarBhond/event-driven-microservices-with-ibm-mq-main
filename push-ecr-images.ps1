$ErrorActionPreference = "Stop"

$account = "882040517001"
$region = "ap-south-1"
$registry = "$account.dkr.ecr.$region.amazonaws.com"

if ((docker version *> $null) -or $LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running. Start Docker Desktop and run this script again."
}

aws ecr get-login-password --region $region |
    docker login --username AWS --password-stdin $registry
if ($LASTEXITCODE -ne 0) {
    throw "AWS ECR login failed."
}

$services = @("producer", "inventory", "payment", "notification")
foreach ($service in $services) {
    $name = "order-saga-$service"
    $localImage = "sagarbhond/${name}:latest"
    $ecrImage = "$registry/${name}:latest"
    $context = Join-Path $PSScriptRoot "order-$service-service"

    docker build --tag $localImage $context
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for $name."
    }

    docker tag $localImage $ecrImage
    docker push $ecrImage
    if ($LASTEXITCODE -ne 0) {
        throw "ECR push failed for $name."
    }
}

Write-Output "All four images were published to ECR with the latest tag."

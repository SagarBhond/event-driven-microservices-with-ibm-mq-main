$ErrorActionPreference = "Stop"

docker version *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop is not running. Start Docker Desktop and run this script again."
}

docker login
if ($LASTEXITCODE -ne 0) {
    throw "Docker Hub login failed."
}

$services = @("producer", "inventory", "payment", "notification")
foreach ($service in $services) {
    $image = "sagarbhond/order-saga-$service`:latest"
    $context = Join-Path $PSScriptRoot "order-$service-service"

    docker build --tag $image $context
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for $image."
    }

    docker push $image
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed for $image."
    }
}

Write-Output "All four Docker Hub images were published with the latest tag."
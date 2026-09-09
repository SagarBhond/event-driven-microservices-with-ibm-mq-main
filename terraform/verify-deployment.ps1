param(
    [Parameter(Mandatory = $true)]
    [string]$AlbDnsName,
    [int]$Attempts = 30,
    [int]$DelaySeconds = 10
)

$ErrorActionPreference = "Stop"
$checks = @(
    @{ Name = "producer"; Url = "http://$AlbDnsName/api/producer/health" },
    @{ Name = "inventory"; Url = "http://$AlbDnsName/api/inventory/health" },
    @{ Name = "payment"; Url = "http://$AlbDnsName/api/payment/health" },
    @{ Name = "notification"; Url = "http://$AlbDnsName/api/notification/health" }
)

for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    $failed = @()
    foreach ($check in $checks) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $check.Url -TimeoutSec 10
            if ($response.StatusCode -ne 200) {
                $failed += "$($check.Name) returned HTTP $($response.StatusCode)"
            }
        } catch {
            $failed += "$($check.Name) is not ready"
        }
    }

    if ($failed.Count -eq 0) {
        Write-Output "All application health endpoints: HTTP 200"
        exit 0
    }

    Write-Output "Attempt $attempt/${Attempts}: $($failed -join ', ')"
    if ($attempt -lt $Attempts) {
        Start-Sleep -Seconds $DelaySeconds
    }
}

Write-Error "Application health verification failed after $Attempts attempts."
exit 1
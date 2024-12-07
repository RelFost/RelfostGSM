param (
    [string]$csvFile
)

# Read the CSV file
$packages = Import-Csv -Path $csvFile

# Check and install each package
foreach ($package in $packages) {
    Write-Host "Checking package: $($package.Package)"
    if (-not (Get-Package -Name $package.Package -ErrorAction SilentlyContinue)) {
        Write-Host "Installing: $($package.Package)"
        if ($package.DownloadUrl) {
            $installerPath = Join-Path $env:TEMP ([System.IO.Path]::GetFileName($package.DownloadUrl))
            Invoke-WebRequest -Uri $package.DownloadUrl -OutFile $installerPath
            Start-Process -FilePath $installerPath -ArgumentList $package.Arguments -Wait
            Remove-Item -Path $installerPath -Force
        } else {
            Write-Host "No DownloadUrl provided for package: $($package.Package)"
        }
    } else {
        Write-Host "Package already installed: $($package.Package)"
    }
}

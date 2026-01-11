if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Restarting script with administrative privileges."
    Start-Process powershell -ArgumentList "-File $PSCommandPath" -Verb RunAs
    exit
}

$imageTargets = @(".bmp", ".dng", ".gif", ".heic", ".jpeg", ".jpg", ".png", ".psd", ".raw", ".tiff", ".webp")
$photoshopPath = $null

$photoshopFiles = Get-ChildItem -Path "C:\Program Files\Adobe" -Filter "Photoshop.exe" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $photoshopFiles) {
    $currentPath = $file.FullName
    $versionName = $file.Directory.Name

    Write-Host "`nFound: $versionName" -ForegroundColor Green
    $choice = Read-Host "Would you like to add this version to the context menu? (Y/N)"
    while ($choice.ToUpper() -notin 'Y', 'N') {
        $choice = Read-Host "Invalid selection, please type Y or N"
    }
    if ($choice.ToUpper() -eq 'Y') {
        $photoshopPath = $currentPath
        break
    }
}
if ($null -eq $photoshopPath) {
    Write-Host "No Photoshop version found or selected." -ForegroundColor Red
    Read-Host "Press 'Enter' to exit the script"
    Exit 1
}

foreach ($target in $imageTargets) {
    $registryPath = "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$target\shell\Edit with Photoshop\command"
    try {
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        $commandValue = "`"$photoshopPath`" `"%1`""
        Set-ItemProperty -Path $registryPath -Name "(default)" -Value $commandValue
        Write-Host "Successfully updated the menu for: $target" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to update registry for $target. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Host "Process finished" -ForegroundColor Cyan
Read-Host "Press 'Enter' to exit the script"
# -----------------------------
# Script: Remove-SelectedAppx.ps1
# -----------------------------
# Run this script from an elevated PowerShell prompt.
# E.g.: .\Remove-SelectedAppx.ps1
 
# Optionally, define a list of apps you do NOT want to remove (e.g., Store, Calculator, etc.)
# because removing some of these can break Sysprep or Windows functionality.
# Uncomment and edit as necessary:
 
# $exclusions = @(
#     'Microsoft.WindowsStore',
#     'Microsoft.DesktopAppInstaller',
#     'Microsoft.NET.Native.Framework',
#     'Microsoft.NET.Native.Runtime',
#     'Microsoft.VCLibs',
#     'Microsoft.WindowsCalculator',
#     'Microsoft.Windows.Photos'
#     # Add more if needed, such as 'Microsoft.MicrosoftEdge',
#     # 'Microsoft.WindowsCamera', etc.
# )
 
# Gather all provisioned AppX packages (applies to new user profiles):
$provPackages = Get-AppxProvisionedPackage -Online | Select-Object DisplayName, PackageName
 
# Gather all installed AppX packages for all users:
$installedPackages = Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName, PackageFamilyName
 
# Join both datasets on 'Name' / 'DisplayName' so we can see if the package is also provisioned
# This helps you remove it from both "installed" and "provisioned" states.
# We'll create a custom object that shows both installed and provisioned details.
 
$allApps = $installedPackages | ForEach-Object {
    $match = $provPackages | Where-Object { $_.DisplayName -eq $_.Name }
    [PSCustomObject]@{
        Name             = $_.Name
        PackageFullName  = $_.PackageFullName
        PackageFamilyName= $_.PackageFamilyName
        Provisioned      = if ($match) { $true } else { $false }
        ProvPackageName  = if ($match) { $match.PackageName } else { $null }
    }
}
 
# If you are using exclusions, uncomment the following line:
# $allApps = $allApps | Where-Object { $exclusions -notcontains $_.Name }
 
# Show all apps in Out-GridView, allowing multiple selection via -PassThru.
# CTRL + click (or shift-click) to select multiple items to remove.
$selected = $allApps | Out-GridView -Title "Select the AppX packages to remove" -PassThru
 
# Confirm selection before proceeding:
if ($selected) {
    Write-Host "You have selected the following packages to remove:" -ForegroundColor Yellow
    $selected | Select-Object Name, PackageFullName, Provisioned | Format-Table
    $confirm = Read-Host "Type 'YES' to confirm removal or anything else to cancel"
    if ($confirm -eq 'YES') {
        foreach ($app in $selected) {
            Write-Host "Removing $($app.Name) ($($app.PackageFullName))..." -ForegroundColor Cyan
            # Remove from all user profiles where installed
            # The -AllUsers switch for Remove-AppxPackage is available
            # in newer Windows 10/11 builds. If not recognized, you can
            # pipeline from Get-AppxPackage -AllUsers as a workaround.
 
            # Method A (Newer PowerShell / Windows):
            # Remove-AppxPackage -Package $app.PackageFullName -AllUsers
 
            # Method B (Fallback / older versions):
            Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -eq $app.PackageFullName } | Remove-AppxPackage
 
            # Remove from the provisioning (future installs) if it was provisioned
            if ($app.Provisioned -eq $true -and $app.ProvPackageName) {
                Remove-AppxProvisionedPackage -Online -PackageName $app.ProvPackageName
            }
 
            Write-Host "Removed $($app.Name)." -ForegroundColor Green
        }
    }
    else {
        Write-Host "Removal canceled by user." -ForegroundColor Red
    }
}
else {
    Write-Host "No apps selected; exiting." -ForegroundColor Red
}

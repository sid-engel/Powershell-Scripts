# THIS SCRIPT WILL retrieve all the Windows Servers in the domain and export the disk drives to a CSV file.

Set-ExecutionPolicy Unrestricted -Force
Import-Module ActiveDirectory

# Delete reports older than 60 days
$OldReports = (Get-Date).AddDays(-60)

# Location for disk reports
Get-ChildItem "C:\Temp\DiskSpaceReport\*.*" |
Where-Object { $_.LastWriteTime -le $OldReports } |
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Create variable for log date
$LogDate = get-date -f yyyyMMddhhmm

# Get all systems
$Systems = Get-ADComputer -Properties * -Filter { OperatingSystem -like "*Windows Server*" } |
Where-Object { $_.Enabled -eq $true } | Select-Object Name, DNSHostName | Sort-Object Name

# Loop through each system
$DiskReport = ForEach ($System in $Systems) {
    Get-WmiObject win32_logicaldisk `
        -ComputerName $System.DNSHostName -Filter "Drivetype=3" `
        -ErrorAction SilentlyContinue
}

# Create disk report
$DiskReport | Select-Object `
@{Label = "HostName"; Expression = { $_.SystemName } },
@{Label = "DriveLetter"; Expression = { $_.DeviceID } },
@{Label = "DriveName"; Expression = { $_.VolumeName } },
@{Label = "Total Capacity (GB)"; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } },
@{Label = "Free Space (GB)"; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb ) } },
@{Label = 'Free Space (%)'; Expression = { "{0:P0}" -f ($_.Freespace / $_.Size) } } |

# Export report to CSV file
Export-Csv -Path "C:\Temp\DiskSpaceReport\DiskReport_$logDate.csv" -NoTypeInformation -Delimiter ";"

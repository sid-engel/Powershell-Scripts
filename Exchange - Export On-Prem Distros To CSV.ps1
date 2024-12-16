# Define the output CSV file path
$OutputCsvPath = "C:\Temp\All_Distribution_Groups.csv"

# Initialize an empty array to store all data
$AllGroupsData = @()

# Get all distribution groups
$DGs = Get-DistributionGroup

# Loop through each distribution group to get members and collect data
foreach ($DG in $DGs) {
    $DGName = $DG.Name
    $DGEmail = $DG.PrimarySmtpAddress  # Get the distribution group's email address
    $Members = Get-DistributionGroupMember -Identity $DGName | Select-Object PrimarySmtpAddress

    # Combine all member emails into a single string, separated by semicolons
    $MemberEmails = $Members.PrimarySmtpAddress -join "; "

    # Add the group data with the combined member emails to the array
    $AllGroupsData += [PSCustomObject]@{
        GroupName = $DGName
        GroupEmail = $DGEmail
        Members = $MemberEmails
    }
}

# Export all data to a single CSV file
$AllGroupsData | Export-Csv -Path $OutputCsvPath -NoTypeInformation

# Disconnect from on-premises Exchange
Remove-PSSession $Session

# Connect to Exchange Online
Connect-ExchangeOnline

# Import distribution groups and members from the consolidated CSV
$CSVFilePath = "PATH"
$GroupsData = Import-Csv -Path $CSVFilePath

foreach ($Group in $GroupsData) {
    # Extract distribution group name and email
    $DGName = $Group.GroupName
    $DGEmail = $Group.GroupEmail

    # Create the distribution group in Exchange Online with the specified email
    New-DistributionGroup -Name $DGName -PrimarySmtpAddress $DGEmail

    # Split the member emails from the "Members" field, which are separated by semicolons
    $MemberEmails = $Group.Members -split "; "

    # Add each member to the distribution group
    foreach ($MemberEmail in $MemberEmails) {
        Add-DistributionGroupMember -Identity $DGName -Member $MemberEmail
    }
}

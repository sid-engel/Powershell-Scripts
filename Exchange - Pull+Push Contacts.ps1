# Connect to Tenant A (Modern Authentication with MFA support)
Connect-ExchangeOnline -UserPrincipalName ADMINLOGIN@ADMIN.com -ShowProgress $true

# Export user data from Tenant A (Get-Mailbox command)
Get-Mailbox -ResultSize Unlimited | Select DisplayName, UserPrincipalName, Alias | Export-Csv "TenantA_Users.csv" -NoTypeInformation

-----
-----
-----

# Connect to Tenant B using Modern Authentication
Connect-ExchangeOnline -UserPrincipalName ADMINLOGIN@ADMIN.com -ShowProgress $true

# Import contacts into Tenant B's GAL (as mail contacts)
Import-Csv "TenantA_Users.csv" | ForEach-Object {
    New-MailContact -Name $_.DisplayName -ExternalEmailAddress $_.UserPrincipalName -Alias $_.Alias
}

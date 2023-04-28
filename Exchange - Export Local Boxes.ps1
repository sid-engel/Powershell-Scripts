# First, establish a connection to the Exchange Server
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://<ExchangeServerName>/PowerShell/ -Authentication Kerberos
Import-PSSession $Session

# Set the output file location and name
$ExportPath = "C:\MailboxExports\"

# Get a list of all mailboxes on the server
$Mailboxes = Get-Mailbox -ResultSize Unlimited

# Loop through each mailbox and export it to a .pst file
foreach ($Mailbox in $Mailboxes) {
    $Name = $Mailbox.Name
    $ExportFile = "$ExportPath\$Name.pst"
    New-MailboxExportRequest -Mailbox $Name -FilePath $ExportFile
}

# Close the connection to the Exchange Server
Remove-PSSession $Session

$ExportCsvPath = "C:\Temp\MailEnabledContacts.csv"
$Contacts = Get-MailContact
$Contacts | Select-Object DisplayName, Alias, PrimarySmtpAddress, ExternalEmailAddress | Export-Csv -Path $ExportCsvPath -NoTypeInformation

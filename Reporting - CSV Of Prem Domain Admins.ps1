# Dumps a CSV to C:\Admin-List DOMAIN.COM.csv
$domain = (Get-ADDomain).DNSRoot
$filename= 'c:\Admin-List ' + $domain + '.csv'
$list = get-adgroupmember 'domain admins' | select samaccountname | Export-CSV $filename

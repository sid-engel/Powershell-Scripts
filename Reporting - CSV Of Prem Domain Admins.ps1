# Simple 1 liner.
# Dumps a CSV onto C:\.
get-adgroupmember 'domain admins' | select samaccountname | Export-CSV C:\domain-admins-list.csv

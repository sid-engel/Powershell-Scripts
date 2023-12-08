# COPY FILES VIA TEXT FILE LIST FROM SOURCE TO DESTINATION
$source = ""
$file_list = Get-Content "c:\consolidated list.txt"
$destination = ""

#foreach file in the text
foreach ($file in $file_list) {
  if (!(Test-Path $source\$file)) { #if the file is not there
    Write-Warning "$file absent."
  } else {
    Write-Host " $file File in list identified." #if file exists there
	if (Test-Path -path $destination, $file) {
		Write-Host "Copying!"
		Copy-Item -Path $file -Destination $destination
	}
	else {
		Write-Host "File already copied, skipping!"
	}
  }
}

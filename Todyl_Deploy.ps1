# Script Name: Todyl_Deploy.ps1
# Purpose:    Install Todyl silently on a VDI Instant Clone and maintain a CSV mapping of MachineName -> Registry UDID values.
# Author:     Blake Marvin/Sid Engel - AVAJEN
# Date:       2/12/25

# ----------------------
# Script Configuration
# ----------------------

# Central CSV path:
$CsvFilePath = '\\NETWORKSHARELOCATION\Todyl_Mapping.csv'

# Determine log file path in the same folder as the CSV
$ScriptFolder = Split-Path -Path $CsvFilePath
$LogFilePath  = Join-Path -Path $ScriptFolder -ChildPath 'Todyl_Install.log'

# Todyl Installer URL and Deploy Key
$TodylInstallerUrl = 'https://download.todyl.com/sgn_connect/SGNConnect_Latest.exe'
$DeployKey         = 'TODYL DEPLOYMENT KEY'

# Registry location and value names
$RegPath    = 'HKLM:\SOFTWARE\WOW6432Node\SGN\SGN Connect'
$ValueUDID  = 'UDID'
$ValueEAUID = 'ElasticAgentUDID'

# ----------------------
# Helper Functions
# ----------------------

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string] $Message
    )

    $timeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $logLine   = "[$timeStamp] $Message"
    Add-Content -Path $LogFilePath -Value $logLine
}

# ----------------------
# Main Script Logic
# ----------------------

try {
    # Silence progress bars
    $ProgressPreference = 'SilentlyContinue'

    # Collect current machine name
    $MachineName = $env:COMPUTERNAME
    Write-Log "Starting Todyl install process for machine: $MachineName"

    # Import CSV
    if (Test-Path $CsvFilePath) {
        Write-Log "Importing CSV from $CsvFilePath"
        $csvContent = Import-Csv -Path $CsvFilePath
    }
    else {
        Write-Log "CSV file not found. Creating a new CSV at $CsvFilePath"
        # If you want to initialize with headers:
        "MachineName,UDID,ElasticAgentUDID" | Out-File -FilePath $CsvFilePath -Encoding UTF8
        $csvContent = Import-Csv -Path $CsvFilePath
    }

    # --- FIX: Force $csvContent to be an array to avoid 'op_Addition' error ---
    $csvContent = @($csvContent)

    # Attempt to find an existing entry for this machine
    $existingEntry = $csvContent | Where-Object { $_.MachineName -eq $MachineName }

    if ($existingEntry) {
        Write-Log "Machine $MachineName found in CSV. Applying stored registry values..."

        # Write registry values prior to Todyl installation
        New-Item -Path $RegPath -Force | Out-Null
        
        if ($null -ne $existingEntry.UDID) {
            New-ItemProperty -Path $RegPath -Name $ValueUDID  -Value $existingEntry.UDID  -PropertyType String -Force | Out-Null
        }
        if ($null -ne $existingEntry.ElasticAgentUDID) {
            New-ItemProperty -Path $RegPath -Name $ValueEAUID -Value $existingEntry.ElasticAgentUDID -PropertyType String -Force | Out-Null
        }

        Write-Log "Stored UDID: $($existingEntry.UDID), Stored ElasticAgentUDID: $($existingEntry.ElasticAgentUDID)"
    }
    else {
        Write-Log "Machine $MachineName not found in CSV. Will install Todyl without setting registry keys first."
    }

    # ----------------------
    # Todyl Installation
    # ----------------------
    try {
        Write-Log "Downloading Todyl installer from $TodylInstallerUrl"
        $tempInstaller = Join-Path $env:TEMP 'SGNConnect_Latest.exe'
        Invoke-WebRequest -Uri $TodylInstallerUrl -UseBasicParsing -OutFile $tempInstaller

        Write-Log "Running Todyl silent install..."
        Start-Process -FilePath $tempInstaller -ArgumentList "/silent /deployKey $DeployKey" -Wait
        Write-Log "Todyl installer completed with Exit Code: $LASTEXITCODE"

        if ($LASTEXITCODE -eq 0) {
            # Start the Todyl client
            $TodylPath = 'C:\Program Files\SGN Connect\Current\sgnconnect.exe'
            if (Test-Path $TodylPath) {
                Write-Log "Starting SGN Connect..."
                Start-Process $TodylPath
            }
            else {
                Write-Log "Warning: Could not find $TodylPath to launch SGN Connect."
            }
        }
        else {
            Write-Log "Todyl installation failed or returned a non-zero exit code."
        }

        # Clean up installer
        if (Test-Path $tempInstaller) {
            Remove-Item $tempInstaller -Force
            Write-Log "Cleaned up installer file: $tempInstaller"
        }
    }
    catch {
        Write-Log "ERROR during Todyl installation or cleanup: $_"
        throw
    }

    # ----------------------
    # Gather / Store Registry Values in CSV
    # ----------------------
    try {
        # Retrieve the updated registry values
        $regValues = Get-ItemProperty -Path $RegPath -Name $ValueUDID, $ValueEAUID -ErrorAction SilentlyContinue

        if ($regValues) {
            $currentUDID  = $regValues.$ValueUDID
            $currentEAUID = $regValues.$ValueEAUID

            Write-Log "Retrieved registry values: UDID=$currentUDID, ElasticAgentUDID=$currentEAUID"

            if ($existingEntry) {
                # Update existing row
                Write-Log "Updating CSV entry for $MachineName"
                $existingEntry.UDID             = $currentUDID
                $existingEntry.ElasticAgentUDID = $currentEAUID
            }
            else {
                # Create a new row in the CSV
                Write-Log "Creating new CSV entry for $MachineName"
                $newRow = New-Object PSObject -Property @{
                    MachineName       = $MachineName
                    UDID              = $currentUDID
                    ElasticAgentUDID  = $currentEAUID
                }
                $csvContent += $newRow
            }

            # Export the updated CSV
            Write-Log "Writing changes back to CSV..."
            $csvContent | Export-Csv -Path $CsvFilePath -NoTypeInformation -Force
        }
        else {
            Write-Log "No registry values found at $RegPath. Skipping CSV update."
        }
    }
    catch {
        Write-Log "ERROR while updating CSV: $_"
        throw
    }

    Write-Log "Todyl install process completed successfully for machine: $MachineName"
}
catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
    # Optionally exit with a non-zero code if you want to signal failure
    exit 1
}
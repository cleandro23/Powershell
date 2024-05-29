# Name        : ADCheckObjects.ps1
# Description : Check in AD all old stuff with no login
# Version     : 1.2.0
# Author      : Carlos Navarro, CRCNN
# Date        : 27/05/2024


# Import AD Module
Import-Module ActiveDirectory

# CSV Address to be save
$csvPath = "C:\Temp\InactiveObjects.csv"
$logPath = "C:\Temp\InactiveObjects.txt"

# Log Information
# Get the executor user 
$executingUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

# Log preparation
if (Test-Path $logPath) {
    Remove-Item $logPath
}
New-Item -Path $logPath -ItemType File

# Escribir información del usuario que ejecutó el script en el log
Add-Content -Path $logPath -Value "Script executed by: $executingUser"
Add-Content -Path $logPath -Value "Execution date: $(Get-Date)"
Add-Content -Path $logPath -Value ""

# Define how many years you wanna search
$inactivityDate = (Get-Date).AddYears(-10)

# Get user object with the defined "lastlogon"
$staleUsers = Get-ADUser -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
              Select-Object Name, SamAccountName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

# Get computer object with the defined "lastlogon"
$staleComputers = Get-ADComputer -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
                  Select-Object Name, SamAccountName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

#  Prepare results to export
$results = @()
$deletedObjects = @()

# Inactive users process
$staleUsers | ForEach-Object {
    $lastLogonDate = $_.LastLogonDate
    if ($lastLogonDate -eq [DateTime]::MinValue) {
        $lastLogonDate = "Never"
    }
    $results += [PSCustomObject]@{
        ObjectType = "User"
        Name = $_.Name
        SamAccountName = $_.SamAccountName
        LastLogonDate = $lastLogonDate
    }
}

# Remove user and register the action
Remove-ADObject -Identity $_.DistinguishedName -Confirm:$false
$deletedObjects += "User: $($_.Name), SamAccountName: $($_.SamAccountName), LastLogonDate: $lastLogonDate, DistinguishedName: $($_.DistinguishedName)"


# Inactive computer process
$staleComputers | ForEach-Object {
    $lastLogonDate = $_.LastLogonDate
    if ($lastLogonDate -eq [DateTime]::MinValue) {
        $lastLogonDate = "Never"
    }
    $results += [PSCustomObject]@{
        ObjectType = "Computer"
        Name = $_.Name
        SamAccountName = $_.SamAccountName
        LastLogonDate = $lastLogonDate
    }
}

#Remove computer or server objetc and register the action
#Remove-ADObject -Identity $_.DistinguishedName -Confirm:$false
#$deletedObjects += "Computer: $($_.Name), SamAccountName: $($_.SamAccountName), LastLogonDate: $lastLogonDate, DistinguishedName: $($_.DistinguishedName)"


# Export the results to CSV
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Removed object log
#$deletedObjects | Out-File -FilePath $logPath -Encoding UTF8

# Send mail
Send-MailMessage -from mail -to mail -Subject "Attached you will find the Inactive Objects" -Priority High -Body "Please check attached log file" -SmtpServer smtp.cpcorp.net -Attachments $csvPath


# Comfirmation of mail
Write-Output "Script completed. The results have been saved to $csvPath and sent by email."

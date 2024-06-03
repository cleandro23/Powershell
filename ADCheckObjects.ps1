# Name        : ADCheckObjects.ps1
# Description : Check in AD all old stuff with no login
# Version     : 1.3.0
# Author      : Carlos Navarro, CRCNN
# Date        : 27/05/2024


# Import AD Module
Import-Module ActiveDirectory

# CSV Address to be save
$testDate = Get-Date -date $(get-date) -format ddMMyyyy
$csvPath = "C:\Temp\InactiveObjects_$testDate.csv"
$logPath = "C:\Temp\InactiveObjects_$testDate.txt"


# Log Information
# Get the executor user 
$executingUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

# Preparar el log
if (Test-Path $logPath) {
    Remove-Item $logPath
}
New-Item -Path $logPath -ItemType File

# Escribir información del usuario que ejecutó el script en el log
Add-Content -Path $logPath -Value "Script ejecutado por: $executingUser"
Add-Content -Path $logPath -Value "Fecha de ejecución: $(Get-Date)"
Add-Content -Path $logPath -Value ""

# Obtener usuarios que no han iniciado sesión en los últimos 10 años
$staleUsers = Get-ADUser -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
              Select-Object Name, SamAccountName, DistinguishedName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

# Obtener computadoras que no han sido usadas en los últimos 10 años
$staleComputers = Get-ADComputer -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
                  Select-Object Name, SamAccountName, DistinguishedName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

# Preparar resultados para exportar
$results = @()
$deletedObjects = @()

# Credenciales para la eliminación
$credUser = "ADUser"  # Nombre de usuario para las credenciales de AD
$credPassword = ConvertTo-SecureString "ADPassword" -AsPlainText -Force  # Contraseña
$credential = New-Object System.Management.Automation.PSCredential($credUser, $credPassword)

# ScriptBlock para eliminar objetos
$deleteScriptBlock = {
    param ($userOrComputer)

    Import-Module ActiveDirectory

    foreach ($item in $userOrComputer) {
        $lastLogonDate = $item.LastLogonDate
        if ($lastLogonDate -eq [DateTime]::MinValue) {
            $lastLogonDate = "Never"
        }
        
        $objectType = if ($item.ObjectClass -eq 'user') { "User" } else { "Computer" }
        $results += [PSCustomObject]@{
            ObjectType = $objectType
            Name = $item.Name
            SamAccountName = $item.SamAccountName
            LastLogonDate = $lastLogonDate
        }

        # Eliminar el objeto y registrar el borrado
        Remove-ADObject -Identity $item.DistinguishedName -Confirm:$false
        $deletedObjects += "$objectType : $($item.Name), SamAccountName: $($item.SamAccountName), LastLogonDate: $lastLogonDate, DistinguishedName: $($item.DistinguishedName)"
    }

    return $deletedObjects
}

# Procesar y eliminar usuarios inactivos usando credenciales específicas
Invoke-Command -Credential $credential -ScriptBlock $deleteScriptBlock -ArgumentList ($staleUsers)

# Procesar y eliminar computadoras inactivas usando credenciales específicas
Invoke-Command -Credential $credential -ScriptBlock $deleteScriptBlock -ArgumentList ($staleComputers)

# Exportar los resultados a un archivo CSV
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Guardar el log de los objetos borrados
$deletedObjects | Out-File -FilePath $logPath -Encoding UTF8 -Append

# Send mail
Send-MailMessage -from crcnn@coloplast.com -to crcnn@coloplast.com -Subject "Attached you will find the Inactive Objects" -Priority High -Body "Please check attached log file, this is a test from $(Get-Date)" -SmtpServer smtp.cpcorp.net -Attachments $csvPath


# Comfirmation of mail
Write-Output "Script completed. The results have been saved to $csvPath and sent by email."

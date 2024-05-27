# Name        : ADCheckObjects.ps1
# Description : Check in AD all old stuff with no login
# Version     : 1.0.0
# Author      : Carlos Navarro, CRCNN
# Date        : 27/05/2027


# Importar el módulo Active Directory
Import-Module ActiveDirectory

# Definir la fecha límite de inactividad
$inactivityDate = (Get-Date).AddYears(-5)

# Obtener usuarios que no han iniciado sesión en los últimos 10 años
$staleUsers = Get-ADUser -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
              Select-Object Name, SamAccountName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

# Obtener computadoras que no han sido usadas en los últimos 10 años
$staleComputers = Get-ADComputer -Filter {LastLogonTimestamp -lt $inactivityDate} -Properties LastLogonTimestamp | 
                  Select-Object Name, SamAccountName, LastLogonTimestamp, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

# Preparar resultados para exportar
$results = @()

# Procesar usuarios inactivos
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

# Procesar computadoras inactivas
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

# Exportar los resultados a un archivo CSV
$results | Export-Csv -Path "C:\Temp\objetos_inactivos.csv" -NoTypeInformation -Encoding UTF8

# Confirmar que el script se completó
Write-Output "Script completado. Los resultados se han guardado en C:\Temp\objetos_inactivos.csv"

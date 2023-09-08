
function CreateDhcpDump{
  [CmdletBinding()]
  Param([string]$dateFolder)

  $dumpPath = Join-Path "\\LTCRSJO00182\c$\dumpf" $dateFolder
  mkdir $dumpPath
}


function Export-DhcpConfigurations {
  Param([string]$dateFolder, [string[]]$exportConfigList)

  foreach ($exportConfig in $exportConfigList) {
      Write-Host "Exporting DHCP configuration for $exportConfig..."
      $filePath = Join-Path "\\LTCRSJO00182\C$\dumpf\$dateFolder" "$exportConfig.xml"
      Export-DhcpServer -ErrorAction 'SilentlyContinue' -ComputerName $exportConfig -File $filePath -Force -Leases
  }
}

# Main script
$dateFolder = Get-Date -Format "yyyyMMdd"



# Import AD Module
 Import-Module ActiveDirectory

 # Realiza una consulta en Active Directory para obtener los servidores
 $servers = Get-ADComputer -Filter {Name -like "*GI*"} | Select-Object -ExpandProperty Name
 
 # Verifica si se encontraron servidores
 if ($servers.Count -gt 0) {
     # Guarda la lista de servidores en un archivo de texto
     $servers | Out-File -FilePath "C:\dumpf\servers.txt"
     Write-Host "Se ha guardado la lista de servidores en el archivo servers.txt"
 } else {
     Write-Host "No se encontraron servidores en Active Directory."
 }
 


#ruta del archivo
$serverFile =  "C:\dumpf\servers.txt"

# Leer contenido del archivo
$fileContent = Get-Content $serverFile

# Crear lista de archivos 
$serverList = $fileContent | ForEach-Object { $_.Trim() }

$exportConfigList = @(
  $serverList
)

CreateDhcpDump $dateFolder
importServers $servers
Export-DhcpConfigurations -dateFolder $dateFolder -exportConfigList $exportConfigList
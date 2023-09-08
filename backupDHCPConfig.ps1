
function CreateDhcpDump{
  [CmdletBinding()]
  Param([string]$dateFolder)

  $dumpPath = Join-Path "\\GICPSRV02\D$\PLKRGO_GI_DHCP_dump_test\" $dateFolder
  #mkdir $dumpPath
}


function Export-DhcpConfigurations {
  Param([string]$dateFolder, [string[]]$exportConfigList)

  foreach ($exportConfig in $exportConfigList) {
      Write-Host "Exporting DHCP configuration for $exportConfig..."
      $filePath = Join-Path "\\GICPSRV02\D$\PLKRGO_GI_DHCP_dump_test\dumpf\$dateFolder" "$exportConfig.xml"
      Export-DhcpServer -ErrorAction 'SilentlyContinue' -ComputerName $exportConfig -File $filePath -Force -Leases
  }
}

# Main script
$dateFolder = Get-Date -Format "yyyyMMdd"

# Import AD Module
 Import-Module ActiveDirectory

 # Query to find the servers due to parameters, for this case, I'll use GI in terms to find DHCP
 $servers = Get-ADComputer -Filter {Name -like "*GI*"} | Select-Object -ExpandProperty Name
 
 # This loop will 
 if ($servers.Count -gt 0) {
     # Save servers information to the specific folder
     $servers | Out-File -FilePath "C:\dumpf\servers.txt"
     Write-Host "Server list has been saved in the following address \\GICPSRV02\D$\PLKRGO_GI_DHCP_dump_test\servers.txt"
 } else {
     Write-Host "No servers were found"
 }
 


#File addres
$serverFile =  "D:PLKRGO_GI_DHCP_dump_test\servers.txt\servers.txt"

# Read content of the TXT File
$fileContent = Get-Content $serverFile

# Server list creation using the TXT file 
$serverList = $fileContent | ForEach-Object { $_.Trim() }

#Export the .xml files, using the information contained in the TXT file
$exportConfigList = @(
  $serverList
)

CreateDhcpDump $dateFolder
importServers $servers
Export-DhcpConfigurations -dateFolder $dateFolder -exportConfigList $exportConfigList
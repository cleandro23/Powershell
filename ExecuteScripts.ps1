# Name        : ExecuteScripts.ps1
# Description : Execute .ps1 file in folder and subfolders
# Version     : 1.0.0
# Author      : Carlos Navarro, CRCNN
# Date        : 21/09/23


# Ruta de la carpeta principal que contiene los archivos PowerShell a ejecutar
$folderPath = "C:\Colo\"

# Función recursiva para buscar y ejecutar archivos .ps1
function Invoke-ScriptFiles {
    param (
        [string]$folderPath
    )

    # Verificar si la carpeta existe
    if (Test-Path -Path $folderPath -PathType Container) {
        # Obtener todos los archivos .ps1 en la carpeta actual
        $scriptFiles = Get-ChildItem -Path $folderPath -Filter *.ps1 -File

        # Verificar si se encontraron archivos .ps1 en la carpeta actual
        if ($scriptFiles.Count -gt 0) {
            foreach ($scriptFile in $scriptFiles) {
                # Ejecutar cada archivo .ps1
                Write-Host "Ejecutando archivo: $($scriptFile.FullName)"
                try {
                    # Ejecutar el script
                    Invoke-Expression -Command $scriptFile.FullName
                } catch {
                    Write-Error "Error al ejecutar el archivo: $($scriptFile.FullName)"
                    Write-Error $_.Exception.Message
                }
            }
        }
        
        # Obtener todas las subcarpetas
        $subfolders = Get-ChildItem -Path $folderPath -Directory

        # Recorrer las subcarpetas y llamar a la función recursivamente
        foreach ($subfolder in $subfolders) {
            Invoke-ScriptFiles -folderPath $subfolder.FullName
        }
    } else {
        Write-Warning "La carpeta $folderPath no existe."
    }
}

# Llamar a la función para iniciar la búsqueda y ejecución
Invoke-ScriptFiles -folderPath $folderPath

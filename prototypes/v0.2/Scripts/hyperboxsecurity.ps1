<#
Author: Silas Burkhard
Date: 12.02.2026
Version: 0.2
Description:
Programm zum finden und patchen von
CLIXML Schwachstellen
#>

Write-Host "[!] Starting Hyperbox Security Utility..."
Write-Host "[!] Checking for vulnerable PSFramwork Version..."

if ((Get-Module -Name PSFramwork).Version -gt "1.12.345" -or $null -eq (Get-Module -Name PSFramwork)) {
    Write-Host "[+] PSFramework is patched or isnt installed"
} else {
    Write-Host "[-] A vulnerable Version of PSFramework is installed"
    Write-Host "[!] Atempting to update PSFramework..."

    Update-Module -Name PSFramework -Force

    Write-Host "[+] Updated PSFramework"

}


Write-Host "[!] Atempting to patch Registry.format.ps1xml..."

Get-Content -Path .\Scripts\sampleRegistryFormat.txt | Set-Content -Path "C:\Windows\System32\WindowsPowerShell\v1.0\Registry.format.ps1xml"

Write-Host "[+] Patched"



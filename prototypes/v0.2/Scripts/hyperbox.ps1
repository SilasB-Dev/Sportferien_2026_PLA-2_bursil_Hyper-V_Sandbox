<#
Author: Silas Burkhard
Date: 18.02.2026
Version: 0.2
Description:
Prototyp für Hyperbox.
Grundlegende Funktionen wie erstellen von VM,
kopieren des Files, Löschen der VM
#>
param (
    [Parameter()]
    [string]
    $suspiciousFilePath
)
$workingdir = "C:\Users\silas\Documents\010_ZLI\Sportferienprojekt\prototypes\v0.2" # Or $workingdir = pwd, $workingdir = $workingdir.Path
Set-Location $workingdir


if (-not (Test-Path -Path $suspiciousFilePath)) {
    Write-Host "Error: Target File does not exist!"
    Pause
    Exit
}

$config = Get-Content .\Scripts\hyperbox.config | ConvertFrom-StringData

Write-Host "Target File: $suspiciousFilePath"
Write-Host "Time: " + (Get-Date -Format "HH:mm:ss")




$suspiciousFilePath = $suspiciousFilePath.Replace("/","\")
$filename = $suspiciousFilePath.Substring($suspiciousFilePath.LastIndexOf("\")+1)
$MasterVHDPath = "$($config.VMPath)\Masterv0.2.vhdx"
$ChildrenVHDPath = "$($config.VMPath)\Childv0.2.vhdx"
$destPath = "C:\Users\admin\Desktop\Files\$filename" 
$vmconf = $config.VMconfigPath



if ($config.Isolation) {
    $SwitchName = "Isolation"
} else { $SwitchName = "Default Switch" }

$ConfirmPreference = 'None'

$username = "admin"
$password = "admin"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

#### Stolen Code

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$suspiciousFilePath`"" -Verb RunAs
    exit
}
# Script continues with admin privileges
Write-Host "Running as Administrator"

#### End Stolen Code




if (Test-Path -Path $ChildrenVHDPath) {
    Remove-Item -Path $ChildrenVHDPath
    Write-Host "Removed Old VHD"
}

Write-Host "Copying VHD..."
New-VHD -ParentPath $MasterVHDPath -Path $ChildrenVHDPath -Differencing | Out-Null
Write-Host "Done"


$VMName = "Childv0.2"
$VM = @{
Name = $VMName
MemoryStartupBytes = 4Gb
Generation = 2
VHDPath = $ChildrenVHDPath
BootDevice = "VHD"
Path = $vmconf
SwitchName = $SwitchName
}
New-VM @VM | Out-Null
$VM = Get-VM -Name $VMName
#Enable-VMTPM -VMName $VMName
Set-VMProcessor $VMName -Count 2

Write-Host "Created new VM"


Start-VM $VMName
vmconnect.exe localhost $VMName
Write-Host "Started VM"

do {
    Start-Sleep -Seconds 1
} until ($VM.state -eq "Running") # (Get-VM | Select-Object -ExpandProperty NetworkAdapters | Select-Object -exp Status)
Start-Sleep -Seconds 10
Write-Host "Booted up"
$PSSession = New-PSSession -VMName $VMName -Credential ($credential)
Copy-Item -ToSession $PSSession -Path $suspiciousFilePath -Destination $destPath

Write-Host "Time: " + (Get-Date -Format "HH:mm:ss")

if ($config.AutoExec -eq "True") {
    $cmd = {
        $futureTime = (Get-Date).AddMinutes(1).ToString("HH:mm")
        schtasks /create /tn "exec" /tr $Using:destPath /sc once /st $futureTime /ru "$env:USERNAME" /rp $password /rl highest /f
        schtasks /run /tn "exec"
    }
    Invoke-Command -VMName $VMName -Command $cmd -Credential ($credential) -AsJob
}




###############
#   Cleanup   #
###############
Wait-Process -Name "vmconnect"
Stop-VM $VMName -TurnOff 
Remove-VM $VMName -Force
Remove-Item "$vmconf\$VMName" -Recurse

Write-Host "Cleaned up"


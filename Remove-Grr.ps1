<#
.SYNOPSIS
    Removes all traces of GRR from the specified list of clients.

.DESCRIPTION
    Kills all running GRR processes, and then removes the service,
    registry componenets and files for the client.

.PARAMETER Credential
    PSCredential object used to connect to all the given targets.

.OUTPUTS
    None.

.NOTES
    Name: Remove-Grr.ps1
    Author: Caleb Stewart
    DateCreated: 11FEB2019

.LINK
    https://github.com/Caleb1994/Remove-Grr

.EXAMPLE
    PS C:\> echo "172.16.8.10" | Remove-Grr

.EXAMPLE
    PS C:\> Remove-Grr -Target 192.168.10.10,192.168.10.11,192.168.10.231 -Credential $credentials
#>
param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][IPAddress[]]$Target,
    [PSCredential]$Credential = $(Get-Credential)
)

ForEach( $t in $Target ) {
    # Run on remote
    Invoke-Command -ComputerName $t -Credential $Credential -ArgumentList @($t) -ScriptBlock {
        param($t)

        # Kill the GRR Monitor Process(es)
        Get-Process -Name "GRR*" | ForEach-Object {
            Write-Host "$($t): killing grr process $($_.Name) w/ PID $($_.Id)"
            Kill -Id $_.Id -Force
        }

        # Remove GRR Registry Key
        Write-Host "$($t): removing registry entry"
        Remove-Item HKLM:\SOFTWARE\GRR -Force -Recurse -ErrorAction SilentlyContinue

        # Remove GRR Service
        Write-Host "$($t): removing grr service"
        sc.exe delete "grr monitor"
        
        # Remove all GRR Files
        Write-Host "$($t): enumerating grr files"
        Get-ChildItem C:\ -Force -Recurse -ErrorAction SilentlyContinue -Include "*GRR*" | ForEach-Object {
            Write-Host "$($t): removing $($_.FullName)"
            Remove-Item -Recurse -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

}

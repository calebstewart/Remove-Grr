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
            Write-Host "killing grr process $($_.Name) w/ PID $($_.Id)"
            Kill -Id $_.Id -Force
        }

        # Remove GRR Registry Key
        Write-Host "$($t): removing registry entry"
        Remove-Item HKLM:\SOFTWARE\GRR -Force -Recurse -ErrorAction SilentlyContinue
        
        # Remove all GRR Files
        Write-Host "$($t): enumerating grr files"
        Get-ChildItem C:\ -Force -Recurse -ErrorAction SilentlyContinue -Include "*GRR*" | ForEach-Object {
            Write-Host "$($t): removing $($_.FullName)"
            Remove-Item -Recurse -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }

}

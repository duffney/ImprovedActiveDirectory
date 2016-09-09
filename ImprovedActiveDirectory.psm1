try {
 Import-Module ActiveDirectory   
}
catch [System.Management.Automation.ParameterBindingException] {
    Write-Error -Message 'ActiveDirectory Module not found' -ErrorAction Stop
}


. $PSScriptRoot\Classes\IADGroup.ps1
. $PSScriptRoot\Functions\Get-IADGroupMember.ps1
. $PSScriptRoot\Functions\Disable-ADComputer.ps1
. $PSScriptRoot\Functions\Disable-ADUser.ps1


Export-ModuleMember Get-IADGroupMember
Export-ModuleMember Disable-ADComputer
Export-ModuleMember Disable-ADUser
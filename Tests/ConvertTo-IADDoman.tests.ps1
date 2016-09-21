# Get the path the script is executing from
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# If the module is already in memory, remove it
Get-Module ImprovedActiveDirectory | Remove-Module -Force

# Import the module from the local path, not from the users Documents folder
Import-Module $PSScriptRoot\..\ImprovedActiveDirectory.psm1 -Force

Describe 'ConvertTo-IADDomain Tests' {

    It 'module should be loaded' {
        "$PSScriptRoot\..\ImprovedActiveDirectory.psm1" | should exist
    }

    It 'outputs valid domain name' {
        ConvertTo-IADDomain -distinguishedname 'CN=Administrator,CN=Users,DC=wef,DC=com','CN=Administrator,CN=Users,DC=wef,DC=com' | should match '[a-z]+\.[a-z]+\.[a-z]+|[a-z]+\.[a-z]+'
    }

    It 'reject invalid distinguishedname' {
        ConvertTo-IADDomain -distinguishedname 'CN=Administrator,CN=Users,DC=wefasdfasdfasdfadsfasdfasdf,DC=com' | should throw
    }
}
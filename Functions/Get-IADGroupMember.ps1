function Get-IADGroupMember
{
<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER Identity
.EXAMPLE
.EXAMPLE
#>       
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Identity,
        [string]$Server,
        [switch]$Recursive
    )

    Begin
    {
        $splat = @{
            Identity = $Identity
        }

        if ($PSBoundParameters.ContainsKey('Server')){
            $splat.Add('Server',$Server)
        }          

    }
    Process
    {
        if ($Recursive){
            [IADGroup]::new($splat).NestedMembers()
        } else {
            [IADGroup]::new($splat).DirectMembers()
        }
    }
    End
    {
    }
}
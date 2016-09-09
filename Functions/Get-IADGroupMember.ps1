function Get-IADGroupMember
{
<#
.SYNOPSIS
    Gets the members of an Active Directory group.
.DESCRIPTION
    Get-IADGroupMember gets the members of an Active Directory group. Members include users, groups, computers and foreignSecurityPrincipal objects.
    It improves upon the Get-ADGroup cmdlet by supporting cross forest direct and nested memberships as well as the ability to report back foreignSecurityPrincipal
    or "broken SIDS" objects.
.PARAMETER Identity
    Specifies an Active Directory object by GUID, DistinguishedName, objectSID, or SamAccountName.
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Recursive
    Specifies that the cmdlet report all nested groups and group memberships.
.EXAMPLE
    Get-IADGroupMember -Identity Group1
.EXAMPLE
    Get-IADGroupMember -Identity Group1 -Server Globomantics.com
.EXAMPLE
    Get-IADGroupMember -Identity Group1 -Server Globomantics.com -Recursive    
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
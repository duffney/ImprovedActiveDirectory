function Get-IADUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]$Identity
    )

    Begin
    {
    }
    Process {

        foreach ($User in $Identity) {
            Start-RSJob -Name $User -Scriptblock {Get-ADUser -Identity $Using:User} | Out-Null
        }        
    }
    End
    {
        Get-RSJob | Receive-RSJob
        #Get-RSjob | Remove-RSJob
    }
}
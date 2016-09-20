function ConvertTo-IADDomain
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]$distinguishedname
    )

    Begin
    {
    }
    Process {

        foreach ($User in $distinguishedname) {
            ((($User -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")
        }        
    }
    End
    {

    }
}
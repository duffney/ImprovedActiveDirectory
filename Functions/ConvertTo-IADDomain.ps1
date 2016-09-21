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

        foreach ($DN in $distinguishedname) {
            if ($DN -match 'CN=[^"/\\\[\]:;|=,+\*\?<>*]{1,64},(CN=[^"/\\\[\]:;|=,+\*\?<>*]{1,64})?,(DC=[^"/\\:*?<>|]{1,15})?,DC=[^"/\\:*?<>|]{1,15}') {
                ((($DN -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")
            } else {
                Write-Error -message "$DN is not a valid distinguishedname"
            }
        }        
    }
    End
    {

    }
}
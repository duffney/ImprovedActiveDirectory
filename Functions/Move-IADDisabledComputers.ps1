Function Move-IADDisabledComputers{
<#
.SYNOPSIS
    Moves all disabled computer accounts found inside a domain to the specified OU for disabled computers.
.DESCRIPTION
    Move-IADDisabledComputers queries the specified domain, gathers all disabled computer accounts, and moves them to the Active Directory path provided by operator. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER DisabledOU
    Specifies the target organizational unit to move the objects to. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Move-IADDisabledComputers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -Confirm

    Queries the fabrikom.com domain after prompting for credentials to use. Will ask for confirmation before moving to the Disabled OU specified.
.EXAMPLE
    Move-IADDisabledComputers -Credential $Creds -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -WhatIf

    Queries the currently joined domain using credentials stored inside the $Creds PSCredential object and returns what will happen, but does not take action (-WhatIf).    
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$DisabledOU,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()
    
    #Gather the computer objects that are disabled and not inside the $DisabledOU
    $DisabledComputers = Get-ADComputer -Server $Server -Filter {enabled -eq $false} | Where-Object {$_.distinguishedname -notlike "*$DisabledOU*"}


    #Move each computer account to the $DisabledOU
    if($DisabledComputers){
        foreach($Computer in $DisabledComputers){

           Try{ 
                Move-ADObject -Server $Server -Identity $Computer -TargetPath $DisabledOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
                $A = [pscustomobject]@{"Computer"=$Computer.dnshostname;
                                       "Status"="Successful"}
           }

           Catch{
                $A = [pscustomobject]@{"Computer"=$Computer.dnshostname;
                                       "Status"="Failure";
                                       "Error"=$Error[0]}
           }

           $ReturnList += $A
        }
    }

    else{$ReturnList = "No computers found"}

    Return $ReturnList

}
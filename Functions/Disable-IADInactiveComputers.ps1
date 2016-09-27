Function Disable-IADInactiveComputers{
<#
.SYNOPSIS
    Moves all inactive computer accounts found inside a domain to the specified OU for disabled computers. 
.DESCRIPTION
    Move-IADDisabledComputers queries the specified domain, gathers all inactive computer accounts, and moves them to the Active Directory path provided by operator. Inactivity is determined using the lastlogontimestamp of the computer. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
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
          [int]$DaysInactive,
          [string[]]$ExclusionList,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()
    $FilterExclusionList = ""
    $CurrentDate = Get-Date

    #Build the $FilterString from the $ExclusionList
    foreach($Account in $ExclusionList){$FilterExclusionList += "-and name -notlike `"$Account`""}
    $FilterString = "lastlogontimestamp -gt $time $FilterExclusionList" 

    #Gather the inactive computer accounts
    $InactiveComputers = Get-ADComputer -Server $Server -Filter $FilterString -Properties lastlogontimestamp,description

    #Disable, set, and move each computer account to the specified $DisabledOU
    if($InactiveComputers){  
        foreach($Computer in $InactiveComputers){

            Try{
                $Description = $($Computer.description) + " / " + "Disabled on $CurrentDate due to $Daysinactive inactive"
                Disable-ADAccount -Identity $Computer -Server $Server -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
                Set-ADObject -Identity $Computer -Server $Server -Credential $Credential -Description $Description -Confirm:$Confirm -Whatif:$WhatIf -Verbose 
                Move-ADObject -Identity $Computer -Server $Server -Credential $Credential -TargetPath $DisabledOU -Confirm:$Confirm -Whatif:$WhatIf -Verbose

                $A = [pscustomobject]@{"Computer"=$Computer.dnshostname;
                                       "Status"="Successful";
                                       "LastLogin"=$Computer.lastlogontimestamp}
            }

            Catch{
                $A = [pscustomobject]@{"Computer"=$Computer.dnshostname;
                                       "Status"="Failure";
                                       "Error"=$Error[0];
                                       "LastLogin"=$Computer.lastlogontimestamp}
            }

            $ReturnList += $A 

        }
    }

    else{$ReturnList = "No inactive computers found"}

    return $ReturnList
}
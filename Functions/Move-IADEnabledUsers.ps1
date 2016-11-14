Function Move-IADEnabledUsers{
<#
.SYNOPSIS
    Moves all enabled user accounts found inside the specified disabled OU for the domain to the specified target OU
.DESCRIPTION
    Move-IADEnabledUsers queries the specified domain, gathers all enabled user accounts inside the specified Disabled OU, and moves them to the Active Directory path provided by operator. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER DisabledOU
    Specifies the disabled objects organizational unit to query. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER TargetOU
    Specifies the User organizational unit to move enabled users into. This parameter accepts the distinguishedname of the OU as a string. 
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Move-IADEnabledUsers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -TargetOU "OU=UserAccounts",DC=fabrikom,DC=com" 

    Queries the fabrikom.com domain after prompting for credentials to use. Moves any returned accounts to the respective target OU.
.EXAMPLE
    Move-IADEnabledUsers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -TargetOU "OU=UserAccounts",DC=fabrikom,DC=com"  -WhatIf

    Queries the fabrikom.com domain after prompting for credentials to use. Returns what will happen, but does not take action (-WhatIf).    
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$DisabledOU,
          [string]$TargetOU,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()
    
    #Gather the user objects that are enabled and inside the $DisabledOU
    $EnabledUsers = Get-ADUser -Server $Server -Filter {enabled -eq $true} | Where-Object {$_.distinguishedname -like "*$DisabledOU*"}

    #Move each user account to the $TargetOU
    if($EnabledUsers){
        foreach($User in $EnabledUsers){
            
           
           Try{ 
                Move-ADObject -Server $Server -Identity $CUser -TargetPath $TargetOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
                $A = [pscustomobject]@{"User"=$User.samaccountname;
                                       "Status"="Successful"}
           }

           Catch{
                $A = [pscustomobject]@{"User"=$User.samaccountname;
                                       "Status"="Failure";
                                       "Error"=$Error[0]}
           }

           $ReturnList += $A
        }
    }

    else{$ReturnList = "No users found"}

    Return $ReturnList

}
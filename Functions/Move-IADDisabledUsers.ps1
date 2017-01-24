Function Move-IADDisabledUsers{
<#
.SYNOPSIS
    Moves all disabled user accounts found inside a domain to the specified OU for disabled users.
.DESCRIPTION
    Move-IADDisabledUsers queries the specified domain, gathers all disabled user accounts, and moves them to the Active Directory path provided by operator. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER DisabledOU
    Specifies the target organizational unit to move the objects to. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER ExclusionList
    Specify which accounts if any need to be excluded from the move. If you have disabled system or service accounts for example that must remain in their current OU this will exclude them. The parameter accepts a string array of samaccountnames. 
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Move-IADDisabledUsers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -ExclusionList test1,test2,test3 -Confirm

    Queries the fabrikom.com domain after prompting for credentials to use. Will ask for confirmation before moving to the Disabled OU specified and excludes user accounts test1, test2, and test3.
.EXAMPLE
    Move-IADDisabledUsers -Credential $Creds -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -WhatIf

    Queries the currently joined domain using credentials stored inside the $Creds PSCredential object and returns what will happen, but does not take action (-WhatIf).    
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$DisabledOU,
          [string[]]$ExclusionList,
          [switch]$Confirm,
          [switch]$WhatIf)

    $FilterExclusionList = ""
    $ReturnList = @()

    #Build the string for the filter exclusion list
    foreach($Account in $ExclusionList){$FilterExclusionList += " -and samaccountname -notlike `"$Account`""}
    $FilterString = "enabled -eq `$false -and samaccountname -notlike `"krbtgt`" -and samaccountname -notlike `"Guest`" -and samaccountname -notlike `"DefaultAccount`"$FilterExclusionList" 
    
    #Gather the user objects that are disabled and not inside the $DisabledOU or $ExclusionList
    $DisabledUsers = Get-ADUser -Server $Server -Filter $FilterString | Where-Object {$_.distinguishedname -notlike "*$DisabledOU*"}


    #Move each user account to the $DisabledOU
    if($DisabledUsers){
        foreach($User in $DisabledUsers){

           Try{ 
                Move-ADObject -Server $Server -Identity $User -TargetPath $DisabledOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
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
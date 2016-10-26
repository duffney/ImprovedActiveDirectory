Function Move-IADEnabledComputers{
<#
.SYNOPSIS
    Moves all enabled computer accounts found inside the specified disabled OU for the domain to the specified target OU
.DESCRIPTION
    Move-IADEnabledComputers queries the specified domain, gathers all enabled computer accounts inside the specified Disabled OU, and moves them to the Active Directory paths provided by operator. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER DisabledOU
    Specifies the disabled objects organizational unit to query. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER TargetDesktopOU
    Specifies the Desktop organizational unit to move workstations into. This parameter accepts the distinguishedname of the OU as a string. (Windows 7*, 8*, 10*, XP*)
.PARAMETER TargetServerOU
    Specifies the Server organizational unit to move servers into. This parameter accepts the distinguishedname of the OU as a string. (Windows Server*)
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Move-IADEnabledComputers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -TargetDesktopOU "OU=Workstations",DC=fabrikom,DC=com" -TargetServerOU "OU=Server,DC=fabrikom,DC=com"

    Queries the fabrikom.com domain after prompting for credentials to use. Moves any returned accounts to their respective target OUs.
.EXAMPLE
    Move-IADEnabledComputers -Server fabrikom.com -Credential (get-credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -TargetDesktopOU "OU=Workstations",DC=fabrikom,DC=com" -TargetServerOU "OU=Server,DC=fabrikom,DC=com" -WhatIf

    Queries the fabrikom.com domain after prompting for credentials to use. Returns what will happen, but does not take action (-WhatIf).    
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$DisabledOU,
          [string]$TargetDesktopOU,
          [string]$TargetServerOU,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()
    
    if(!$TargetDesktopOU -and !$TargetServerOU){throw "You must specify either a Target Destop or Server OU"}

    #Gather the computer objects that are enabled and inside the $DisabledOU
    $EnabledComputers = Get-ADComputer -Server $Server -Filter {enabled -eq $true} -properties operatingsystem,dnshostname | Where-Object {$_.distinguishedname -like "*$DisabledOU*"}

    #Move each computer account to the $TargetPath
    if($EnabledComputers){
        foreach($Computer in $EnabledComputers){
            
           #If Desktop use TargetDesktopOU
           if($Computer.operatingsystem -like "Windows 7*" -or $Computer.operatingsystem -like "Windows 8*" `
            -or $Computer.operatingsystem -like "Windows XP*" -or $Computer.operatingsystem -like "Windows 10*"){$TargetPath = $TargetDesktopOU}

           #If Server use TargetServerOU
           if($Computer.operatingsystem -like "Windows Server*"){$TargetPath = $TargetServerOU}

           Try{ 
                Move-ADObject -Server $Server -Identity $Computer -TargetPath $TargetPath -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
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
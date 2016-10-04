Function Disable-IADInactiveUsers{
<#
.SYNOPSIS
    Disables all inactive user accounts found inside a domain to the specified OU for disabled users. 
.DESCRIPTION
    Disable-IADInactiveUsers queries the specified domain, gathers all inactive user accounts, and moves them to the Active Directory path provided by operator. Inactivity is determined using the lastlogontimestamp of the user. PLEASE NOTE, it is suggesed you first run the cmdlet with -WhatIf so you are aware of any unwanted accounts targeted like service or system accounts. Add any exceptions to the exclusion list and run again using -WhatIf to test they are truly excluded. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER DisabledOU
    Specifies the target organizational unit to move the objects to. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER DaysInactive
    Specifies the amount of days of inactivity to target. Accepts an integer for input and checks against the lastlogontimestamp of the user account.
.PARAMETER ExclusionList
    Specifies what usernames to exclude from the command. Input the samaccountname property of a user account and it will leave it out of the query. Accepts string array input for multiple usernames. 
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Disable-IADInactiveComputers -Server fabrikom.com -Credential (Get-Credential) -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -DaysInactive 90 -WhatIf -IncludeServers

    Queries the fabrikom.com domain after prompting for credentials to use. Includes both desktop and server computer objects that have not logged on for 90 days. Returns what will happen, but does not take action (-WhatIf).  
.EXAMPLE
    Disable-IADInactiveComputers -Server fabrikom.com -Credential $Creds -DisabledOU "OU=Disabled,DC=fabrikom,DC=com" -DaysInactive 180

    Queries the currently joined domain using credentials stored inside the $Creds PSCredential object. Queries and disables all desktop computers that have not logged on for 180 days.  
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$DisabledOU,
          [Parameter(Mandatory=$true)]
          [int]$DaysInactive,
          [string[]]$ExclusionList,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()
    $FilterExclusionList = ""

    #Grab current date for description and set the $DaysInactive as [datetime] data type for use with lastlogontimestamp
    $CurrentDate = Get-Date -UFormat %D
    $InactiveDate = ((Get-Date).AddDays(-$DaysInactive))

    #Build the string for the filter exclusion list
    foreach($Account in $ExclusionList){$FilterExclusionList += "-and samaccountname -notlike `"$Account`""}
    $FilterString = "enabled -eq `$true -and samaccountname -notlike `"krbtgt`" -and samaccountname -notlike `"Guest`" -and samaccountname -notlike `"DefaultAccount`" $FilterExclusionList" 
    
    #Gather the user objects that are disabled and not inside the $DisabledOU or $ExclusionList
    $DisabledUsers = Get-ADUser -Server $Server -Filter $FilterString -Properties lastlogontimestamp,description | Where-Object {$_.lastlogontimestamp -lt $($InactiveDate.ToFileTime())}

    #Disable, set, and move each user account
    if($DisabledUsers){
        foreach($User in $DisabledUsers){

           Try{ 
                $Description = $($User.description) + " / " + "Disabled on $CurrentDate due to $Daysinactive days inactive"
                Disable-ADAccount -Server $Server -Identity $User -Credential $Credential -Confirm:$Confirm -WhatIf:$WhatIf -Verbose
                Set-ADObject -Server $Server -Identity $User -Credential $Credential -Description $Description -Confirm:$Confirm -WhatIf:$WhatIf -Verbose
                Move-ADObject -Server $Server -Identity $User -TargetPath $DisabledOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
                $A = [pscustomobject]@{"User"=$User.samaccountname;
                                       "LastLogin"=$([datetime]::FromFileTime($User.Lastlogontimestamp));
                                       "Status"="Successful"}
           }

           Catch{
                $A = [pscustomobject]@{"User"=$User.samaccountname;
                                       "Status"="Failure";
                                       "LastLogin"=$([datetime]::FromFileTime($User.Lastlogontimestamp));
                                       "Error"=$Error[0]}
           }

           $ReturnList += $A
        }
    }

    else{$ReturnList = "No users found"}

    Return $ReturnList

}

#Include logic for never logged in but expired ? moloneyl             12/31/1600 6:00:00 PM  Successful
#maybe if -IncludeNeverLoggedIn check the create or modify date instead. Otherwise by default leave out these accounts
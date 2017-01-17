Function Add-IADOUUsersToGroups{
<#
.SYNOPSIS
    Adds user accounts found inside an Active Directory OU to specified groups. 
.DESCRIPTION
    Add-IADOUUsersToGroups queries the specified OU, gathers all enabled user accounts, and adds them to the specified groups. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to modify the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER TargetOU
    Specifies the target organizational unit containing the users you want to add. This parameter accepts the distinguishedname of the OU as a string.
.PARAMETER Groups
    Specifies the group or groups to add the users to. This parameter accepts a string array of samaccountnames. 
.PARAMETER ExclusionList
    Specify which accounts if any need to be excluded from the move. The parameter accepts a string array of samaccountnames. 
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before modifying each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Add-IADOUUsersToGroups -Server fabrikom.com -Credential (get-credential) -TargetOU "OU=UserAccounts,DC=fabrikom,DC=com" -Groups Group1,Group2 -ExclusionList test1,test2,test3 -Confirm

    Queries the fabrikom.com domain after prompting for credentials to use. Will ask for confirmation before adding users to Group1 and Group2, and excludes user accounts test1, test2, and test3.
.EXAMPLE
    Add-IADOUUsersToGroups -Credential $Creds -DisabledOU -Server fabrikom.com -TargetOU "OU=UserAccounts,DC=fabrikom,DC=com" -Groups Group -WhatIf

    Queries the fabrikom.com domain using credentials stored inside the $Creds PSCredential object and returns what will happen, but does not take action (-WhatIf).
.EXAMPLE
    $A = Add-IADOUUsersToGroups -Server fabrikom.com -Credential (get-credential) -TargetOU "OU=UserAccounts,DC=fabrikom,DC=com" -Groups Group1,Group2 -ExclusionList test1,test2,test3 
    $A | where Status -like "Failure"

    Displays errors encountered if you receive a failure when adding users to groups.    
#>       
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]
          [string]$Server,
          [Parameter(Mandatory=$true)]
          [System.Management.Automation.PSCredential]$Credential,
          [Parameter(Mandatory=$true)]
          [string]$TargetOU,
          [Parameter(Mandatory=$true)]
          [string[]]$Groups,
          [string[]]$ExclusionList,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()

    #Verify OU
    if((Get-ADOrganizationalUnit -Server $Server -filter{distinguishedname -like $TargetOU}) -eq $null){throw "$TargetOU not found in $Server domain"}
    

    #Build the string for the filter exclusion list
    if($ExclusionList){
        foreach($Account in $ExclusionList){
            if(!$FilterExclusionList){$FilterExclusionList += "enabled -eq `$true -and samaccountname -notlike `"$Account`""}
            else{$FilterExclusionList += " -and samaccountname -notlike `"$Account`""}
        }
    }

    else{$FilterExclusionList = "enabled -eq `$true"}

   
    #Gather the user objects inside the $TargetOU and exclude $FilterExclusionList 
    $OUUsers = Get-ADUser -Server $Server -Filter $FilterExclusionList -SearchBase $TargetOU


    #Add each user account to the $Groups
    if($OUUsers){
        foreach($User in $OUUsers){
            foreach($Group in $Groups){

               Try{ 
                    Add-ADGroupMember -Server $Server -Identity $Group -Members $User -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose
                    $A = [pscustomobject]@{"User"=$User.samaccountname;
                                           "Group"=$Group;
                                           "Status"="Successful"}
               }

               Catch{
                    $A = [pscustomobject]@{"User"=$User.samaccountname;
                                           "Group"=$Group;
                                           "Status"="Failure";
                                           "Error"=$Error[0]}
               }

               $ReturnList += $A
            }
        }
    }

    else{$ReturnList = "No users found inside $TargetOU"}

    Return $ReturnList

}
Function Empty-IADComputersContainer{
<#
.SYNOPSIS
    Moves either or both Workstation and Server computer accounts to the specified Active Directory OUs from the Computers container. 
.DESCRIPTION
    Empty-IADComputersContainer queries the specified domain, gathers all computer accounts inside the Computers container, and moves them to the Active Directory paths provided by operator. Suggested application of this function is to use it inside a daily automated task to ensure a more organized Active Directory. Please note: moving devices to different OUs will apply any Group Policy Objects linked. 
.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to.
.PARAMETER Credential
    Specifies the credentials used to move the objects. Functions the same way as Active Directory cmdlets (PSCredential). 
.PARAMETER IncludeWorkstations
    Use this SwitchParameter to specify you want to move workstations. Workstation operating systems begin with Windows 7, 8, 10, or XP.
.PARAMETER WorkstationOU
    Specifies the target organizational unit to move the workstation objects to. This parameter accepts the distinguishedname of the OU as a string. 
.PARAMETER IncludeServers
    Use this SwitchParameter to specify you want to move servers. Server operating systems begin with Windows Server.
.PARAMETER ServerOU
   Specifies the target organizational unit to move the server objects to. This parameter accepts the distinguishedname of the OU as a string. 
.PARAMETER WhatIf
    Supports the SwitchParameter WhatIf. If specified the function will return what would happen if it was ran, taking no action. Use this to see what accounts are targeted without actually moving them.
.PARAMETER Confirm
    Supports the SwitchParameter Confirm. If specified the function will ask for confirmation before moving each account. If you do not specify -Confirm it will move the objects without asking.
.EXAMPLE
    Empty-IADComputersContainer -Server fabrikom.com -Credential (Get-Credential) -IncludeWorkstations -IncludeServers -WorkstationOU "OU=Workstations,DC=fabrikom,DC=com" -ServerOU "OU=Servers,DC=fabrikom,DC=com" -WhatIf

    Queries the fabrikom.com domain after prompting for credentials to use for movement. Returns what will happen (-WhatIf) and won't take any actions.  
.EXAMPLE
    Empty-IADComputersContainer -Server fabrikom.com -Credential $Creds -IncludeServers -ServerOU "OU=Servers,DC=fabrikom,DC=com" 

    Queries the currently joined domain and moves servers only using credentials stored inside the $Creds PSCredential object.    
#>       
    [CmdletBinding()]
    param([string]$Server,
          [System.Management.Automation.PSCredential]$Credential,
          [switch]$IncludeWorkstations,
          [string]$WorkstationOU,
          [switch]$IncludeServers,      
          [string]$ServerOU,
          [switch]$Confirm,
          [switch]$WhatIf)

    $ReturnList = @()

    if($IncludeWorkstations -or $IncludeServers){
        
        #Build the SearchBase for the Computers container
        $SearchBase = "CN=Computers," + "$((Get-ADDomain -Server $Server).distinguishedname)"

        #Process Workstations
        if($IncludeWorkstations){
        
            $Workstations = Get-ADComputer -Server $Server -Searchbase $Searchbase -filter{operatingsystem -like "Windows 7*" -or operatingsystem -like "Windows XP*" -or operatingsystem -like "Windows 8*" -or operatingsystem -like "Windows 10*"}
            
            foreach($Workstation in $Workstations){
                
                Try{
                    Move-ADObject -Identity $Workstation -Server $Server -TargetPath $WorkstationOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose

                    $A = [pscustomobject]@{"Computer"=$Workstation.dnshostname;
                                       "Type"="Workstation";
                                       "Status"="Successful"}
                }

                Catch{
                    $A = [pscustomobject]@{"Computer"=$Workstation.dnshostname;
                                       "Type"="Workstation";
                                       "Status"="Failed";
                                       "Error"="$Error[0]"}
                }

                $ReturnList += $A

            }
        }

        #Process Servers
        if($IncludeServers){
            
            $Servers = Get-ADComputer -Server $Server -SearchBase $SearchBase -filter{operatingsystem -like "Windows Server*"}
            
            foreach($ServerInstance in $Servers){
                
                Try{
                    Move-ADObject -Identity $ServerInstance -Server $Server -TargetPath $ServerOU -Credential $Credential -Confirm:$Confirm -Whatif:$WhatIf -Verbose

                    $A = [pscustomobject]@{"Computer"=$ServerInstance.dnshostname;
                                       "Type"="Server";
                                       "Status"="Successful"}
                }

                Catch{
                    $A = [pscustomobject]@{"Computer"=$ServerInstance.dnshostname;
                                       "Type"="Server";
                                       "Status"="Failed";
                                       "Error"="$Error[0]"}
                }

                $ReturnList += $A

            }
        }

        
    }

    else{Write-host "Please specify -IncludeWorkstations or -IncludeServers when using this cmdlet"}

    return $ReturnList

}
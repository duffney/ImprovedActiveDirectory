using module ActiveDirectory
using assembly Microsoft.ActiveDirectory.Management

class ADGroupMember {
    [string]$distinguishedName
    [string]$name
    [string]$objectClass
    [string]$objectGUID
    [string]$SamAccountName
    [string]$SID

    ADGroupMember ($distinguishedName,$name,$objectClass,$objectGUID,$SamAccountName,$SID){
        $this.distinguishedName = $distinguishedName
        $this.name = $name
        $this.objectClass = $objectClass
        $this.objectGUID = $objectGUID
        $this.SamAccountName = $SamAccountName
        $this.SID = $SID
    }    

    [ADGroupMember]Object(){
        return $this
    }
}

class IADGroup {
[string]$Identity
[object[]]$Properties
[string]$Server = (Get-ADDomain).DNSroot
 
IADGroup([Hashtable]$parameters)
{
    $type = $this.GetType()
    $hashproperties = $type.GetProperties()

    foreach($property in $hashproperties)
    {
        if($parameters.ContainsKey($property.Name) -and $parameters[$property.Name] -ne $null)
        {
            $property.SetValue($this, $parameters[$property.Name])
        }
    }
}

[object]GetGroup(){
    
    $splat = $this.Hash()
    return Get-ADgroup @splat
}

[object]NestedMembers(){
    $members = $this.DirectMembers($this.Identity,$this.Server) 

    $memberships = foreach ($member in $members) {

        $Domain = ((($member.DistinguishedName -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")  

        switch ($member.objectClass) {
            
            'group' {
                $this.NestedMembers($member.DistinguishedName,$Domain)
            }

            'user' {
                try {
                   $property = Get-ADUser -Identity $member.DistinguishedName -Server $Domain
                   [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)

                } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                    
                    $errors = Write-Warning -Message "$($member.DistinguishedName) not found"
                }
            }

            'computer' {
               $property = Get-ADComputer -Identity $member.DistinguishedName -Server $Domain
               [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)               
            }

            'foreignSecurityPrincipal' {
               $property = Get-ADObject -Identity $Member.DistinguishedName -Server $Domain -Properties objectsid | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
               [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.objectsid)                       
            }            
        }
    }

    return $memberships
    return $errors
}

[object]NestedMembers([string]$Identity,[string]$Server){
    $members = $this.DirectMembers($Identity,$Server) 

    $memberships = foreach ($member in $members) {
        
        $Domain = ((($member.DistinguishedName -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")  

        switch ($member.objectClass) {
            
            'group' {
                $this.NestedMembers($member.DistinguishedName,$Domain)
            }

            'user' {
                try {
                   $property = Get-ADUser -Identity $member.DistinguishedName -Server $Domain
                   [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)

                } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                    
                    $errors = Write-Warning -Message "$($member.DistinguishedName) not found"
                }
            }

            'computer' {
               $property = Get-ADComputer -Identity $member.DistinguishedName -Server $Domain
               [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)               
            }

            'foreignSecurityPrincipal' {
               $property = Get-ADObject -Identity $Member.DistinguishedName -Server $Domain -Properties objectsid | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
               [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.objectsid)                       
            }            
        }
    }

    return $memberships
    return $errors
}

[object]DirectMembers(){
        
    try {
        
        #$splat = $this.Hash()
        #if(!$splat.Properties.Contains('member')){$splat.Properties = $splat.Properties += 'member'}

        $memberships = Get-ADGroupMember -Identity $this.Identity -Server $this.Server
    }
    Catch [Microsoft.ActiveDirectory.Management.ADException] {
        
        $ADGroupMembers = (Get-ADGroup -Identity $this.Identity -Server $this.Server -Properties member).member

        $memberships = foreach($Member in $ADGroupMembers){
            
            $ObjectDomain = ((($member -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")
            $ADObject = Get-ADObject -Identity $Member -Server $ObjectDomain
                
                switch ($ADObject.ObjectClass) {
                    'group' {
                        $property = Get-ADGroup -Identity $member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,SID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)

                     }
                    'user' {
                        $property = Get-ADUser -Identity $Member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,SID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)
                        
                     }
                    'foreignSecurityPrincipal' {
                        $property = Get-ADObject -Identity $Member -Server $ObjectDomain -Properties objectSid | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.objectsid)                        
                     }
                    'computer' {
                        $property = Get-ADComputer -Identity $Member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)                                                 
                     }                     
                }
        } 
    }
    if ($memberships){
        return $memberships
    } else {
        return $null
    }
            
}

[object]DirectMembers([string]$Identity,[string]$Server){
    try {
        

        $memberships = Get-ADGroupMember -Identity $Identity -Server $Server
    }
    Catch [Microsoft.ActiveDirectory.Management.ADException] {
        
        $ADGroupMembers = (Get-ADGroup -Identity $Identity -Server $Server -Properties member).member

        $memberships = foreach($Member in $ADGroupMembers){
            
            $ObjectDomain = ((($member -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")            
            $ADObject = Get-ADObject -Identity $Member -Server $ObjectDomain
                
                switch ($ADObject.ObjectClass) {
                    'group' {
                        $property = Get-ADGroup -Identity $member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,SID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)

                     }
                    'user' {
                        $property = Get-ADUser -Identity $Member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,SID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)
                        
                     }
                    'foreignSecurityPrincipal' {
                        $property = Get-ADObject -Identity $Member -Server $ObjectDomain -Properties objectSid | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.objectsid)                        
                     }
                    'computer' {
                        $property = Get-ADComputer -Identity $Member -Server $ObjectDomain | select distinguishedName,name,objectClass,objectGuid,samaccountname,objectSID
                        [ADGroupMember]::New($property.distinguishedName,$property.name,$property.objectclass,$property.objectguid,$property.samaccountname,$property.sid)                                                 
                     }                     
                }
        } 
    }

    if ($memberships){
        return $memberships
    } else {
        return $null
    }       
}

[hashtable]Hash(){
    $type = $this.GetType()
    $hashproperties = $type.GetProperties()

    $splat = @{}
    foreach($property in $hashproperties)
    {
        if ($this.($property.Name) -ne $null){
            $splat.Add($($property.Name),$($this.($property.Name)))
        }
    }

    return $splat
}

}
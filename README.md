![improvedactivedirectory](http://i.imgur.com/MFNQkoG.png "improvedactivedirectory")

## Introduction
ImprovedActiveDirectory is a PowerShell module that builds on and expands upon the ActiveDirectory module used for interacting with ActiveDirectory domains and forests.
The purpose of this module is to provide richer and more consistance experaince for ActiveDirectory engineers that are automating the maintenance and administration of
ActiveDirectory. To do that it combines several existing cmdlets to perform administration tasks as well as improved upon those cmdlets with advanced PowerShell scripting
techniques. 

## Requirements

- PowerShell Version 5.0+
- [ActiveDirectory Module](https://www.microsoft.com/en-us/download/details.aspx?id=45520)

### Installation

1. [Download the module](https://github.com/Duffney/ImprovedActiveDirectory/archive/master.zip)
2. Unblock the .zip file
3. Extract ImprovedActiveDirectory-master.zip
4. Rename ImprovedActiveDirectory-master to ImprovedActiveDirectory
5. Copy ImprovedActiveDirectory to *C:\Program Files\WindowsPowerShell\Modules*
6. Open PowerShell
7. *Import-Module ImprovedActiveDirectory*
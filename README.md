![MSAD](https://img.shields.io/badge/Active_Directory_Domain_Services-blue) ![PowerShell](https://img.shields.io/badge/Powershell-5391FE?style=flat&logo=powershell&logoColor=white) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)](https://www.gnu.org/licenses/gpl-3.0)

# Managed Service Accounts Kerberos Delegation
This repository contains a PowerShell script which provides a GUI to manage the attributes relevant for the Kerberos Delegation mechanism more comfortably.

## Motivation
It's been obvious for years that Microsoft has seriously neglected other management tools because of its focus on the cloud. For example, in the ADAC created back in 2012, you can create FGPPs or Authentication Silos, but you still have to manually create NTDS Quotas. Likewise, the long-existing Managed Service Accounts are basically ignored in ADAC, and you can't set Kerberos delegation settings there.
For standard user accounts with SPN and computer accounts, there is a 'Delegation' tab in the Users and Computers (ADUC) Snap-In:


But not like that for MSAs. To help with this a bit, this PowerShell script provides a simple recreation of this 'Delegation' tab.

## Installation and Use
No installation needed, download both files, the .ps1 and the .lib.ps1 to the same directory and run the Set-MsaKerberosDelegation.ps1 script. With the parameter -Identity you could submit the desired MSA:
````PowerShell
.\Set-MsaKerberosDelegation.ps1 -Identity 'testmsa'
````
The script reads the current Kerberos delegation setting and displays them in the GUI:


After closing the dialog with the OK button, a confirmation prompt appears where you can still cancel the operation.
````
PS C:\Data> .\Set-MsaKerberosDelegation.ps1 -identity testmsa
Do you want to write the new delegation settings?
Enter [Y] for OK or [N] for Cancel:
````

## Contributing
All PowerShell developers or Active Directory experts are very welcome to help and make the code better, more readable or contribute new ideas. 

## License
This project is licensed under the terms of the GPL V3 license. Please see the included LICENCE file gor more details.

## Release History
### Version 1.0.1 (2025/02/27)
Small bug: GUI-Function could not be canceled.
### Version 1.0.0 (2024/09/01)
First release, testing has been done but bugs may still exist.



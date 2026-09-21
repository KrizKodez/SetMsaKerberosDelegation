<#PSScriptInfo

.TYPE Controller

.VERSION 1.0.1

.TEMPLATEVERSION 1

.PLATFORM 5.1

.GUID 4ABAC152-CC18-4FFB-A495-8E26BDFE3B9E

.AUTHOR Christoph Rust

.CONTRIBUTORS

.COMPANYNAME KrizKodez, Tools and Components.

.TAGS
    Delegation
    Kerberos
    Managed Service Account
    MSA

.EXTERNALMODULEDEPENDENCIES
    ActiveDirectory, Microsoft
   
.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.REQUIREDBINARIES

.RELEASENOTES
    2024-09-01, 1.0.0, Christoph Rust, Initial release.
    2025-02-27, 1.0.1, Christoph Rust, Function could not be canceled.
#>

<#
.SYNOPSIS
    Set Kerberos delegation settings of a Managed Service Account.                

.DESCRIPTION
    The function provides a more easy interface to change Kerberos delegation settings for
    Managed Service Accounts.
    
.INPUTS
    System.String
    Identity of the Managed Service Account.
        
    You cannot pipe input to this cmdlet.

.OUTPUTS
    None    
 
.NOTES
 
.LINK
    https://github.com/KrizKodez/DSHeuristics
 
.EXAMPLE

.PARAMETER Identity
    Specifies an Active Directory user object by providing one of the following property values.
    The identifier in parentheses is the LDAP display name for the attribute. The acceptable values for this parameter are:
    distinguished name, GUID (objectGUID), security identifier (objectSid) or SAM account name (sAMAccountName).

.PARAMETER Server
    Specifies the Active Directory Domain Services instance to connect to,
    by providing a domain name or directory server.
    The default value is the LOGONSERVER of the current user.
    
#>

[CmdletBinding()]
param
(
    [Parameter(Position=0,Mandatory=$true)]
    [string]$Identity,

    [string]$Server = $Env:LOGONSERVER.Substring(2) 
)

# PARAMETER CHECK
# NA

# PREREQUISITES
Add-Type      -AssemblyName PresentationFramework -ErrorAction Stop
Import-Module -Name ActiveDirectory               -ErrorAction Stop

# INCLUDE LIBRARIES
    # PRIVATE
    . "$PSScriptRoot\SetMsaKerberosDelegation.lib.ps1"

    # PUBLIC
    # NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA

    # CONSTANTS
    # NA 

    # VARIABLES
    $ControllerVersion    = GetVersion
    $DelegationAttributes = @{
                            'AccountName'                = $null
                            'AllowedServices'            = $null
                            'DoNotTrust'                 = $false
                            'TrustForAnyKerberosService' = $false
                            'TrustForSpecificServices'   = $false
                            'UseKerberosOnly'            = $false
                            'UseAnyAuthentication'       = $false
                            }
    # We use an ArrayList for the msDS-AllowedToDelegate attribute date because adding and removing is easy.
    $AllowedToDelegateTo = [System.Collections.ArrayList]::new()


# CONTROLLER MAIN CODE
# Try to get the Managed Service Account and...
$ServiceAccount = Get-ADServiceAccount @PSBoundParameters -Properties * -ErrorAction Stop

# ...and collect all important attributes and values for delegation.
foreach ($Item in $ServiceAccount."msDS-AllowedToDelegateTo") { $null = $AllowedToDelegateTo.Add($Item) }
$DelegationAttributes.AllowedServices = $AllowedToDelegateTo
$DelegationAttributes.AccountName     = $ServiceAccount.Name
if ($ServiceAccount.TrustedForDelegation)
{
    # Here we have unconstrained delegation.
    if ($ServiceAccount.TrustedToAuthForDelegation) { } # Should not exist
    else { $DelegationAttributes.TrustForAnyKerberosService = $true }       
}
else
{
    # Here we have constrained delegation
    if ($ServiceAccount.TrustedToAuthForDelegation)
    {
        $DelegationAttributes.TrustForSpecificServices = $true
        $DelegationAttributes.UseAnyAuthentication     = $true
    }
    else
    {
        if ($ServiceAccount."msDS-AllowedToDelegateTo")
        {
            $DelegationAttributes.TrustForSpecificServices = $true
            $DelegationAttributes.UseKerberosOnly          = $true
        }
        else { $DelegationAttributes.DoNotTrust = $true }
    }
}  

# Open the WPF dialog with the collected delegation attributes.
$NewDelegationAttributes = OutMsaDelegationView -InputObject $DelegationAttributes

# If we have no return value here the user has canceled the process.
if (-not $NewDelegationAttributes) { return }

# If the OK button has been clicked we first check if any setting has been changed.
$HasDelegationSettingsChanged = $false
foreach ($Attribute in $DelegationAttributes.Keys)
{
    # The 'AllowedServices' setting is an array so we need a special handling.
    if ($Attribute -eq 'AllowedServices')
    {
        $CompareResult =  Compare-Object -ReferenceObject $NewDelegationAttributes."$Attribute" -DifferenceObject $DelegationAttributes."$Attribute"
        if (-not $CompareResult) { continue }
        $HasDelegationSettingsChanged = $true 
        break 
    }
    # All other settings could compared directly.
    if ($DelegationAttributes."$Attribute" -eq $NewDelegationAttributes."$Attribute") { continue }
    $HasDelegationSettingsChanged = $true 
    break  
}

# Bye, bye.
if (-not $HasDelegationSettingsChanged) { return }

# If something has been changed we want the user to do a last confirmation before changing the Directory.
Write-Host "Do you want to write the new delegation settings?" -ForegroundColor Yellow
do    { $Awnser = Read-Host -Prompt "Enter [Y] for OK or [N] for Cancel" }
until ( $Awnser -eq 'y' -or $Awnser -eq 'n' )
if ($Awnser -eq 'n') { return }

# Ok so now we change the Managed Service Account.
# We use the samAccountName of the Managed Service Account which our script read, because the user could submit
# an account name without $ to our function but this not works with the Set-ADAccountControl cmdlet.
$SamAccountName = $ServiceAccount.samAccountName

# No delegation case.
if ($NewDelegationAttributes.DoNotTrust)
{
    Set-ADAccountControl -Identity $SamAccountName -TrustedForDelegation $false -TrustedToAuthForDelegation $false -Server $Server -ErrorAction Stop
    Set-ADServiceAccount -Identity $SamAccountName -Clear 'msDS-AllowedToDelegateTo' -Server $Server -ErrorAction Stop
}

# Unconstrained delegation case.
if ($NewDelegationAttributes.TrustForAnyKerberosService)
{
    Set-ADAccountControl -Identity $SamAccountName -TrustedForDelegation $true -TrustedToAuthForDelegation $false -Server $Server -ErrorAction Stop
    Set-ADServiceAccount -Identity $SamAccountName -Clear 'msDS-AllowedToDelegateTo' -Server $Server -ErrorAction Stop
}

# Constrained delegation case.
if ($NewDelegationAttributes.TrustForSpecificServices)
{
    if($NewDelegationAttributes.UseKerberosOnly)
    {
        if (-not $NewDelegationAttributes.AllowedServices)
        {
            $ErrorMessage = 'Constrained Kerberos delegation works only with defined services.'
            Write-Error -Message $ErrorMessage -Category InvalidOperation -RecommendedAction "Define at least one SPN in the Services listbox."
            return
        }
        Set-ADAccountControl -Identity $SamAccountName -TrustedForDelegation $false -TrustedToAuthForDelegation $false -Server $Server -ErrorAction Stop
        Set-ADServiceAccount -Identity $SamAccountName -Replace @{"msDS-AllowedToDelegateTo" = $NewDelegationAttributes.AllowedServices.ToArray()} -Server $Server
    }
    else
    {
        Set-ADAccountControl -Identity $SamAccountName -TrustedForDelegation $false -TrustedToAuthForDelegation $true -Server $Server -ErrorAction Stop
        if (-not $NewDelegationAttributes.AllowedServices)
        { Set-ADServiceAccount -Identity $SamAccountName -Clear 'msDS-AllowedToDelegateTo' -Server $Server }
        else
        { Set-ADServiceAccount -Identity $SamAccountName -Replace @{"msDS-AllowedToDelegateTo" = $NewDelegationAttributes.AllowedServices.ToArray()} -Server $Server }
    }
}

# END MAIN CODE

# EXCEPTION HANDLING
trap { break }





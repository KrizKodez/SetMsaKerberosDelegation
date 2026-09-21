<#PSScriptInfo

.TYPE Private Library

.TEMPLATEVERSION 1

.PLATFORM 5.1

.GUID 39AB32AF-2F35-476D-8729-E0F0B47A51E8

.AUTHOR Christoph Rust

.CONTRIBUTORS

.COMPANYNAME KrizKodez, Tools and Components.

.TAGS
    Delegation
    Kerberos
    Managed Service Account
    MSA

.FUNCTIONS
    GetGuiWindow
    GetVersion
    OutMsaDelegationView

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS Set-MsaKerberosDelegation

.REQUIREDBINARIES

.DESCRIPTION
    This library contains private functions for the script defined in REQUIREDSCRIPTS.

.RELEASENOTES 
     2024-09-01, 1.0.0, Christoph Rust, Initial release.

#>

# DECLARATIONS AND DEFINITIONS
    # CONSTANTS
    # NA

    # VARIABLES
    # NA

# SCRIPTBLOCKS
# NA

# FUNCTIONS
function GetGuiWindow
{
<#
.DESCRIPTION
    Initialize the WPF-GUI main window.
    
.INPUTS
    None
    [You cannot pipe input to this function.]

.OUTPUTS
    System.Windows.Window
    The WPF Window of the GUI.
#>   

# PARAMETERS
[CmdletBinding()]
param()

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    # NA

# FUNCTION MAIN CODE

$WindowXamlDefinition=
@"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Managed Service Account Delegation" Height="542"  Width="446" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Canvas>
        <Label x:Name="lblAccountName" Content="Managed Service Account:" Canvas.Left="13" HorizontalAlignment="Left" VerticalAlignment="Center" Width="177" FontSize="13" FontWeight="Bold"/>
        <TextBox x:Name="txtAccountName" IsReadOnly="True" Canvas.Left="18" Text="accountname" Canvas.Top="25" Width="395" HorizontalAlignment="Center" VerticalAlignment="Top" Height="25" IsUndoEnabled="False" VerticalContentAlignment="Center" UseLayoutRounding="False" FontSize="13"/>
        <RadioButton x:Name="radioNoTrust" Content="Do not trust this MSA for delegation" Canvas.Left="18" Canvas.Top="100" GroupName="TrustSettings" HorizontalAlignment="Left" VerticalAlignment="Center" Width="390" FontSize="13"/>
        <RadioButton x:Name="radioTrustKerberosOnly" Content="Trust this MSA for delegation to any Kerberos (only) Service" Canvas.Left="18" Canvas.Top="120" GroupName="TrustSettings" HorizontalAlignment="Left" VerticalAlignment="Center" Width="391" FontSize="13"/>
        <RadioButton x:Name="radioTrustSpecificServices" Content="Trust this MSA for delegation to specific services only" Canvas.Left="18" Canvas.Top="140" GroupName="TrustSettings" HorizontalAlignment="Left" VerticalAlignment="Center" Width="392" FontSize="13"/>
        <TextBlock Canvas.Left="18" TextWrapping="Wrap" Text="Delegation is a security-sensitive operation, which allows services to act on behalf of other users." Canvas.Top="57" Height="33" Width="393" HorizontalAlignment="Left" VerticalAlignment="Center" FontSize="13" FontWeight="Bold"/>
        <RadioButton x:Name="radioKerberosProtocolOnly" Content="Use Kerberos only" Canvas.Left="39" Canvas.Top="163" HorizontalAlignment="Center" VerticalAlignment="Top" GroupName="ProtocolType" Width="352" FontSize="13"/>
        <RadioButton x:Name="radioAnyProtocol" Content="Use any authentication protocol" Canvas.Left="39" Canvas.Top="182" GroupName="ProtocolType" HorizontalAlignment="Center" VerticalAlignment="Top" Width="352" FontSize="13"/>
        <Label x:Name="lblSPNListTitel" Content="Services to which this account can present delegated credentials:" Canvas.Left="35" Width="380" HorizontalAlignment="Left" VerticalAlignment="Center" Canvas.Top="196" FontSize="13"/>
        <ListBox x:Name="lstSPN" Height="133" Canvas.Left="39" Canvas.Top="220" Width="369" HorizontalAlignment="Left" VerticalAlignment="Center"/>
        <TextBox x:Name="txtSelectedSPNItem" Canvas.Left="39" Canvas.Top="358" Width="369" Height="25" IsUndoEnabled="False" VerticalContentAlignment="Center" UseLayoutRounding="False" HorizontalAlignment="Left" VerticalAlignment="Center"/>
        <Button x:Name="buttonAdd" Content="Add" Canvas.Left="249" Canvas.Top="390" HorizontalAlignment="Left" VerticalAlignment="Center" Width="75" Height="26"/>
        <Button x:Name="buttonRemove" Content="Remove" Canvas.Left="332" Canvas.Top="390" Width="75" Height="26" HorizontalAlignment="Left" VerticalAlignment="Center"/>
        <Button x:Name="buttonOK" Content="OK" Canvas.Left="96" Canvas.Top="434" Width="106" Height="26" HorizontalAlignment="Center" VerticalAlignment="Top" FontWeight="Bold"/>
        <Button x:Name="buttonCancel" Content="Cancel" Canvas.Left="227" Canvas.Top="434" Width="106" Height="26" HorizontalAlignment="Center" VerticalAlignment="Top" FontWeight="Bold"/>
        <Canvas x:Name="CavasKrizKodez" Height="32" Width="447" Background="#FF00A2E8" Panel.ZIndex="1" Canvas.Top="471" HorizontalAlignment="Left" VerticalAlignment="Center">
            <Label x:Name="LableCompany" Content="KrizKodez" Height="30" Width="97" Background="{x:Null}" Foreground="White" FontFamily="Segoe UI Black" FontSize="16" Canvas.Left="-2"/>
            <Label x:Name="LabelCompanyDescription" Content="Tools and Components" Height="20" Canvas.Left="95" Width="133" Canvas.Top="9" Padding="0,0,0,0" Foreground="White"/>
            <Label x:Name="LabelVersion" Content="Version" Canvas.Left="377" Canvas.Top="4" RenderTransformOrigin="1.579,-0.462" Foreground="White" Width="55" HorizontalAlignment="Left" VerticalAlignment="Center"/>
        </Canvas>
    </Canvas>
</Window>
"@

[xml]$Xaml = $WindowXamlDefinition
$Reader    = New-Object -TypeName 'System.Xml.XmlNodeReader' -ArgumentList $Xaml
$Result    = [Windows.Markup.XamlReader]::Load($Reader)

Write-Output $Result

}# End of function GetGuiWindow.

function GetVersion
{
<#
.DESCRIPTION
    Get the current version of the controller.
    
.INPUTS
    None
    [You cannot pipe input to this function.]

.OUTPUTS
    System.String
    The version of the controller.
#>   

# PARAMETERS
[CmdletBinding()]
param()

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    # NA

# FUNCTION MAIN CODE
$ScriptText = Get-Content -Path $MyInvocation.ScriptName
$MatchInfo  = $ScriptText | Select-String -Pattern '\.VERSION (\d\.\d\.\d)'
$Result     = $MatchInfo.Matches.Groups[1].Value

Write-Output $Result

}# End of function GetVersion.

function OutMsaDelegationView
{
<#    
.SYNOPSIS
    Shows the delegation settings of a Managed Service Account in a WPF dialog.               

.DESCRIPTION
    The function allows delegation settings to be changed with an interactive WPF-GUI.    
    
.INPUTS
    System.Collections.Hashtable
    The delegation settings of a Managed Service Account.
        
    You cannot pipe input to this cmdlet.

.OUTPUTS
    System.Collections.Hashtable
    The changed delegation settings of a Managed Service Account.    
 
.NOTES

.PARAMETER InputObject
    The delegation settings of a Managed Service Account to be viewed.

#>

# PARAMETERS
[CmdletBinding()]
param
(
    [Parameter(Position=0,Mandatory=$true)]
    [hashtable]$InputObject
)

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA 

    # VARIABLES
    $EmptyArrayList = [System.Collections.ArrayList]::new()

# FUNCTION MAIN CODE

# We must clone the submitted AllowedServices ArrayList to allow changes.
$NewAllowedServices = $InputObject.AllowedServices.Clone()

# Prepare WPF-Form.
$Form = GetGuiWindow

# Assign the WPF controls to PowerShell variables.
$ButtonAdd                        = $Form.FindName('buttonAdd')
$ButtonRemove                     = $Form.FindName('buttonRemove')
$ButtonOK                         = $Form.FindName('buttonOK')
$ButtonCancel                     = $Form.FindName('buttonCancel')
$LabelVersion                     = $Form.FindName('LabelVersion')
$ListBoxSPN                       = $Form.FindName('lstSPN')
$RadioButtonNoTrust               = $Form.FindName('radioNoTrust')
$RadioButtonTrustKerberosOnly     = $Form.FindName('radioTrustKerberosOnly')
$RadioButtonTrustSpecificServices = $Form.FindName('radioTrustSpecificServices')
$RadioButtonKerberosProtocolOnly  = $Form.FindName('radioKerberosProtocolOnly')
$RadioButtonAnyProtocol           = $Form.FindName('radioAnyProtocol')
$TextBoxAccountName               = $Form.FindName('txtAccountName')
$TextBoxNewSPNItem                = $Form.FindName('txtSelectedSPNItem')


# Add the event handlers.
$ButtonOK.Add_Click({ $Form.DialogResult = $true })
$ButtonCancel.Add_Click({ $Form.DialogResult = $false })

$NewSPNItem = {
    if ($TextBoxNewSPNItem.Text.Length) { $ButtonAdd.IsEnabled = $true }
    else                                { $ButtonAdd.IsEnabled = $false }
}
$TextBoxNewSPNItem.Add_TextChanged($NewSPNItem)

$DisableConstrainedDelegationControls = {
    $RadioButtonKerberosProtocolOnly.IsChecked = $false
    $RadioButtonKerberosProtocolOnly.IsEnabled = $false
    $RadioButtonAnyProtocol.IsChecked          = $false
    $RadioButtonAnyProtocol.IsEnabled          = $false
    $ListBoxSPN.IsEnabled                      = $false
    $TextBoxNewSPNItem.IsEnabled               = $false
    $ButtonAdd.IsEnabled                       = $false
    $ButtonRemove.IsEnabled                    = $false
}
$EnableConstrainedDelegationControls = {
    $RadioButtonKerberosProtocolOnly.IsChecked = $true
    $RadioButtonKerberosProtocolOnly.IsEnabled = $true
    $RadioButtonAnyProtocol.IsEnabled          = $true
    $ListBoxSPN.IsEnabled                      = $true
    $TextBoxNewSPNItem.IsEnabled               = $true
    $ButtonAdd.IsEnabled                       = $true
    $ButtonRemove.IsEnabled                    = $true
}
$RadioButtonNoTrust.Add_Checked($DisableConstrainedDelegationControls)
$RadioButtonTrustKerberosOnly.Add_Checked($DisableConstrainedDelegationControls)
$RadioButtonTrustSpecificServices.Add_Checked($EnableConstrainedDelegationControls)

$AddNewSPNItem = {
    if($TextBoxNewSPNItem.Text)
    {
        # The SPN data comes in SNOW with the < and > characters, we remove this first.
        $Text = $TextBoxNewSPNItem.Text -replace '<',''
        $Text = $Text -replace '>',''
        $NewAllowedServices.Add($Text)
        $TextBoxNewSPNItem.Text = $null
    }
    $ListBoxSPN.ItemsSource = $null
    $ListBoxSPN.ItemsSource = $NewAllowedServices
}
$ButtonAdd.Add_Click($AddNewSPNItem)

$RemoveSPNItem = {
    $NewAllowedServices.Remove($ListBoxSPN.SelectedItem)
    $ListBoxSPN.ItemsSource = $null
    $ListBoxSPN.ItemsSource = $NewAllowedServices
}
$ButtonRemove.Add_Click($RemoveSPNItem)

# Setup some controls default properties.
$ButtonAdd.IsEnabled    = $False
$LabelVersion.Content   = $ControllerVersion
$ListBoxSPN.ItemsSource = $NewAllowedServices

# Setup the controls from the values of the submitted InputObject.
$TextBoxAccountName.Text = $InputObject.AccountName
if ($InputObject.DoNotTrust)                 { $RadioButtonNoTrust.IsChecked = $true }
if ($InputObject.TrustForAnyKerberosService) { $RadioButtonTrustKerberosOnly.IsChecked = $true }
if ($InputObject.TrustForSpecificServices)
{
    $RadioButtonTrustSpecificServices.IsChecked = $true
    if ($InputObject.UseKerberosOnly) { $RadioButtonKerberosProtocolOnly.IsChecked = $true }
    else                              { $RadioButtonAnyProtocol.IsChecked = $true }
}

# Show the WPF dialog and if the user click the Cancel button...
$DialogResult = $Form.ShowDialog()
# ...we cancel the function with a null value.
if (-not $DialogResult) { return }

# Create the Result with the new delegation settings and return it.
$Result = @{
            'AccountName'                = $InputObject.AccountName
            'AllowedServices'            = $NewAllowedServices
            'DoNotTrust'                 = $false
            'TrustForAnyKerberosService' = $false
            'TrustForSpecificServices'   = $false
            'UseKerberosOnly'            = $false
            'UseAnyAuthentication'       = $false
            }

if ($RadioButtonNoTrust.IsChecked)
{ 
    $Result.DoNotTrust      = $true
    $Result.AllowedServices = $EmptyArrayList
}
if ($RadioButtonTrustKerberosOnly.IsChecked)
{
    $Result.TrustForAnyKerberosService = $true
    $Result.AllowedServices            = $EmptyArrayList
}
if ($RadioButtonTrustSpecificServices.IsChecked)
{
    $Result.TrustForSpecificServices = $true
    if ($RadioButtonKerberosProtocolOnly.IsChecked) { $Result.UseKerberosOnly      = $true }
    else                                            { $Result.UseAnyAuthentication = $true }
}

Write-Output $Result

}# End of function OutMsaDelegationView


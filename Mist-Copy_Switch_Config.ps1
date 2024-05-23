#create a configuration file in the same directory as the script. The configuration text file should looke like the following. No spaces between the = sign! 
#api_key=<API Key no " or '>
#org_id=<Org Id from mist no " or '>
$ConfigFile = "$PSScriptRoot\Config.txt"

Foreach ($i in $(Get-Content $ConfigFile)){
    Set-Variable -Name $i.split("=")[0] -Value $i.split("=",2)[1]
}
$token = "Token $($api_key)"
function Show-ChoiceMenu {
    param (
        [Parameter(Position=0,mandatory=$true)]
        [array] $Choices, #Array of data
        [Parameter(Position=1,mandatory=$true)]
        [string] $Choice, #Array property that you want shown as a choice.
        [Parameter(Position=3,mandatory=$true)]
        [string] $ChoiceValue, #Array property that you want as the returned value. Can be the same property as the choice variable.  
        [Parameter(Position=4)]
        [string] $ChoicePrompt = "Pick an Option" #What the prompt will ask the user, automatically adds : at the end. 

    )
    $menu = @{}
    for ($i=1;$i -le $Choices.count; $i++) 
    { Write-Host "$i. $($Choices[$i-1].$Choice)" #,$($Choices[$i-1].$ChoiceValue)
    $menu.Add($i,($Choices[$i-1].$Choice))}

    [int]$ans = Read-Host $ChoicePrompt
    $selection = @{}
    $selection = @{
        name = "$($menu.Item($ans))"
        value = "$($Choices[$ans-1].$ChoiceValue)"
    }
    Write-Host "You Selected: $($menu.Item($ans))"
    Return $selection
}

function Get-JunosMistSites {
    param (
        [Parameter(Position=0,mandatory=$true)]
        [string] $OrgID,
        [Parameter(Position=1,mandatory=$true)]
        [string] $token
    )
    $headers = @{
        'Authorization' = $token
    }
    $API_URI = "https://api.mist.com/api/v1/orgs/$OrgID/sites"
    $SitePayload = Invoke-RestMethod -Uri $API_URI -Method Get -Headers $headers 
    $SitePayload = $SitePayload | Sort-Object -Property name
    $SiteID = Show-ChoiceMenu -Choices $SitePayload -Choice name -ChoiceValue id 
    Return $SiteID
}
function Get-JunosMistSiteSwitches {
    param (
        [Parameter(Position=0,mandatory=$true)]
        [string] $SiteID,
        [Parameter(Position=1,mandatory=$true)]
        [string] $token,
        [Parameter(Position=2,mandatory=$true)]
        [string] $prompt
    )
    $headers = @{
        'Authorization' = $token
    }
    $API_URI = "https://api.mist.com/api/v1/sites/$SiteID/devices?type=switch"
    $SwitchesPayload = Invoke-RestMethod -Uri $API_URI -Method Get -Headers $headers 
    $SwitchesPayload = $SwitchesPayload | Sort-Object -Property name
    $SelectedSwitch = Show-ChoiceMenu -Choices $SwitchesPayload -Choice name -ChoiceValue id -ChoicePrompt $prompt
    Return $SelectedSwitch
}
function Get-JunosSwitchConfig {
    param (
        [Parameter(Position=0,mandatory=$true)]
        [string] $SiteID,
        [Parameter(Position=1,mandatory=$true)]
        [string] $token,
        [Parameter(Position=2,mandatory=$true)]
        [string] $SwitchID
    )
    $headers = @{
        'Authorization' = $token
    }
    $API_URI = "https://api.mist.com/api/v1/sites/$SiteID/devices/$SwitchID"
    $SourceSwitchPayload = Invoke-RestMethod -Uri $API_URI -Method Get -Headers $headers 
    Return $SourceSwitchPayload
}
function Push-JunosSwitchConfig {
    param (
        [Parameter(Position=0,mandatory=$true)]
        [string] $SiteID,
        [Parameter(Position=1,mandatory=$true)]
        [string] $token,
        [Parameter(Position=2,mandatory=$true)]
        [string] $SwitchID,
        [Parameter(Position=3,mandatory=$true)]
        $Payload
    )
    $SwitchConfigJSON = $Payload | ConvertTo-Json
    $headers = @{
        'Authorization' = $token
    }
    $API_URI = "https://api.mist.com/api/v1/sites/$SiteID/devices/$SwitchID"
    $SwitchPayload = Invoke-RestMethod -Uri $API_URI -Method Put -Headers $headers -ContentType "application/json; charset=utf-8" -Body $SwitchConfigJSON
    Return $SwitchPayload
}

$SiteID = Get-JunosMistSites -OrgID $org_id -token $token

Write-Host "`n"
$SourceSwitch = Get-JunosMistSiteSwitches -SiteID $SiteID.value -token $token -prompt "Select the source switch"
Write-Host "`n"
$DestinationSwitch = Get-JunosMistSiteSwitches -SiteID $SiteID.value -token $token -prompt "Select the destination switch"

$SwitchConfig = Get-JunosSwitchConfig -SiteID $SiteID.value -token $token -SwitchID $SourceSwitch.value
$SwitchConfig = $SwitchConfig | ConvertTo-Json | ConvertFrom-Json

############## Switch Config Changes ##############

$SwitchConfig.name = "$($SwitchConfig.name)-new"
$SwitchConfig.PSObject.Properties.Remove('x')
$SwitchConfig.PSObject.Properties.Remove('y')
$SwitchConfig.PSObject.Properties.Remove('x_m')
$SwitchConfig.PSObject.Properties.Remove('y_m')
$SwitchConfig.PSObject.Properties.Remove('id')
$SwitchConfig.PSObject.Properties.Remove('site_id')
$SwitchConfig.PSObject.Properties.Remove('org_id')
$SwitchConfig.PSObject.Properties.Remove('created_time')
$SwitchConfig.PSObject.Properties.Remove('modified_time')
$SwitchConfig.PSObject.Properties.Remove('map_id')
$SwitchConfig.PSObject.Properties.Remove('mac')
$SwitchConfig.PSObject.Properties.Remove('serial')
$SwitchConfig.PSObject.Properties.Remove('model')
$SwitchConfig.PSObject.Properties.Remove('type')
$SwitchConfig.PSObject.Properties.Remove('tag_uuid')
$SwitchConfig.PSObject.Properties.Remove('tag_id')
$SwitchConfig.PSObject.Properties.Remove('evpn_scope')
$SwitchConfig.PSObject.Properties.Remove('evpntopo_id')
$SwitchConfig.PSObject.Properties.Remove('st_ip_base')
$SwitchConfig.PSObject.Properties.Remove('deviceprofile_id')
$SwitchConfig.PSObject.Properties.Remove('hw_rev')
$SwitchConfig.PSObject.Properties.Remove('switch_mgmt')
$SwitchConfig.PSObject.Properties.Remove('managed')
$SwitchConfig.PSObject.Properties.Remove('routing_policies')
$SwitchConfig.PSObject.Properties.Remove('bgp_config')

#####################################################

$JSON = $SwitchConfig | ConvertTo-Json

$JSON

$confirmation = Read-Host "You are about to copy the above configuration from $($SourceSwitch.name) TO $($DestinationSwitch.name) would you like to proceed? y/n"
if ($confirmation -eq 'y') {
    Push-JunosSwitchConfig -SiteID $SiteID.value -token $token -SwitchID $DestinationSwitch.value -Payload $SwitchConfig 
}
else {
    exit 0
}
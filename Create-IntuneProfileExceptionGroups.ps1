<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################
# 
####################################################

Function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $User
    )
    
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User    
    $tenant = $userUpn.Host
    
    Write-Host "Checking for AzureAD module..."
    
    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]    
        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

        # Checking if there are multiple versions of the same module found
        if($AadModule.count -gt 1){
            $aadModule = $AadModule | Select-Object -Unique
        }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }    
    else {    
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"    
    }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"    
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"
    
    try {

        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        # If the accesstoken is valid then create the authentication header
        if($authResult.AccessToken){

            # Creating header for Authorization token
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }

            return $authHeader
        }
        else {
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
        }
    }
    catch {
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    }
}
    
####################################################
    
Function Get-DeviceConfigurationPolicy(){

    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-DeviceConfigurationPolicy
    #>

    [cmdletbinding()]

    param
    (
        $name
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"

    try {

        if($Name){
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }
        }
        else {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        }
    }
    catch {
        $ex = $_.Exception
        $ex
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }
}
    
####################################################
    
Function Get-DeviceConfigurationPolicyAssignment(){

    <#
    .SYNOPSIS
    This function is used to get device configuration policy assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets a device configuration policy assignment
    .EXAMPLE
    Get-DeviceConfigurationPolicyAssignment $id guid
    Returns any device configuration policy assignment configured in Intune
    .NOTES
    NAME: Get-DeviceConfigurationPolicyAssignment
    #>

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter id (guid) for the Device Configuration Policy you want to check assignment")]
        $id
    )

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/groupAssignments"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }
}

####################################################
    
    Function Add-DeviceConfigurationPolicyAssignment() {

        <#
        .SYNOPSIS
        This function is used to add a device configuration policy assignment using the Graph API REST interface
        .DESCRIPTION
        The function connects to the Graph API Interface and adds a device configuration policy assignment
        .EXAMPLE
        Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
        Adds a device configuration policy assignment in Intune
        .NOTES
        NAME: Add-DeviceConfigurationPolicyAssignment
        #>
        
        [cmdletbinding()]
        
        param
        (
            $ConfigurationPolicyId,
            $TargetGroupId
        )
        
        $graphApiVersion = "Beta"
        $Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assign"
            
        try {

            if(!$ConfigurationPolicyId){
                write-host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red
                break
            }

            if(!$TargetGroupId){
                write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
                break
            }

            $ConfPolAssign = "$ConfigurationPolicyId" + "_" + "$TargetGroupId"            

            $JSON = @"
            {
            "deviceConfigurationGroupAssignments": [
                {
                "@odata.type": "#microsoft.graph.deviceConfigurationGroupAssignment",
                "id": "$ConfPolAssign",
                "targetGroupId": "$TargetGroupId",
                "excludeGroup": true
                }
            ]
            }
"@
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        }        
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
            break
        }        
    }    
    
####################################################
    
    Function Get-AADGroup(){
    
    <#
    .SYNOPSIS
    This function is used to get AAD Groups from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Groups registered with AAD
    .EXAMPLE
    Get-AADGroup
    Returns all users registered with Azure AD
    .NOTES
    NAME: Get-AADGroup
    #>
    
    [cmdletbinding()]
    
    param
    (
        $GroupName,
        $id,
        [switch]$Members
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    $Group_resource = "groups"
    # pseudo-group identifiers for all users and all devices
    [string]$AllUsers   = "acacacac-9df4-4c7d-9d50-4ef0226f57a9"
    [string]$AllDevices = "adadadad-808e-44e2-905a-0b7873a8a531"
    
        try {
    
            if($id){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
            switch ( $id ) {
                    $AllUsers   { $grp = [PSCustomObject]@{ displayName = "All users"}; $grp           }
                    $AllDevices { $grp = [PSCustomObject]@{ displayName = "All devices"}; $grp         }
                    default     { (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value  }
                    }
                    
            }
    
            elseif($GroupName -eq "" -or $GroupName -eq $null){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
            }
    
            else {
    
                if(!$Members){
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
                }
    
                elseif($Members){
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
                    if($Group){
    
                    $GID = $Group.id
    
                    $Group.displayName
                    write-host
    
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
                    }
    
                }
    
            }
    
        }
    
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    }
    
    ####################################################
    
    Function New-AADGroup(){

        <#
        .SYNOPSIS
        This function is used to create AAD Groups from the Graph API REST interface
        .DESCRIPTION
        The function connects to the Graph API Interface and creates an Azure AD Group
        .EXAMPLE
        New-AADGroup
        Creates an Azure AD Group
        .NOTES
        NAME: New-AADGroup
        #>
        
        [cmdletbinding()]
        
        param
        (
            $GroupAlias,
            $GroupDisplayName,
            $GroupDescription            
        )
        
        # Defining Variables
        $graphApiVersion = "v1.0"
        $Group_resource = "groups"

            #POST https://graph.microsoft.com/v1.0/groups                                
                        
        try {

            $JSON = @"
            
            {			
                "description": "$GroupDescription",
                "displayName": "$GroupDisplayName",
                "groupTypes": [],	
                "mailEnabled": false,
                "mailNickname": "$GroupAlias",
                "securityEnabled": true
            }
"@

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        }
        
        catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break

        }
    }

    ####################################################

    Function Convert-ProfileNameToGroup(){
        <#
        .SYNOPSIS
        This function is used to remove any special characters from Intune profile name and adopt it to use for AAD group name. 
        .DESCRIPTION
        This function is used to remove any special characters from Intune profile name and adopt it to use for AAD group name.
        .EXAMPLE
        Convert-ProfileNameToGroup        
        .NOTES
        NAME: Convert-ProfileNameToGroup
        #>                
        
        param
        (
            [string]$ProfileName,
            [string]$GroupPrefix
        )

        $special_chars = ("[", "\", "!", "#", "$", "%", "&", "*", "+", "/", "=", "?", "^", "``", "{", "}", "|", "~", "<", ">", "(", ")", "‘", ";", ":", ",", "]", "`"", "@", " ");
                
        [string]$GroupName = $GroupPrefix + $ProfileName;

        foreach($char in $special_chars){            
            $GroupName = $GroupName.Replace($char, "_")
        }
        
        #check mailnickname max length (can't be more than 63 bytes)
        if ($GroupName.Length -ge 63)
        {
            return ($GroupName.Remove(59) + $ProfileName.Length) # workaround if profile name is too long: cut everything after 59 symbols and add length of profile name to avoid conflicts
        } 
        else {
            return $GroupName
        }
    }


    ############################################################################################
    # Script starts here
    ############################################################################################
    
    #region Variables
    
    $groupPrefix = "intune_exc-" #prefix for group names
    $GroupDescriptionPrefix = "Group for intune profile " #prefix for groups description
    
    #endregion

    Clear-Host

    #region Authentication
    
    write-host "Authenticating..."
    write-host
    
    # Checking if authToken exists before running authentication
    if($global:authToken){
    
        # Setting DateTime to Universal time to work in all timezones
        $DateTime = (Get-Date).ToUniversalTime()
    
        # If the authToken exists checking when it expires
        $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
    
            if($TokenExpires -le 0){
    
            write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
            write-host
    
                # Defining User Principal Name if not present
    
                if($User -eq $null -or $User -eq ""){
    
                $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                Write-Host
    
                }
    
            $global:authToken = Get-AuthToken -User $User
    
            }
    }
    
    # Authentication doesn't exist, calling Get-AuthToken function
    
    else {
    
        if($User -eq $null -or $User -eq ""){
    
        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host
    
        }
    
    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User
    
    }
    
    #endregion
    
    ####################################################
    
    # get Intune config profiles
    write-host "Getting all configuration profiles..."
    write-host
    $DCPs = Get-DeviceConfigurationPolicy    

    if (($DCPs.Count -lt 1) -or ($DCPs -eq $null) ) {
        Write-Host "Couldn't load configuration profiles. Exiting now." -f Red
        break
    }
    
        
    foreach($DCP in $DCPs)
    {        
        [bool]$groupAssignedFlag = $false;

        write-host "Device Configuration Profile: `"$($DCP.displayName)`""        

        $id = $DCP.id

        # Getting profile name and normilize it to use as AAD group
        $groupName = Convert-ProfileNameToGroup -ProfileName $DCP.displayName -GroupPrefix $groupPrefix

        #checking if AAD group already exist
        write-host "`tChecking if group `"$groupName`" already exist"
        $aadgroup = $null
        $aadgroup = Get-AADGroup -GroupName $groupName
        if ($aadgroup)
        {            
            write-host "`tGroup `"$groupName`" already exist in Azure AD!" -f Yellow            
        } else {
            write-host "`tGroup `"$groupName`" doesn't exist in Azure AD!" -f Yellow
            write-host "`tCreating new AAD group: `"$groupName`"." -f Green
                        
            $groupDisplayName = $groupName
            $groupDescription = $GroupDescriptionPrefix + $DCP.displayName            
            $aadgroup = New-AADGroup -GroupAlias $groupName -GroupDisplayName $groupDisplayName -GroupDescription $groupDescription            
            if ($aadgroup)
            {
                write-host "`tGroup has been created." -f Green
            }
        }

        write-host "`tLooking for a group `"$groupName`" in the profile assignments"        

        # Getting Configuration Policy assignments and looking for existing exclude groups
        $DCPA = Get-DeviceConfigurationPolicyAssignment -id $id               

        if($DCPA){
            if($DCPA.count -gt 1){
                foreach($group in $DCPA){                                        
                    # check if "exclusion" group exists and assigned to profile (multiple assignments)                        
                    if ($group.targetGroupId -eq $aadgroup.id){
                        $groupAssignedFlag = $true;
                        write-host "`tExclusion group already assigned. No action needed." -f Cyan
                    }
                }
            }            
            else {                
                # check if "exclusion" group exist and assigned at profile (single assignment)
                if ($DCPA.targetGroupId -eq $aadgroup.id){
                    $groupAssignedFlag = $true;
                    write-host "`tExclusion group already assigned. No action needed." -f Cyan
                }
            }
        }
        else {
            Write-Host "`tNo assignments found."
        }

        if ($groupAssignedFlag -eq $false) {
            # Assigning exclusion group to the profile
            write-host "`tNo exclusion groups assigned to the profile. Assigning `"$($aadgroup.displayName)`" as exclusion group." -f Green

            Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $id -TargetGroupId $aadgroup.id                        
        }

        write-host
    }
    write-host "`tAll Done!" -f Cyan
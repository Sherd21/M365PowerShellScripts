<# 

 .SYNOPSIS
  Generates a CSV reports for how many times senders from EOP Allow lists where found in mail logs.
  
 .DESCRIPTION
  THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
  OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

 .PARAMETER startDate
  Mandatory parameter. Start date of MessageTrace search. Start date can't be further than 30 days from EndDate. (example "01/10/2019")

 .PARAMETER endDate
  Mandatory parameter. End date of MessageTrace search. Start date can't be further than 30 days from EndDate. (example "01/26/2019")

 .PARAMETER reportsPath
  Optional patameter. Path where script will save reports. By default, current script directory is used.
 
 .NOTES
  Script should be executed in PowerShell console with Exchange Online session established

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------
param(
    [Parameter(Mandatory=$true)]
    [datetime]$startDate,                 
    [Parameter(Mandatory=$true)]
    [datetime]$endDate,                   
    [string]$reportsPath = $PSScriptRoot  #  current directory of the script
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
#Set Error Action to Stop - script will stop execution on any error
$ErrorActionPreference = 'Stop'

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$WhitelistedEmailAddresses = @{};
$WhitelistedDomains = @{};

$mailflowEmailAddresses = @();
$mailflowEmailDomain = @();

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-AllowListsFromEOP()
{
    # collect all whitelisted email addresses and domains from EOP policies
    $EOPPolicies = Get-HostedContentFilterPolicy # connection to Exchnage Online to get current EOP Policies

    foreach ($EOPPolicy in $EOPPolicies)
    {            
        foreach($senderEmail in $EOPPolicy.AllowedSenders)
        {
            $WhitelistedEmailAddresses.Add($senderEmail.Sender.Address, $EOPPolicy.Name);
        }

        foreach($senderDomain in $EOPPolicy.AllowedSenderDomains)
        {
            $WhitelistedDomains.Add($senderDomain.Domain, $EOPPolicy.Name);
        }
    }
}

Function Get-MessageTraceLogs()
{
    #collect MessageTrace logs for specific period
    $MessageTrace = Get-MessageTrace -StartDate $startDate -EndDate $endDate   #connection to Exchnage Online to get MessageTrace logs

    foreach ($sender in $MessageTrace)
    {
        if ($sender.SenderAddress.Split('@').Count -eq 2) # lazy check if email in proper format
        {
            $mailflowEmailAddresses += $sender.SenderAddress;
            $mailflowEmailDomain    += $sender.SenderAddress.Split('@')[1];
        }
    }
}

Function Search-MessageTraceLogsForAllowedSenders()
{
    # search MessageTrace logs for Allowed Sender domains
    [System.Collections.ArrayList]$reportDomains = @()

    foreach($wdomain in $WhitelistedDomains.GetEnumerator())
    {
        $cnt = ($mailflowEmailDomain -match $wdomain.Key).Count

        $reportDomain = [PSCustomObject]@{
            DomainName          = $wdomain.Key
            Count               = $cnt
            Policy              = $wdomain.Value
        }

        $reportDomains.Add($reportDomain) >> $null
    }
    return $reportDomains
}

Function Search-MessageTraceLogsForAllowedEmailAddresses()
{
    # search MessageTrace logs for Allowed Sender email addresses    
    [System.Collections.ArrayList]$reportEmailAddresses = @()

    foreach($wemails in $WhitelistedEmailAddresses.GetEnumerator())
    {
        $cnt = ($mailflowEmailAddresses -match $wemails.Key).Count

        $reportEmailAddress = [PSCustomObject]@{
            EmailAddress        = $wemails.Key
            Count               = $cnt
            Policy              = $wemails.Value
        }

        $reportEmailAddresses.Add($reportEmailAddress) >> $null        
    }
    return $reportEmailAddresses
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

"Collecting EOP policy information..." | Write-Host -ForegroundColor Yellow
Get-AllowListsFromEOP  # collect all whitelisted email addresses and domains from EOP policies

"Collecting MessageTrace logs between $startDate and $endDate..." | Write-Host -ForegroundColor Yellow
Get-MessageTraceLogs   #collect MessageTrace logs for specific period

"Searching whitelisted domains in MessageTrace logs..." | Write-Host -ForegroundColor Yellow
$reportDomains = Search-MessageTraceLogsForAllowedSenders   # search MessageTrace logs for Allowed Senders

"Searching whitelisted email addresses in MessageTrace logs..." | Write-Host -ForegroundColor Yellow
$reportEmailAddresses = Search-MessageTraceLogsForAllowedEmailAddresses # search MessageTrace logs for Allowed Sender email addresses

"Writing a report to $reportsPath\Domains.csv..." | Write-Host -ForegroundColor Yellow
$reportDomains | Sort-Object Count | Export-Csv -Path "$reportsPath\Domains.csv" -NoTypeInformation # save domains report to CSV

"Writing a report to $reportsPath\EmailAddresses.csv..." | Write-Host -ForegroundColor Yellow
$reportEmailAddresses | Sort-Object Count | Export-Csv -Path "$reportsPath\EmailAddresses.csv" -NoTypeInformation -Force # save email adresses report to CSV

"All done!" | Write-Host -ForegroundColor Green
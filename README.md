# M365PowerShellScripts
Collection of PowerShell scripts for Microsoft 365 administration

This repo is a collection of different PowerShell scripts to automate some Microsoft 365 administration tasks.

* **Search-WhitelistedSendersInMailLogs** - generates reports on how many times senders from EOP Allow lists were found in mail logs.
* **Create-IntuneProfileExceptionGroups** - creates Azure AD group for Intune Confguration profiles in "Assignment - Exclude" section. It creates and ability to disable a profile for troubleshooting purposes by simply adding a device to an AAD group with the same name as profile. 
* **Generate-FakeRecords** - generates customizable set of fake PII records like ID, Name, SSN, Date of Birth, Email address for testing or simulation purposes.

## Disclaimer
>The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

<#
.SYNOPSIS
Exports firewall rules to a CSV or JSON file.
.DESCRIPTION
Exports firewall rules to a CSV or JSON file. Local and policy based rules will be given out.
CSV files are semicolon separated (Beware! Excel is not friendly to CSV files).
.PARAMETER Name
Display name of the rules to be processed. Wildcard character * is allowed.
.PARAMETER CSVFile
Output file
.PARAMETER JSON
Output in JSON instead of CSV format
.NOTES
Author: Markus Scholtes
Version: 1.01
Build date: 2018/03/27
.EXAMPLE
Export-FirewallRules.ps1
Exports all firewall rules to the CSV file FirewallRules.csv in the current directory.
.EXAMPLE
Export-FirewallRules.ps1 snmp* SNMPRules.json -json
Exports all SNMP firewall rules to the JSON file SNMPRules.json.
#>
Param($Name = "*", $CSVFile = ".\FirewallRules.csv", [SWITCH]$JSON)

#Requires -Version 4.0

# convert Stringarray to comma separated liste (String)
function StringArrayToList($StringArray)
{
	if ($StringArray)
	{
		$Result = ""
		Foreach ($Value In $StringArray)
		{
			if ($Result -ne "") { $Result += "," }
			$Result += $Value
		}
		return $Result
	}
	else
	{
		return ""
	}
}


# read firewall rules
$FirewallRules = Get-NetFirewallRule -DisplayName $Name -PolicyStore "ActiveStore"

# start array of rules
$FirewallRuleSet = @()
ForEach ($Rule In $FirewallRules)
{ # iterate throug rules
	Write-Output "Processing rule `"$($Rule.DisplayName)`" ($($Rule.Name))"

	# Retrieve addresses,
	$AdressFilter = $Rule | Get-NetFirewallAddressFilter
	# ports,
	$PortFilter = $Rule | Get-NetFirewallPortFilter
	# application,
	$ApplicationFilter = $Rule | Get-NetFirewallApplicationFilter
	# service,
	$ServiceFilter = $Rule | Get-NetFirewallServiceFilter
	# interface,
	$InterfaceFilter = $Rule | Get-NetFirewallInterfaceFilter
	# interfacetype
	$InterfaceTypeFilter = $Rule | Get-NetFirewallInterfaceTypeFilter
	# and security settings
	$SecurityFilter = $Rule | Get-NetFirewallSecurityFilter

	# generate sorted Hashtable
	$HashProps = [PSCustomObject]@{
		Name = $Rule.Name
		DisplayName = $Rule.DisplayName
		Description = $Rule.Description
		Group = $Rule.Group
		Enabled = $Rule.Enabled
		Profile = $Rule.Profile
		Platform = StringArrayToList $Rule.Platform
		Direction = $Rule.Direction
		Action = $Rule.Action
		EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
		LooseSourceMapping = $Rule.LooseSourceMapping
		LocalOnlyMapping = $Rule.LocalOnlyMapping
		Owner = $Rule.Owner
		LocalAddress = StringArrayToList $AdressFilter.LocalAddress
		RemoteAddress = StringArrayToList $AdressFilter.RemoteAddress
		Protocol = $PortFilter.Protocol
		LocalPort = StringArrayToList $PortFilter.LocalPort
		RemotePort = StringArrayToList $PortFilter.RemotePort
		IcmpType = StringArrayToList $PortFilter.IcmpType
		DynamicTarget = $PortFilter.DynamicTarget
		Program = $ApplicationFilter.Program -Replace "$($ENV:SystemRoot.Replace("\","\\"))\\", "%SystemRoot%\" -Replace "$(${ENV:ProgramFiles(x86)}.Replace("\","\\").Replace("(","\(").Replace(")","\)"))\\", "%ProgramFiles(x86)%\" -Replace "$($ENV:ProgramFiles.Replace("\","\\"))\\", "%ProgramFiles%\"
		Package = $ApplicationFilter.Package
		Service = $ServiceFilter.Service
		InterfaceAlias = StringArrayToList $InterfaceFilter.InterfaceAlias
		InterfaceType = $InterfaceTypeFilter.InterfaceType
		LocalUser = $SecurityFilter.LocalUser
		RemoteUser = $SecurityFilter.RemoteUser
		RemoteMachine = $SecurityFilter.RemoteMachine
		Authentication = $SecurityFilter.Authentication
		Encryption = $SecurityFilter.Encryption
		OverrideBlockRules = $SecurityFilter.OverrideBlockRules
	}

	# add to array with rules
	$FirewallRuleSet += $HashProps
}

if (!$JSON)
{ # output rules in CSV format
	$FirewallRuleSet | ConvertTo-CSV -NoTypeInformation -Delimiter ";" | sc $CSVFile
}
else
{ # output rules in JSON format
	$FirewallRuleSet | ConvertTo-JSON | sc $CSVFile
}

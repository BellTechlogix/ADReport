<#
ADReport.ps1
Created By Kristopher Roy
Date Created 25Jan15
Date Modified 06Oct17
Script purpose - Gather details about an Active Directory Environment
#>

#This Function creates a dialogue to return a Folder Path
function Get-Folder {
    param([string]$Description="Select Folder to place results in",[string]$RootFolder="Desktop")

 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
     Out-Null     

   $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.Rootfolder = $RootFolder
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()
        If ($Show -eq "OK")
        {
            Return $objForm.SelectedPath
        }
        Else
        {
            Write-Error "Operation cancelled by user."
        }
}

#File Select Function - Lets you select your input file
function Get-FileName
{
  param(
      [Parameter(Mandatory=$false)]
      [string] $Filter,
      [Parameter(Mandatory=$false)]
      [switch]$Obj,
      [Parameter(Mandatory=$False)]
      [string]$Title = "Select A File"
    )
   if(!($Title)) { $Title="Select Input File"}
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.FileName = $Title
	#can be set to filter file types
	IF($Filter -ne $null){
		$FilterString = '{0} (*.{1})|*.{1}' -f $Filter.ToUpper(), $Filter
		$OpenFileDialog.filter = $FilterString}
	if(!($Filter)) { $Filter = "All Files (*.*)| *.*"
		$OpenFileDialog.filter = $Filter}
	$OpenFileDialog.ShowDialog() | Out-Null
	IF($OBJ){
		$fileobject = GI -Path $OpenFileDialog.FileName.tostring()
		Return $fileObject}
	else{Return $OpenFileDialog.FileName}
}

#2 Option Function - A Basic Dynamic 2 option User Prompt Function
function user-prompt
{
	#If Select1 and 2 are not defined deafault is Yes,No
	param(
		#Title Defines Header for Prompt
		[Parameter(Mandatory=$false)]
		[string] $Title,
		#Message Defines Body of Prompt
		[Parameter(Mandatory=$False)]
		[string]$Message,
		#Select1 Defines First of two options
		[Parameter(Mandatory=$False)]
		[string]$Select1,
		#Select2 Define Second of two options
		[Parameter(Mandatory=$False)]
		[string]$Select2,
		#String to Display what first option means in a tooltip
		[Parameter(Mandatory=$False)]
		[string]$Selection1ToolTip,
		#String to Display what second option means in a tooltip
		[Parameter(Mandatory=$False)]
		[string]$Selection2ToolTip
    )

    If($Title -eq $Null -or $Title -eq ""){$title = "Selection"}
    If($Select1 -eq $Null -or $Select1 -eq ""){$Select1 = "Yes"}
	$selection1 = New-Object System.Management.Automation.Host.ChoiceDescription "&$Select1", `
	$selection1ToolTip
    If($Select2 -eq $Null -or $Select2 -eq ""){$Select2 = "No"}
	$selection2 = New-Object System.Management.Automation.Host.ChoiceDescription "&$Select2", `
	$selection2ToolTip
    If($message -eq $Null -or $Message -eq ""){$message = "Basic $select1,$select2 Options"}
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($selection1, $selection2)
    $choice = $host.ui.PromptForChoice($title, $message, $options, 0)    
    $choice = [int]$choice
    Return $choice
    #Returns selection1 = 0, and selection2 = 1

<#
	example 1 - No switches defined:
	user-prompt
	Result = A Yes,No prompt with Title "Selection", Body "Basic Yes,No Options"
		
	example 2 - Selections Defined
	user-prompt -select1 "blue" -select2 "green"
	Result = A blue,green prompt with Title "Selection" Body "Basic Blue,Green Options"
		
	Output will always be 0,1
#>
}

#This function lets you build an array of specific list items you wish
Function MultipleSelectionBox ($inputarray,$prompt,$listboxtype) {
 
# Taken from Technet - http://technet.microsoft.com/en-us/library/ff730950.aspx
# This version has been updated to work with Powershell v3.0.
# Had to replace $x with $Script:x throughout the function to make it work. 
# This specifies the scope of the X variable.  Not sure why this is needed for v3.
# http://social.technet.microsoft.com/Forums/en-SG/winserverpowershell/thread/bc95fb6c-c583-47c3-94c1-f0d3abe1fafc
#
# Function has 3 inputs:
#     $inputarray = Array of values to be shown in the list box.
#     $prompt = The title of the list box
#     $listboxtype = system.windows.forms.selectionmode (None, One, MutiSimple, or MultiExtended)
 
$Script:x = @()
 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
 
$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = $prompt
$objForm.Size = New-Object System.Drawing.Size(300,600) 
$objForm.StartPosition = "CenterScreen"
 
$objForm.KeyPreview = $True
 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {
        foreach ($objItem in $objListbox.SelectedItems)
            {$Script:x += $objItem}
        $objForm.Close()
    }
    })
 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})
 
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,520)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
 
$OKButton.Add_Click(
   {
        foreach ($objItem in $objListbox.SelectedItems)
            {$Script:x += $objItem}
        $objForm.Close()
   })
 
$objForm.Controls.Add($OKButton)
 
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,520)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)
 
$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Please make a selection from the list below:"
$objForm.Controls.Add($objLabel) 
 
$objListbox = New-Object System.Windows.Forms.Listbox 
$objListbox.Location = New-Object System.Drawing.Size(10,40) 
$objListbox.Size = New-Object System.Drawing.Size(260,20) 
 
$objListbox.SelectionMode = $listboxtype
 
$inputarray | ForEach-Object {[void] $objListbox.Items.Add($_)}
 
$objListbox.Height = 470
$objForm.Controls.Add($objListbox) 
$objForm.Topmost = $True
 
$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
 
Return $Script:x
}

#Check for Pre-Existing CSVDE Report
$csvdechoice = $NULL
$csvdechoice = user-prompt -Title "CSVDE Report Status" -Message "Do you already have an exported CSVDE Report that you wish to use?" -Selection1ToolTip "Says that you already have an exported report that you wish to use." -Selection2ToolTip "Tells the system you need a report."
If($csvdechoice -eq 0){
	$file = Get-FileName -Title "Select Your CSVDExport file" -Filter "csv" -obj
	#$ADExport = Import-Csv $file
}
#FullADReport
#CSVDE Is a comprehensive AD tool that pulls a whole lot of AD Data
If($csvdechoice -eq 1 -or $ADExport -eq $NULL)
{
	#Folder Location for Reports
	$folder = get-folder -Description "Select folder you wish to place reports in"
	Write-Host "No CSVDE import found Gathering CSVDE Report this may take some time"
	CSVDE -F $folder\CSVDEADExport.csv
	#Import CSVDE CSV Report as Object
	#$ADExport = Import-Csv $folder\CSVDEADExport.csv
	$file = "$folder\CSVDEADExport.csv"
}
IF($folder -eq $null -or $folder -eq ""){$folder = $file.DirectoryName}
#Select Report Types You Wish
$options01 = "Users","Machines","Both"
$reportselection = MultipleSelectionBox -listboxtype one -inputarray $options01

$dcs = Get-ADDomainController -Filter *

#deffinition for UAC codes
$lookup = @{4096="Workstation/Server"; 4098="Disabled Workstation/Server"; 4128="Workstation/Server No PWD"; 
4130="Disabled Workstation/Server No PWD"; 528384="Workstation/Server Trusted for Delegation";
528416="Workstation/Server Trusted for Delegation"; 532480="Domain Controller"; 66176="Workstation/Server PWD not Expire"; 
66178="Disabled Workstation/Server PWD not Expire";512="User Account";514="Disabled User Account";66048="User Account PWD Not Expire";66050="Disabled User Account PWD Not Expire"}

#Timestamp for Reference
$time = Get-Date

#Select Only Machines
IF($reportselection -eq "Machines" -or $reportselection -eq "Both")
{
	$computers = Import-Csv $file|where-object{$_.objectClass -eq "computer"}|Select-Object -Property Name,operatingSystem,operatingSystemVersion,operatingSystemServicePack,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,description,cn,DN,memberOf,badPasswordTime,pwdLastSet,accountExpires,IPv4Address
	#Doublecheck and format AD Report for PC's
	FOREACH ($computer in $computers)
	{
		$PC = $DCs |% { Get-ADComputer -Server $_.DNSHostName $computer.name -Properties * } | sort-object -property lastLogondate| select -Last 1
		$IP = ($DCs |% { Get-ADComputer -Server $_.DNSHostName $computer.name -Properties IPv4Address } | sort-object -property IPv4Address| select -Last 1).IPv4Address
		IF($IP -ne $NULL){$computer.IPv4Address = $PC.IPv4Address}ELSE{$computer.IPv4Address = "0.0.0.0"}
		$computer.lastlogondate = Try{Get-Date $PC.lastlogondate -format "M/d/yyyy hh:mm tt"}catch{}
		try{$computer.dayssincelogon = (New-TimeSpan -start $computer.lastlogondate -end $time).days}catch{$computer.dayssincelogon = "Null"}
		$computer.whenCreated = Try{Get-Date $PC.whenCreated -format "M/d/yyyy hh:mm tt"}catch{}
		$computer.whenChanged = Try{Get-Date $PC.whenChanged -format "M/d/yyyy hh:mm tt"}catch{}
		$computer.badPasswordTime = Try{Get-Date $PC.badPasswordTime -format "M/d/yyyy hh:mm tt"}catch{}
		IF($computer.pwdLastSet -ne $NULL){$computer.pwdLastSet = ([datetime]::fromfiletime($PC.pwdLastSet)|Get-Date -format "M/d/yyyy hh:mm tt")}
		IF($PC.accountExpires -eq "9223372036854775807"){$computer.accountExpires = "Never"}
		ELSE{try{$computer.accountExpires = Get-Date $PC.accountExpires -format "M/d/yyyy hh:mm tt"}Catch{}}
		$computer.userAccountControl = $lookup[$PC.userAccountControl]
	}
	$computers|export-csv $folder\ComputerExport.csv -NoTypeInformation
	#Workstation Count By OS, Version, and Service Pack
	$resultsarray =@()
	$Vers = $computers|select-object operatingSystemVersion,OperatingSystem,OperatingSystemServicePack -unique
	FOREACH($Ver in $Vers)
	{
		#$PCs = $PCExport|where-object{$_.operatingSystem -eq "Windows Server 2003"}
		$PCs = $computers|where-object{$_.operatingSystemVersion -eq $Ver.operatingSystemVersion -and $_.operatingSystem -eq $Ver.operatingSystem -and $_.operatingSystemServicePack -eq $Ver.operatingSystemServicePack}
		$curOS = $PCs|select-object operatingSystemVersion,OperatingSystem,OperatingSystemServicePack -unique
		$OSobject = New-Object PSObject
		$OSobject|add-member -MemberType NoteProperty -name "Count" -value $PCs.operatingSystem.Count
		$uniqueOS = $curOS|select-object OperatingSystem -Unique
		$OSobject|add-member -MemberType NoteProperty -name "OS" -value $uniqueOS.operatingSystem
		$OSobject|add-member -MemberType NoteProperty -name "Version" -value ($curOS|select-object OperatingSystemVersion -Unique).operatingSystemVersion
		$OSobject|add-member -MemberType NoteProperty -name "SP" -value ($curOS|select-object OperatingSystemServicePack -Unique).operatingSystemServicePack
		$resultsarray += $OSobject
	}
	$resultsarray|export-csv $folder\WorkstationCount.csv -NoTypeInformation -Encoding UTF8
}

#Select Only Users
IF($reportselection -eq "Users" -or $reportselection -eq "Both")
{
	$users = Import-Csv $file|where-object{$_.objectClass -eq "user"}|Select-Object -Property SamAccountName,givenName,sn,telephoneNumber,mobile,mail,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,description,office,City,cn,DN,memberOf,badPasswordTime,pwdLastSet,LockedOut,accountExpires
	#Doublecheck and format AD Report for Users
	$i = 0
	FOREACH ($user in $users)
	{
		$i++
		Write-Progress -Activity ("Gathering User Date . . ."+$user.SamAccountName) -Status "Scanned: $i of $($users.Count)" -PercentComplete ($i/$users.Count*100)
		$curuser = $DCs |% { Get-ADUser -Server $_.HostName $user.sAMAccountName -Properties * } | sort-object -property lastLogondate| select -Last 1
		$user.lastlogondate = Try{Get-Date $curuser.lastlogondate -format "M/d/yyyy hh:mm tt"}catch{}
		try{$user.dayssincelogon = (New-TimeSpan -start $user.lastlogondate -end $time).days}catch{$user.dayssincelogon = "Null"}
		$user.whenCreated = Try{Get-Date $curuser.whenCreated -format "M/d/yyyy hh:mm tt"}catch{}
		$user.whenChanged = Try{Get-Date $curuser.whenChanged -format "M/d/yyyy hh:mm tt"}catch{}
		$user.badPasswordTime = Try{Get-Date $curuser.badPasswordTime -format "M/d/yyyy hh:mm tt"}catch{}
		IF($user.pwdLastSet -ne $NULL){$user.pwdLastSet = ([datetime]::fromfiletime($curuser.pwdLastSet)|Get-Date -format "M/d/yyyy hh:mm tt")}
		IF($user.accountExpires -eq "9223372036854775807"){$user.accountExpires = "Never"}
		ELSE{try{$user.accountExpires = Get-Date $curuser.accountExpires -format "M/d/yyyy hh:mm tt"}Catch{}}
		$user.userAccountControl = $lookup[$curuser.userAccountControl] 
	}
	$users|export-csv $folder\UserExport.csv -NoTypeInformation
	#Account Counts
	$accountsarray =@()
	$Countobject = New-Object PSObject
	$Countobject|add-member -MemberType NoteProperty -name "UserCount" -value $users.count
	$Countobject|add-member -MemberType NoteProperty -name "Groups" -value (Import-Csv $file|where-object{$_.objectClass -eq "group"}).count
	$Countobject|add-member -MemberType NoteProperty -name "Ou's/Containers" -value ((Import-Csv $file|where-object{$_.objectClass -eq "container"}).count + ($ADExport|where-object{$_.objectClass -eq "organizationalUnit"}).count)
	$Countobject|add-member -MemberType NoteProperty -Name "Disabled Users" -Value ($users|where-object{$_.userAccountControl -ilike "Disabled*"}).count
	$Countobject|add-member -MemberType NoteProperty -Name "Users Pwd Not Expire" -Value ($users|where-object{$_.userAccountControl -ilike "*PWD Not Expire"}).count
	$Countobject|add-member -MemberType NoteProperty -Name "Users No Logon last 30" -Value (($users|where-object{$_.dayssincelogon -ge 30}).count)
	$accountsarray += $Countobject
	$accountsarray|export-csv $folder\AccountStructureCount.csv -NoTypeInformation -Encoding UTF8
}
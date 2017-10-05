#FullADReport
CSVDE -F c:\belltech\ADExport.csv

#Import CSV as Object
$ADExport = Import-Csv c:\belltech\ADExport.csv
$computers = $ADExport|where-object{$_.objectClass -eq "computer"}|Select-Object -Property Name,operatingSystem,operatingSystemVersion,operatingSystemServicePack,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,description,cn,DN,memberOf,badPasswordTime,pwdLastSet,accountExpires,IPv4Address
$users = $ADExport|where-object{$_.objectClass -eq "user"}|Select-Object -Property SamAccountName,givenName,sn,telephoneNumber,mobile,mail,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,description,office,City,cn,DN,memberOf,badPasswordTime,pwdLastSet,LockedOut,accountExpires
#$PSUsers = Get-ADUser -Properties * -Filter *
$dcou = "ou=domain controllers,dc=ngkacu,dc=com"
$dcs = Get-ADComputer -searchbase $dcou -filter '*'|where-object{$_.name -ne "DC1"}

#deffinition for UAC codes
$lookup = @{4096="Workstation/Server"; 4098="Disabled Workstation/Server"; 4128="Workstation/Server No PWD"; 
4130="Disabled Workstation/Server No PWD"; 528384="Workstation/Server Trusted for Delegation";
528416="Workstation/Server Trusted for Delegation"; 532480="Domain Controller"; 66176="Workstation/Server PWD not Expire"; 
66178="Disabled Workstation/Server PWD not Expire";512="User Account";514="Disabled User Account";66048="User Account PWD Not Expire";66050="Disabled User Account PWD Not Expire"}

#Timestamp for Reference
$time = Get-Date


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
$computers|export-csv c:\belltech\ComputerExport.csv -NoTypeInformation

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
$resultsarray|export-csv c:\belltech\WorkstationCount.csv -NoTypeInformation -Encoding UTF8

#Doublecheck and format AD Report for Users
FOREACH ($user in $users)
{
   $curuser = $DCs |% { Get-ADUser -Server $_.DNSHostName $user.sAMAccountName -Properties * } | sort-object -property lastLogondate| select -Last 1
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
$users|export-csv c:\belltech\UserExport.csv -NoTypeInformation

#Account Counts
$accountsarray =@()
$Countobject = New-Object PSObject
$Countobject|add-member -MemberType NoteProperty -name "UserCount" -value $users.count
$Countobject|add-member -MemberType NoteProperty -name "Groups" -value ($ADExport|where-object{$_.objectClass -eq "group"}).count
$Countobject|add-member -MemberType NoteProperty -name "Ou's/Containers" -value (($ADExport|where-object{$_.objectClass -eq "container"}).count + ($ADExport|where-object{$_.objectClass -eq "organizationalUnit"}).count)
$Countobject|add-member -MemberType NoteProperty -Name "Disabled Users" -Value ($users|where-object{$_.userAccountControl -ilike "Disabled*"}).count
$Countobject|add-member -MemberType NoteProperty -Name "Users Pwd Not Expire" -Value ($users|where-object{$_.userAccountControl -ilike "*PWD Not Expire"}).count
$Countobject|add-member -MemberType NoteProperty -Name "Users No Logon last 30" -Value (($users|where-object{$_.dayssincelogon -ge 30}).count)
$accountsarray += $Countobject
$accountsarray|export-csv c:\belltech\AccountStructureCount.csv -NoTypeInformation -Encoding UTF8
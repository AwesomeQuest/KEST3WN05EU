

$gpopath = "C:\GPOs"

class GPO {
    [string]$name
    [string]$id
    $path = $gpopath + "\" + $name

}


$employeeOU = "OU=company," + (Get-ADDomain).DistinguishedName

$GROUPS = @()
foreach($i in $env:GROUPS.Split(";")){$GROUPS += ,$i}

$groupsOUs = @()
foreach($i in $GROUPS){$groupsOUs += "OU=" + $i + "," + $employeeOU}

function linkSome ([GPO]$GPO, $groups){

    New-GPO -Name $GPO.name
    Import-GPO -Path $GPO.path -BackupId $GPO.id -TargetName $GPO.name

    foreach($group in $groups){
        New-GPLink -Name $GPO.name -Target $groupsOUs[$group]
        
        echo $GPO.name + "has been applied to " + $groupsOUs[$group] 
    }
}
function linkAll ([GPO]$GPO){

    New-GPO -Name $GPO.name
    Import-GPO -Path $GPO.path -BackupId $GPO.id -TargetName $GPO.name
    New-GPLink -Name $GPO.name -Target $employeeOU

    echo $GPO.name + "has been applied to all" 
    
}



foreach($GPO in (Get-ChildItem $gpopath).Name){
    if($GPO.Contains('&'))
    {
        $GPO1 = [GPO]::new()
        $GPO1.id = (Get-ChildItem "$gpopath\$GPO").Name
        $GPO1.name = $GPO

        $gprStr = $GPO.Split('&')[0]
        $grps = $gprStr.Split(' ')

        linkSome $GPO1 $grps

    }
    else
    {
        $GPO1 = [GPO]::new()
        $GPO1.id = (Get-ChildItem "$gpopath\$GPO").Name
        $GPO1.name = $GPO

        linkAll($GPO1)
    }
}


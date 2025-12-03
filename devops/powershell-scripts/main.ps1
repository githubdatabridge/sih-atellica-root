
param(
    [Parameter(Mandatory=$True)] 
    [string] $DB_name,
    [Parameter(Mandatory=$FALSE)] 
    [bool] $Uninstall=$FALSE
    ) 


write-host "`n----------------------------"
write-host " system requirements checking  "
write-host "----------------------------`n"

### require administator rights

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   write-Warning "This setup needs admin permissions. Please run this file as admin."     
   break
}

$sih_atellica_qplus_backend = "sih-atellica-qplus-backend"
$sih_atellica_qplus_frontend= "sih-atellica-qplus-frontend"
$sih_atellica_qlik_service = "sih-atellica-qlik-service"

$apps = $sih_atellica_qplus_backend, $sih_atellica_qlik_service, $sih_atellica_qplus_frontend

. .\funcs\run2.ps1

if($Uninstall){

    foreach ($app in $apps) {

        $toUninstall = $TRUE

        $confirmation = read-host "[$app] Do you want to run uninstall? [Y/n]"

        if ($confirmation -eq "n") {
            Write-Warning "[$app] Uninstall skiped"
            $toUninstall = $FALSE
        }

        if($toUninstall){ 
            UninstallService -Location $PSScriptRoot
        }
    } 
    return;
}

### nodejs version check

if (Get-Command node -errorAction SilentlyContinue) {
    $current_version = (node -v)
}
 
if ($current_version) {
    write-host "[NODE] nodejs $current_version installed"
} else {
    write-Warning "[NODE] nodejs not installed."     
    break
}

write-host "`n"

'Press any key to continue...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

foreach ($app in $apps) {

    $toRun = $TRUE

    $confirmation = read-host "[$app] Do you want to run deployment? [Y/n]"
    if ($confirmation -eq "n") {
        Write-Warning "[$app] Deployment skiped"
        $toRun = $FALSE
    }

    if($toRun){
        RunAppDeploy -Location $PSScriptRoot
    }
} 


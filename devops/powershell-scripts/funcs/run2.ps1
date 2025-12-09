function RunAppDeploy
{ 
    param(

       [Parameter(Mandatory=$True)] 
       [string] $Location
    ) 

    try {
        
        $repoDir = "$app"
        $DirLocation = "$Location\$repoDir"
        $repoExist = Test-Path -Path $DirLocation

        write-host "$DirLocation Exist => $repoExist"


        if(!$repoExist){

            write-host "Searching for zip file $app.zip"
            $ZipLocation = "$Location\$repoDir.zip"
            $zipExist = Test-Path -Path $ZipLocation 

            if(!$zipExist){
                throw "Directory or zip of $app not found."
            }

            UnzipService -Location $Location
        }
    
        Set-Location ".\$repoDir" 

        $buildExist = Test-Path -Path "./build"
		
        if(($app -ne $migration) -and $buildExist){
            'Checking for existing installation ...'
            npm run win-svc-uninstall
        }

        $envExist=Test-Path -Path ".\.env" -PathType Leaf

        if(!$envExist){
            Copy-Item ".env.example" ".env"
        }
        
        Start-Process WordPad ".env" -Wait

        if($app -eq $app_api){
            Start-Process WordPad "./src/configuration.json" -Wait

            # CHECK FOR CERS DIR
            'Copying server certificates ...'
            CopyCrts -FilesDir ".\certificates\server" -PathToCopy ".\build" -Files "server.cert", "server.key"
        }

        if($app -eq $qlik_service){
            # CHECK FOR CERS DIR
            'Copying server certificates ...'
            CopyCrts -FilesDir ".\certificates\server" -PathToCopy ".\build" -Files "server.cert", "server.key"
            'Copying qlik certificates ...'
            CopyCrts -FilesDir ".\certificates\qlik" -PathToCopy ".\build" -Files "client.pem", "client_key.pem", "root.pem"
        }

        if($app -eq $frontend){
            # CHECK FOR CERS DIR
            'Copying server certificates ...'
            CopyCrts -FilesDir ".\certificates\server" -Files "server.cert", "server.key" -JustCheck $True
        }

        if($app -eq $migration){
            npx db-migrate --config database.json db:create $DB_name -e test
            npx db-migrate up -e test
        }
        else{
            npm run win-svc-install
        }

        $repeat = $FALSE

        $confirmation = read-host "[$app] Deploying Done. Do you want to continue or repeat? [Y/n]"
        if ($confirmation -eq "n") {
            $repeat = $TRUE
        }

        if($repeat){
            Set-Location $Location
            Write-Warning "[$app] Repeating deployment..."
            RunAppDeploy -Location $Location
        }

    }
    catch {
        Write-Error $_ 
        throw "Deploying $app failed"
    }
    finally {
        Set-Location $Location
    }
}

function UnzipService 
{
    param(
        [Parameter(Mandatory=$True)] 
        [string] $Location
     ) 

    $ZipFile = "$Location\$app.zip"
    #Extract Zip File
    Write-Host 'Starting unzipping.'
    Expand-Archive -Path $ZipFile -DestinationPath $Location -Force
    Write-Host 'Unzip finished'
    
}

function CopyCrts
{
    param(
        [Parameter(Mandatory=$False)] 
        [bool] $JustCheck=$False,
        [Parameter(Mandatory=$True)] 
        [string[]] $Files,
        [Parameter(Mandatory=$True)] 
        [string] $FilesDir,
        [Parameter(Mandatory=$False)] 
        [string] $PathToCopy=".\build"
     ) 

    $filesMisiing = New-Object Collections.Generic.List[string]

    foreach ($file in $Files) {
        $filePath = "$FilesDir\$file"
        $exist = Test-Path -Path $filePath -PathType Leaf
        if(!$exist){
            $filesMisiing.Add($filePath);
        }
    }

    if($filesMisiing.count -gt 0){
        Write-Warning "Missing files:"
        Write-Warning "$($filesMisiing -join ',')"
        '\n'
        Write-Warning "Please add certificates to $app directory. For more infomation check README.md."

        $repeat = $FALSE

        $confirmation = read-host "[$app] Do you want to continue without certificates? [Y/n]"
        if ($confirmation -eq "n") {
            $repeat = $TRUE
        }

        if($repeat){
            Write-Warning "[$app] Repeating copy certificates."
            CopyCrts -JustCheck $JustCheck -Files $Files -FilesDir $FilesDir -PathToCopy $PathToCopy
        }
        else {
            return
        }
    }   
    else
    {
        if($JustCheck){
            return
        }

        foreach ($file in $Files) {
            $filePath = "$FilesDir\$file"
            $fileCopyToPath = "$PathToCopy\$(("$FilesDir\$file").Substring(2))"
			
			$certDir ="$PathToCopy\$($FilesDir.Substring(2))"
			
            $certDirExist = Test-Path -Path $certDir

			if(!$certDirExist){
                mkdir -p "$certDir"
            }

            Copy-Item $filePath $fileCopyToPath
            Write-Host "[$app] Copy certificates done."
        }
    }
}

function UninstallService {
    param(

       [Parameter(Mandatory=$True)] 
       [string] $Location
    ) 
    try {
        $repoDir = "$app"
        $DirLocation = "$Location\$repoDir"
        $repoExist = Test-Path -Path $DirLocation

        write-host "$DirLocation Exist => $repoExist"


        if(!$repoExist){
            write-host "Searching for zip file $app.zip"
            $ZipLocation = "$Location\$repoDir.zip"
            $zipExist = Test-Path -Path $ZipLocation 

            if(!$zipExist){
                throw "Directory or zip of $app not found."
            }


            $continue = $FALSE

            $confirmation = read-host "[$app] Folder not found. Do you want to unzip? [Y/n]"
            if ($confirmation -eq "n") {
                $continue = $TRUE
            }

            if(!$continue){
                return
            }
            UnzipService -Location $Location
        }

        Set-Location ".\$repoDir" 

        $buildExist = Test-Path -Path "./build"
        
        if(($app -ne $migration) -and $buildExist){
            'Checking for existing installation ...'
            npm run win-svc-uninstall
        }
    }
    catch {
        Write-Error $_ 
        throw "Uninstalling $app failed"
    }
    finally {
        Set-Location $Location
    }
    
    
}
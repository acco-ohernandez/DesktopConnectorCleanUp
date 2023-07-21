#
# Script.ps1
#
# Get the current Windows identity
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()

# Check if the current user is running with administrative privileges
$isAdmin = [Security.Principal.WindowsPrincipal]::new($currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch the script with elevated privileges
    Start-Process -FilePath PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# =============================================

# start log
Start-Transcript "$env:windir\Temp\DesktopConnecorCleanUp_ScriptLog.txt"
# =============================================
# Stop Desktop Connector Prosses if it's running
if (Get-Process "DesktopConnector.Applications.Tray" -ErrorAction SilentlyContinue)
{
    Write-Host "Terminating Process: DesktopConnector.Applications.Tray" -ForegroundColor Green
    Get-Process "DesktopConnector.Applications.Tray" | Stop-Process -Force
    Start-Sleep -Seconds 2
}
else{
    Write-Host "DesktopConnector.Applications.Tray Process is not Running" -ForegroundColor Yellow
}
# =============================================
# Get all the paths to be deleted if they exist
$AllUserProfileFolderPaths = Get-ChildItem "C:\Users" -Directory | Select-Object -ExpandProperty FullName
$PathsToDelete = @()
foreach ($userProfile in $AllUserProfileFolderPaths)
{
    $curPath = "$userProfile\Autodesk\Desktop Connector"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }
    
    $curPath = "$userProfile\Autodesk\Web Services\DesktopConnector"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }
    # Get the Local Desktop Connector Workspaces if they exist
    $curPath = "$userProfile\DC"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }

    $curPath = "$userProfile\ACCDocs"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }

    $curPath = "$userProfile\Fusion"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }

    $curPath = "$userProfile\ADrive"
    if (Test-Path $curPath -ErrorAction SilentlyContinue)
    {   
        Write-Host "Added to delete: $curPath" -ForegroundColor Green
        $PathsToDelete += $curPath; $curPath = $null
    }
    else
    {
        Write-Host "Path not found: $curPath" -ForegroundColor Yellow
    }
}

# add the following paths if they exist
"C:\Program Files\Autodesk\Desktop Connector", "C:\ProgramData\Autodesk\Desktop Connector" |
    ForEach-Object {
        if (Test-Path $_ -ErrorAction SilentlyContinue)
        {
            $PathsToDelete += $_
        }
        else
        {
            Write-Host "Path not found: $_" -ForegroundColor Yellow
        }
    }
# ==========>
function StopFileSystemMonitorService
{
    $serviceName = "Autodesk File System Monitor Service"
    if((Get-Service -Name $serviceName -ErrorAction SilentlyContinue).Status -eq "Running")
    {
        Write-Host "Stopping: `'$serviceName`'" -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force
        Start-Sleep -Seconds 3
        Write-Host "Stopped: `'$serviceName`'" -ForegroundColor Yellow
    }
}
# ==========>
# Delete all the paths in the array $PathsToDelete
#foreach ($path in $PathsToDelete)
#{
#    Write-Host "Deleting: $path" -ForegroundColor Cyan
#    #$Folder = Get-Item $path
#    #$Folder.Delete($true)
#    Remove-Item $path -Recurse -Force
#    #$Folder = $null # Reset the variable
#}
function RemoveDirectoryRecursive($directory)
{
    # create a temporary (empty) directory
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $tempDirectory = New-Item -ItemType Directory -Path (Join-Path $parent $name)

    try
    {
        robocopy /MIR $tempDirectory.FullName $directory | out-null
        Remove-Item $directory -Force -Recurse -Verbose #| out-null
    }
    finally
    {
        Remove-Item $tempDirectory -Force -Recurse -Verbose # | out-null
    }
}

# Stop the service before attempting to delete the Desktop Connector folders
StopFileSystemMonitorService
foreach ($path in $PathsToDelete)
{
    Write-Host "Deleting: $path" -ForegroundColor Cyan
    RemoveDirectoryRecursive($path)
}
# =============================================
# Delete the following registry keys if they exist:
$RegistryKeys = "HKCU:\SOFTWARE\Autodesk\Autodesk Desktop Connector", "HKLM:\SOFTWARE\Autodesk\Desktop Connector"
foreach ($registryPath in $RegistryKeys)
{
    # Check if the registry key exists
    if (Test-Path $registryPath)
    {
        # Delete the registry key and its subkeys
        Remove-Item -Path $registryPath -Recurse
        Write-Host "Registry key Deleted: '$registryPath'" -ForegroundColor Green
    }
    else
    {
        Write-Host "Registry key not found: '$registryPath'" -ForegroundColor Yellow
    }
}
Read-Host "Hit ENTER to Exit."
Stop-Transcript
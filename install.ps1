Set-StrictMode -Off
$ProgressPreference = 'SilentlyContinue'

$PROJECT_NAME = "kaldo"
$OWNER = "cpendery"
$REPO = "${PROJECT_NAME}"


Write-Host @"
 _           _     _       
| |         | |   | |      
| |  _ _____| | __| | ___  
| |_/ |____ | |/ _  |/ _ \ 
|  _ (/ ___ | ( (_| | |_| |
|_| \_)_____|\_)____|\___/ 
                           
cross shell aliases

https://github.com/cpendery/kaldo

Please file an issue if you encounter any problems!
===============================================================================

"@

# ------------------------------------------------------------------------
# source: https://get.scoop.sh
# ------------------------------------------------------------------------

function Publish-Env {
    if (-not ('Win32.NativeMethods' -as [Type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    }

    $HWND_BROADCAST = [IntPtr] 0xffff
    $WM_SETTINGCHANGE = 0x1a
    $result = [UIntPtr]::Zero

    [Win32.Nativemethods]::SendMessageTimeout($HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Environment',
        2,
        5000,
        [ref] $result
    ) | Out-Null
}

function Get-Env {
    param(
        [String] $name,
        [Switch] $global
    )

    $RegisterKey = if ($global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    }
    else {
        Get-Item -Path 'HKCU:'
    }

    $EnvRegisterKey = $RegisterKey.OpenSubKey('Environment')
    $RegistryValueOption = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    $EnvRegisterKey.GetValue($name, $null, $RegistryValueOption)
}

function Write-Env {
    param(
        [String] $name,
        [String] $val,
        [Switch] $global
    )

    $RegisterKey = if ($global) {
        Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    }
    else {
        Get-Item -Path 'HKCU:'
    }

    $EnvRegisterKey = $RegisterKey.OpenSubKey('Environment', $true)
    if ($val -eq $null) {
        $EnvRegisterKey.DeleteValue($name)
    }
    else {
        $RegistryValueKind = if ($val.Contains('%')) {
            [Microsoft.Win32.RegistryValueKind]::ExpandString
        }
        elseif ($EnvRegisterKey.GetValue($name)) {
            $EnvRegisterKey.GetValueKind($name)
        }
        else {
            [Microsoft.Win32.RegistryValueKind]::String
        }
        $EnvRegisterKey.SetValue($name, $val, $RegistryValueKind)
    }
    Publish-Env
}

function Add-DirToPath {
    param(
        [String] $dir
    )
    # Get $env:PATH of current user
    $userEnvPath = Get-Env 'PATH'

    if ($userEnvPath -notmatch [Regex]::Escape($dir)) {
        $h = (Get-PSProvider 'FileSystem').Home
        if (!$h.EndsWith('\')) {
            $h += '\'
        }

        if (!($h -eq '\')) {
            $friendlyPath = "$dir" -Replace ([Regex]::Escape($h)), '~\'
            Write-InstallInfo "adding $friendlyPath to your path."
        }
        else {
            Write-InstallInfo "adding $dir to your path."
        }

        # For future sessions
        Write-Env 'PATH' "$dir;$userEnvPath"
        # For current session
        $env:PATH = "$dir;$env:PATH"
    }
}

function Write-InstallInfo {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $String,
        [Parameter(Mandatory = $False, Position = 1)]
        [System.ConsoleColor] $ForegroundColor = $host.UI.RawUI.ForegroundColor
    )

    $backup = $host.UI.RawUI.ForegroundColor

    if ($ForegroundColor -ne $host.UI.RawUI.ForegroundColor) {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    Write-Output "$String"

    $host.UI.RawUI.ForegroundColor = $backup
}

function Deny-Install {
    param(
        [String] $message,
        [Int] $errorCode = 1
    )

    Write-InstallInfo -String $message -ForegroundColor DarkRed
    Write-InstallInfo 'Abort.'

    # Don't abort if invoked with iex that would close the PS session
    if ($IS_EXECUTED_FROM_IEX) {
        break
    }
    else {
        exit $errorCode
    }
}

# ------------------------------------------------------------------------
# end https://get.scoop.sh
# ------------------------------------------------------------------------

function Get-LatestReleaseTag {
    try {
        $Response = Invoke-WebRequest "https://github.com/$OWNER/$REPO/releases/latest" -Headers @{ 'Accept' = 'application/json' }
        $Json = $Response.Content | ConvertFrom-Json
        return $Json.tag_name
    }
    catch {
        Deny-Install "failed to get github release tag"
    }
}

function Get-Arch {
    $SysInfo = systeminfo | Out-String
    if ($SysInfo -match "ARM-based PC") {
        return "arm64"
    }
    return "amd64"
}

function Install-ShellPlugin {
    New-Item -ItemType Directory -Force ($profile | Split-Path) | Out-Null
    $shell = ""
    if ($PSVersionTable.PSEdition -eq "Core") {
        $shell = "pwsh"
    }
    else {
        $shell = "powershell"
    }

    if (-not (Select-String -Path $profile -Pattern "kaldo -s $shell")) {
        kaldo init $shell | Out-File $profile -Append -Encoding "UTF8"
        Write-InstallInfo "installed $shell plugin!"
    }
}

function Download-Release {
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Tag,
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Arch,
        [Parameter(Mandatory = $True, Position = 2)]
        [String] $Path
    )
    Invoke-WebRequest "https://github.com/$OWNER/$REPO/releases/download/$TAG/$PROJECT_NAME-$TAG-windows-$Arch.exe" -OutFile $Path
}

function Install {
    $Os = $PSVersionTable.OS
    if ($Os -inotmatch "Windows") {
        Deny-Install "installation on $Os is only supported via the bash install script"
    }
    $Arch = Get-Arch


    Write-InstallInfo 'checking github for the current release tag'
    $Tag = Get-LatestReleaseTag

    Write-InstallInfo "using release tag='$Tag' arch='$Arch'"
    $ProjectBin = "$env:USERPROFILE\.$PROJECT_NAME\bin"
    New-Item -Path $ProjectBin -ItemType Directory -Force | Out-Null
    Add-DirToPath $ProjectBin

    Download-Release $Tag $Arch "$projectBin\$PROJECT_NAME.exe"

    Install-ShellPlugin
}

Install

Write-Host @"

===============================================================================

thanks for installing kaldo!
if you have any issues, please open an issue on GitHub!
if you love kaldo, please give us a star on GitHub! it really helps ⭐️ https://github.com/cpendery/kaldo

to have kaldo take effect, restart your shell!

"@
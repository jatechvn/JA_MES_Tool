param(
    [string]$Origin = '',
    [string]$Mode = ''
)
$ErrorActionPreference = 'Stop'
$cleanMode = if ($null -ne $Mode) { $Mode.Trim('"'' ').ToLower() } else { '' }
$silent = $cleanMode -in @('/silent', '/s', '-silent', '-s', 'silent')
function Confirm-Yes([string]$prompt) {
    return ((Read-Host $prompt).Trim() -match '^(?i:y|yes)$')
}
try {
    $target = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\JA_MES_Tool')).TrimEnd('\')
    if ([string]::IsNullOrWhiteSpace($Origin)) {
        $Origin = $env:UNINSTALL_ORIGIN
    }
    $originClean = if (-not [string]::IsNullOrWhiteSpace($Origin)) { $Origin.Trim('"'' ') } else { '' }
    $originPath = if (-not [string]::IsNullOrWhiteSpace($originClean)) { [IO.Path]::GetFullPath($originClean).TrimEnd('\') } else { '' }
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\JA_MES_Tool'
    $registered = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).InstallLocation
    $registeredPath = if (-not [string]::IsNullOrWhiteSpace($registered)) { [IO.Path]::GetFullPath($registered.Trim('"'' ')).TrimEnd('\') } else { '' }
    if (($originPath -ne '' -and $originPath -ne $target) -or ($registeredPath -ne '' -and $registeredPath -ne $target)) {
        throw 'Run the uninstaller from the registered installation, not a portable/source folder.'
    }
    function Assert-PlainDirectory([string]$path) {
        $item = Get-Item -LiteralPath $path -Force
        for ($parent = $item; $null -ne $parent; $parent = $parent.Parent) {
            if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked directory refused.' }
        }
        if (Get-ChildItem -LiteralPath $path -Force -Recurse | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) {
            throw 'Linked content refused.'
        }
    }
    if (Test-Path -LiteralPath $target) { Assert-PlainDirectory $target }
    $purge = $false
    if (-not $silent) {
        if (-not (Confirm-Yes 'Uninstall JA MES Tool? (Yes/No)')) {
            Write-Host 'Uninstall cancelled.'
            exit 0
        }
        $purge = Confirm-Yes 'Delete user configurations and logs too? (Yes/No; default No)'
    }
    $exe = Join-Path $target 'ja_mes_tool.exe'
    $running = @(Get-Process ja_mes_tool -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })
    if ($running.Count) {
        if ($silent) { throw 'App is running. Interactive uninstall is required to confirm termination.' }
        if (-not (Confirm-Yes 'App is running. Kill the installed app and continue uninstalling? Unsaved changes may be lost. (Yes/No)')) {
            Write-Host 'Uninstall cancelled. Application was not stopped.'
            exit 0
        }
        foreach ($app in $running) {
            $current = Get-Process -Id $app.Id -ErrorAction SilentlyContinue
            if ($current -and $current.Path -eq $exe) {
                Stop-Process -InputObject $current -Force
                if (-not $current.WaitForExit(5000)) { throw 'Application did not exit.' }
            }
        }
    }
    $dataDirs = @((Join-Path $env:APPDATA 'JA_MES_Tool'), (Join-Path $env:LOCALAPPDATA 'JA_MES_Tool'))
    if ($purge) {
        foreach ($dir in $dataDirs) { if (Test-Path -LiteralPath $dir) { Assert-PlainDirectory $dir } }
    }
    Set-Location -LiteralPath $env:TEMP
    [System.IO.Directory]::SetCurrentDirectory($env:TEMP)
    Start-Sleep -Milliseconds 500
    # Default uninstall removes the program only. config.json stays in the
    # install folder so the next install still has the previous settings.
    $keepNames = @('config.json', 'config.ini', 'update_config.json')
    $stash = Join-Path $env:TEMP ('JA_MES_Uninstall_Keep_' + [guid]::NewGuid().ToString('N'))
    if (-not $purge -and (Test-Path -LiteralPath $target)) {
        New-Item -ItemType Directory -Path $stash | Out-Null
        foreach ($name in $keepNames) {
            $src = Join-Path $target $name
            if (Test-Path -LiteralPath $src -PathType Leaf) {
                Copy-Item -LiteralPath $src -Destination (Join-Path $stash $name) -Force
            }
        }
        $logs = Join-Path $target 'logs'
        if (Test-Path -LiteralPath $logs -PathType Container) {
            Copy-Item -LiteralPath $logs -Destination (Join-Path $stash 'logs') -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $target) {
        $deleted = $false
        for ($retry = 0; $retry -lt 5; $retry++) {
            try {
                Remove-Item -LiteralPath $target -Recurse -Force
                $deleted = $true
                break
            } catch {
                Start-Sleep -Milliseconds 600
            }
        }
        if (-not $deleted -and (Test-Path -LiteralPath $target)) {
            cmd.exe /c "rd /s /q `"$target`""
        }
    }
    if (-not $purge -and (Test-Path -LiteralPath $stash)) {
        $kept = @(Get-ChildItem -LiteralPath $stash -Force -ErrorAction SilentlyContinue)
        if ($kept.Count -gt 0) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            foreach ($item in $kept) {
                Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $target $item.Name) -Recurse -Force
            }
            Write-Host 'Kept config.json, update settings and logs in the install folder.'
        }
        Remove-Item -LiteralPath $stash -Recurse -Force
    }
    if ($purge) {
        foreach ($dir in $dataDirs) { if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force } }
    }
    $desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'JA MES Tool.lnk'
    $menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\JA MES Tool'
    $shell = New-Object -ComObject WScript.Shell
    foreach ($link in @($desktop, (Join-Path $menu 'JA MES Tool.lnk'), (Join-Path $menu 'Uninstall JA MES Tool.lnk'))) {
        if (Test-Path -LiteralPath $link) {
            $shortcut = $shell.CreateShortcut($link)
            if ($shortcut.TargetPath -eq $exe -or $shortcut.Arguments.Contains((Join-Path $target 'uninstall.bat'))) {
                Remove-Item -LiteralPath $link -Force
            }
        }
    }
    if ((Test-Path -LiteralPath $menu) -and -not (Get-ChildItem -LiteralPath $menu -Force)) { Remove-Item -LiteralPath $menu }
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    foreach ($name in @('JA MES Tool', 'JA_MES_Tool')) {
        $properties = Get-ItemProperty -LiteralPath $runKey -ErrorAction SilentlyContinue
        $value = if ($properties) { $properties.PSObject.Properties[$name].Value } else { $null }
        if ($value -and $value.Contains($exe)) { Remove-ItemProperty -LiteralPath $runKey -Name $name }
    }
    Remove-Item -LiteralPath $key
    Write-Host 'Uninstall completed.'
    exit 0
} catch {
    Write-Host ('Uninstall failed: ' + $_.Exception.Message)
    if (-not $silent) { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}

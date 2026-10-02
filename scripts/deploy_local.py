import os
import shutil
import subprocess

def main():
    root = r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool'
    rel_dir = os.path.join(root, r'build\windows\x64\runner\Release')
    target_dir = r'C:\Users\FT\AppData\Local\Programs\JA_MES_Tool'
    
    print(f"[deploy_local] Updating installed application at: {target_dir}")
    if os.path.exists(target_dir):
        # Copy ja_mes_tool.exe and app_icon.ico
        for f in ['ja_mes_tool.exe', 'app_icon.ico']:
            src = os.path.join(rel_dir, f)
            dst = os.path.join(target_dir, f)
            if os.path.exists(src):
                shutil.copy2(src, dst)
                print(f"[deploy_local] Copied {f} -> {dst}")
                
        # Copy data folder
        src_data = os.path.join(rel_dir, 'data')
        dst_data = os.path.join(target_dir, 'data')
        if os.path.exists(src_data):
            shutil.copytree(src_data, dst_data, dirs_exist_ok=True)
            print(f"[deploy_local] Updated data/ directory")

    # Re-save shortcuts with WScript.Shell
    ps_cmd = (
        "$ws = New-Object -ComObject WScript.Shell; "
        "$exe = 'C:\\Users\\FT\\AppData\\Local\\Programs\\JA_MES_Tool\\ja_mes_tool.exe'; "
        "$ico = 'C:\\Users\\FT\\AppData\\Local\\Programs\\JA_MES_Tool\\app_icon.ico'; "
        "$desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'JA MES Tool.lnk'; "
        "if (Test-Path $desktopLnk) { "
        "    $d = $ws.CreateShortcut($desktopLnk); "
        "    $d.TargetPath = $exe; "
        "    $d.IconLocation = $ico; "
        "    $d.Save(); "
        "    Write-Host '[deploy_local] Updated Desktop shortcut'; "
        "} "
        "$startMenuLnk = Join-Path $env:APPDATA 'Microsoft\\Windows\\Start Menu\\Programs\\JA MES Tool\\JA MES Tool.lnk'; "
        "if (Test-Path $startMenuLnk) { "
        "    $m = $ws.CreateShortcut($startMenuLnk); "
        "    $m.TargetPath = $exe; "
        "    $m.IconLocation = $ico; "
        "    $m.Save(); "
        "    Write-Host '[deploy_local] Updated Start Menu shortcut'; "
        "} "
    )
    subprocess.run(['powershell', '-NoProfile', '-Command', ps_cmd], check=False)
    print("[deploy_local] Local update complete.")

if __name__ == '__main__':
    main()

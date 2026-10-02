import os
import shutil
import zipfile
import re
import hashlib

def main():
    root = r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool'
    rel_dir = os.path.join(root, r'build\windows\x64\runner\Release')
    dist_dir = os.path.join(root, 'dist')
    os.makedirs(dist_dir, exist_ok=True)
    
    # 1. Clean config and logs from Release and Dist
    for d in [rel_dir, dist_dir]:
        for f in ['config.json', 'config.ini', 'update_config.json']:
            p = os.path.join(d, f)
            if os.path.exists(p):
                os.remove(p)
        logs_p = os.path.join(d, 'logs')
        if os.path.exists(logs_p):
            shutil.rmtree(logs_p, ignore_errors=True)
        
    # 2. Copy root helper files to Release
    extra_files = [
        'install.bat', 'uninstall.bat', 'uninstall.ps1', 'debug.bat',
        'ABOUT.txt', 'README.md', 'CHANGELOG.md', 'RELEASE_NOTES.md', 'USERGUIDE.md', 'LICENSE'
    ]
    for ef in extra_files:
        src = os.path.join(root, ef)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(rel_dir, ef))
            
    # Copy app_icon.ico
    icon_src = os.path.join(root, r'windows\runner\resources\app_icon.ico')
    if os.path.exists(icon_src):
        shutil.copy2(icon_src, os.path.join(rel_dir, 'app_icon.ico'))
        
    # 3. Mirror rel_dir to dist_dir (excluding logs, config, zips)
    for root_dir, dirs, files in os.walk(rel_dir):
        rel_path = os.path.relpath(root_dir, rel_dir)
        if rel_path == 'logs' or rel_path.startswith('logs' + os.sep):
            continue
        dest_subdir = os.path.join(dist_dir, rel_path) if rel_path != '.' else dist_dir
        os.makedirs(dest_subdir, exist_ok=True)
        for f in files:
            if f in ['config.json', 'config.ini', 'update_config.json'] or f.endswith('.log') or f.endswith('.key'):
                continue
            src_f = os.path.join(root_dir, f)
            dest_f = os.path.join(dest_subdir, f)
            shutil.copy2(src_f, dest_f)
            
    print(f"[stage_release] Files mirrored to dist: {dist_dir}")
    
    # 4. Read version from pubspec.yaml and create release zip
    pub_path = os.path.join(root, 'pubspec.yaml')
    with open(pub_path, 'r', encoding='utf-8') as pf:
        pub_text = pf.read()
    m = re.search(r'^version:\s*([^\r\n]+)', pub_text, re.MULTILINE)
    if m:
        ver = m.group(1).strip()
        base_ver = ver.split('+')[0]
        zip_name = f"JA_MES_Tool_v{base_ver}_Windows_x64.zip"
        zip_path = os.path.join(dist_dir, zip_name)
        
        # Clean any old zip packages from dist_dir
        for f in os.listdir(dist_dir):
            if f.endswith('.zip') and f != zip_name:
                try:
                    os.remove(os.path.join(dist_dir, f))
                    print(f"[stage_release] Removed old zip: {f}")
                except Exception:
                    pass

        # Package contents into zip (parent folder named JA_MES_Tool_v<base_ver>_Windows_x64)
        folder_prefix = f"JA_MES_Tool_v{base_ver}_Windows_x64"
        print(f"[stage_release] Creating release ZIP: {zip_path}")
        
        with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
            for root_dir, dirs, files in os.walk(dist_dir):
                for f in files:
                    full_p = os.path.join(root_dir, f)
                    if full_p == zip_path or f.endswith('.zip') or f == 'SHA256SUMS.txt':
                        continue
                    arc_name = os.path.relpath(full_p, dist_dir)
                    zf.write(full_p, os.path.join(folder_prefix, arc_name))
        print(f"[stage_release] ZIP package created: {zip_path} ({os.path.getsize(zip_path)} bytes)")

        # 5. Compute SHA256 and write dist/SHA256SUMS.txt
        sha256 = hashlib.sha256()
        with open(zip_path, 'rb') as f:
            while chunk := f.read(65536):
                sha256.update(chunk)
        zip_hash = sha256.hexdigest()

        sha_path = os.path.join(dist_dir, 'SHA256SUMS.txt')
        with open(sha_path, 'w', encoding='utf-8') as sf:
            sf.write(f"{zip_hash}  {zip_name}\n")
        print(f"[stage_release] Updated SHA256SUMS.txt: {zip_hash}  {zip_name}")

        # 6. Generate dist/version.json metadata for OTA
        notes = ''
        notes_path = os.path.join(root, 'RELEASE_NOTES.md')
        if os.path.exists(notes_path):
            with open(notes_path, 'r', encoding='utf-8') as nf:
                notes = nf.read().strip()

        from datetime import datetime, timezone
        import json
        meta = {
            "version": ver,
            "fileName": zip_name,
            "releaseNotes": notes,
            "releaseDate": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        }
        version_json_path = os.path.join(dist_dir, 'version.json')
        with open(version_json_path, 'w', encoding='utf-8') as vf:
            json.dump(meta, vf, indent=4, ensure_ascii=False)
        print(f"[stage_release] Updated version.json: version {ver}")

if __name__ == '__main__':
    main()


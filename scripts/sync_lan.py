import os
import shutil
import subprocess

def main():
    root = r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool'
    src_dist = os.path.join(root, 'dist')
    target_lan = r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_MES_Tool'

    if not os.path.exists(target_lan):
        print(f"[LAN Sync] Target path does not exist or unreachable: {target_lan}")
        return

    print(f"[LAN Sync] Mirroring {src_dist} to {target_lan} via robocopy...")
    cmd = ['robocopy', src_dist, target_lan, '/MIR', '/R:2', '/W:2', '/XD', 'logs']
    res = subprocess.run(cmd, capture_output=True, text=True)
    # Robocopy exit codes: 0 = no change, 1 = files copied, 2 = extra files deleted, 3 = files copied and deleted
    print(f"[LAN Sync] Robocopy exit code: {res.returncode}")
    print(res.stdout[-1000:] if res.stdout else "No stdout")

    # Verify target directory
    print("\n[LAN Sync] Target contents after sync:")
    for item in os.listdir(target_lan):
        full_p = os.path.join(target_lan, item)
        sz = os.path.getsize(full_p) if os.path.isfile(full_p) else '<DIR>'
        print(f"  {item} ({sz})")

if __name__ == '__main__':
    main()

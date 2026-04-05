import os
import subprocess
import sys
import shutil

# ---------------------------------------------------------------
# CONFIGURATION — edit these to match your script locations
# ---------------------------------------------------------------
_BASE = os.path.dirname(os.path.abspath(__file__))
def _s(name):
    return os.path.join(_BASE, name)

SCRIPTS = {
    "1": (
        "Filter Subtitles.", 
        _s("filter_subs.ps1")
        ),
    "2": (
        "Embed Subtitles to video.", 
        _s("embed_subtitles_sources_to_mkvs.ps1")
        ),
    "3": (
        "Set default Subtitle.", 
        _s("set_default_sub.ps1")
        ),
    "4": (
        "Set default Audio.", 
        _s("set_default_audio.ps1")
        ),
    "5": (
        "Show Track IDs (first file)", 
        _s("show_track_ids.ps1")
        )
}
# ---------------------------------------------------------------

def clear():
    os.system('cls')

def check_dependencies():
    if shutil.which("mkvmerge") is None:
        print("╔══════════════════════════════════════════════════╗")
        print("║  ERROR: mkvmerge not found on PATH               ║")
        print("║                                                  ║")
        print("║  Install MKVToolNix from:                        ║")
        print("║  https://mkvtoolnix.download/downloads.html      ║")
        print("║                                                  ║")
        print("║  During install, enable:                         ║")
        print("║  'Add MKVToolNix to the PATH'                    ║")
        print("╚══════════════════════════════════════════════════╝")
        input("\nPress Enter to exit...")
        sys.exit(1)

def main(): 
    check_dependencies()
    current_dir = os.getcwd() #current directory

    while True:
        clear()
        print("╔══════════════════════════════╗")
        print("║       MKV Script Launcher    ║")
        print("╚══════════════════════════════╝\n")
        print(f"Current directory: {current_dir}\n")

        cd_input = input("Enter Directory (press Enter to keep using the selected one): ").strip()

        #allow the user to type just a path or cd and path
        path = cd_input.removeprefix("cd").strip().strip('"').strip("'")

        #expand environment variables and ~
        path = os.path.expandvars(os.path.expanduser(path))

        #support relative and absolute paths
        new_dir = path if os.path.isabs(path) else os.path.join(current_dir, path)
        new_dir = os.path.normpath(new_dir)

        if not os.path.isdir(new_dir):
            input(f"\nDirectory not found: {new_dir}\n  Press Enter to try again...")
            continue

        current_dir = new_dir
        clear()

        print(f"Directory set to: {current_dir}\n")
        confirm = input("Is this correct? (Y/N): ").strip().lower()

        if confirm != 'y':
            continue
        #script selection
        while True:
            clear()
            print("=== Select a Script ===\n")
            print(f"Current directory: {current_dir}\n")
            for key, (name, path) in SCRIPTS.items():
                print(f"  [{key}]  {name}")
            print("\n  [Q]  Back to Directory Select.\n")
            choice = input("  Choose: ").strip().lower()

            if choice == 'q':
                clear()
                break

            if choice in SCRIPTS:
                name, script_path = SCRIPTS[choice] #makes a varibale in correleation to the value of the directionary
                clear()

                subprocess.run(
                    ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path],
                    cwd=current_dir
                )

                print("\n" + "-" * 50)
                input("Done. Press Enter to return to menu...")
                continue
            else:
                input("Invalid choice. Press Enter to try again...")

if __name__ == "__main__":
    main()
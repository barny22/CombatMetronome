import requests
import argparse
from contextlib import closing

def upload_addon(api_token, addon_id, version, file_path, changelog_path, compatible, description_path, test_only):
    url = "https://api.esoui.com/addons/updatetest" if test_only else "https://api.esoui.com/addons/update"
    
    headers = {
        "x-api-token": api_token
    }

    try:
        with closing(open(file_path, "rb")) as updatefile, \
             closing(open(changelog_path, "rb")) as changelog_file, \
             closing(open(description_path, "rb")) as description_file:
            
            files = {
                "updatefile": updatefile,
                "changelog": changelog_file,
                "compatible": compatible,
                "description": description_file
            }

            response = requests.post(url, headers=headers, files=files)
            response.raise_for_status()  # Überprüfe auf HTTP-Fehler
            print(response.json())

    except requests.exceptions.HTTPError as err:
        print(f"HTTP error occurred: {err}")
    except Exception as err:
        print(f"An error occurred: {err}")

def read_file(file_path):
    try:
        with open(file_path, 'r') as file:
            return file.read()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        exit(1)  # Beende das Skript bei einem Fehler

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload an ESO Addon to ESOUI")
    
    parser.add_argument("--api_token", required=True, help="API token for ESOUI")
    parser.add_argument("--addon_id", required=True, help="ID of the addon")
    parser.add_argument("--version", required=True, help="Version of the addon")
    parser.add_argument("--file_path", required=True, help="Path to the addon ZIP file")
    parser.add_argument("--changelog_path", required=True, help="Path to the changelog file")
    parser.add_argument("--compatible", required=True, help="Compatible Patch ID")
    parser.add_argument("--description_path", required=True, help="Path to the description file")
    parser.add_argument("--test_only", required=True, help="Use test URL if set to true")

    args = parser.parse_args()

    print(f"Parsed arguments: {args}")  # Zum Debuggen

    # Den Aufruf der Funktion mit den Argumenten
    upload_addon(
        api_token=args.api_token,
        addon_id=args.addon_id,
        version=args.version,
        file_path=args.file_path,
        changelog_path=args.changelog_path,
        compatible=args.compatible,
        description_path=args.description_path,
        test_only=args.test_only.lower() == 'true'
    )

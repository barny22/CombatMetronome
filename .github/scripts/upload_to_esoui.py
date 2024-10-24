import requests
import argparse

def upload_addon(api_token, addon_id, version, file_path, changelog, compatible, description, test_only):
    # Bestimme die URL basierend auf dem test_only Flag
    url = "https://api.esoui.com/addons/updatetest" if test_only else "https://api.esoui.com/addons/update"
    
    headers = {
        "x-api-token": api_token
    }

    files = {
        "updatefile": open(file_path, "rb"),
        "changelog": changelog,
        "compatible": compatible,
        "description": description
    }

    response = requests.post(url, headers=headers, files=files)
    print(response.json())

if __name__ == "__main__":
    # Argumente definieren
    parser = argparse.ArgumentParser(description="Upload an ESO Addon to ESOUI")
    
    parser.add_argument("--api_token", required=True, help="API token for ESOUI")
    parser.add_argument("--addon_id", required=True, help="ID of the addon")
    parser.add_argument("--version", required=True, help="Version of the addon")
    parser.add_argument("--file_path", required=True, help="Path to the addon ZIP file")
    parser.add_argument("--changelog", required=True, help="Changelog for the addon")
    parser.add_argument("--compatible", required=True, help="Compatible Patch ID")
    parser.add_argument("--description", required=True, help="Description of the addon")
    parser.add_argument("--test_only", required=True, help="Use test URL if set to true")

    args = parser.parse_args()

    # Den Aufruf der Funktion mit den Argumenten
    upload_addon(args.api_token, args.addon_id, args.version, args.file_path, args.changelog, args.compatible, args.description, args.test_only.lower() == 'true')

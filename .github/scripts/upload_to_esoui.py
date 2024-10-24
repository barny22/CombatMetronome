import requests
import argparse

def upload_addon(api_token, addon_id, version, file_path, changelog, compatible, description, test_only):
    url = "https://api.esoui.com/addons/updatetest" if test_only else "https://api.esoui.com/addons/update"
    
    headers = {
        "x-api-token": api_token if api_token else None
    }

    files = {
        "updatefile": open(file_path, "rb"),
        "changelog": changelog,
        "compatible": compatible,
        "description": description
    }

    # Debugging-Ausgaben
    print(f"URL: {url}")
    print(f"Headers: {headers}")
    print(f"Files: {files}")

    try:
        response = requests.post(url, headers={k: v for k, v in headers.items() if v is not None}, files=files)
        print(f"Response code: {response.status_code}")
        print(f"Response text: {response.text}")
        response.raise_for_status()  # Auslösen eines Fehlers für 4xx/5xx Antworten
        print(response.json())
    except requests.exceptions.HTTPError as err:
        print(f"HTTP error occurred: {err}")
    except Exception as e:
        print(f"An error occurred: {e}")

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload an ESO Addon to ESOUI")
    
    parser.add_argument("--api_token", required=False, help="API token for ESOUI")
    parser.add_argument("--addon_id", required=True, help="ID of the addon")
    parser.add_argument("--version", required=True, help="Version of the addon")
    parser.add_argument("--file_path", required=True, help="Path to the addon ZIP file")
    parser.add_argument("--changelog_path", required=False, help="Path to the changelog file")
    parser.add_argument("--compatible", required=True, help="Compatible Patch ID")
    parser.add_argument("--description_path", required=False, help="Path to the description file")
    parser.add_argument("--test_only", required=True, help="Use test URL if set to true")

    args = parser.parse_args()

    changelog = read_file(args.changelog_path)
    description = read_file(args.description_path)

    # Den Aufruf der Funktion mit den Argumenten
    upload_addon(args.api_token, args.addon_id, args.version, args.file_path, changelog, args.compatible, description, args.test_only.lower() == 'true')

def upload_addon(api_token, addon_id, version, file_path, changelog, compatible, description, test_only):
    url = "https://api.esoui.com/addons/updatetest" if test_only else "https://api.esoui.com/addons/update"
    
    headers = {
        "x-api-token": api_token if api_token else None
    }

    with open(file_path, "rb") as updatefile:
        files = {
            "archive": "Yes",  # oder "No", je nach Anforderung
            "updatefile": updatefile
        }

        data = {
            "id": addon_id,
            "title": "",  # Optional
            "version": version,
            "changelog": changelog,
            "compatible": compatible,
            "description": description
        }

        # Debugging-Ausgaben
        print(f"Request Data: {data}")
        print(f"Request Files: {files}")

        try:
            response = requests.post(url, headers={k: v for k, v in headers.items() if v is not None}, files=files, data=data)
            print(f"Response code: {response.status_code}")
            print(f"Response text: {response.text}")
            response.raise_for_status()  # Auslösen eines Fehlers für 4xx/5xx Antworten
            print(response.json())
        except requests.exceptions.HTTPError as err:
            print(f"HTTP error occurred: {err}")
        except Exception as e:
            print(f"An error occurred: {e}")

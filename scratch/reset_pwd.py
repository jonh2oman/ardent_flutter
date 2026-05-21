import json
import urllib.request
import urllib.error

def reset_password():
    # Read the token from firebase-tools config
    config_path = "/Users/jonathanwaterman/.config/configstore/firebase-tools.json"
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    access_token = config['tokens']['access_token']
    project_id = "rcscc-training-plan"
    uid = "tud5V9j0H7QPdVO9i6UZvzln9rt2"
    new_password = "password123"
    
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{project_id}/accounts:update"
    
    payload = json.dumps({
        "localId": uid,
        "password": new_password
    }).encode('utf-8')
    
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            res_data = response.read().decode('utf-8')
            print("Password reset successful!")
            print(res_data)
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} - {e.reason}")
        print(e.read().decode('utf-8'))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    reset_password()

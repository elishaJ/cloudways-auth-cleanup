#!/bin/bash 
# Retrieve input variables
email="$EMAIL"
api_key="$API_KEY"
task_id="$TASK_ID"
BASE_URL="https://api.cloudways.com/api/v1"
qwik_api="https://us-central1-cw-automations.cloudfunctions.net"

# Fetch access token
get_token() {
    echo "Retrieving access token"

    response=$(curl -s -X POST --location "$BASE_URL/oauth/access_token" \
        -w "%{http_code}" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'email='$email'' \
        --data-urlencode 'api_key='$api_key'')

    http_code="${response: -3}"
    body="${response::-3}"

    if [ "$http_code" != "200" ]; then
        echo "Error: Failed to retrieve access token. Invalid credentials."
        sleep 3
        exit
    else
        # Parse the access token and set expiry time to 10 seconds
        access_token=$(echo "$body" | jq -r '.access_token')
        expires_in=$(echo "$body" | jq -r '.expires_in')
        expiry_time=$(( $(date +%s) + $expires_in ))
        echo "Access token generated."
    fi
}

delete_ssh_keys(){
    echo "Deleting SSH keys from servers"
    curl -s --location --request DELETE "$qwik_api/cleanup" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header 'Authorization: Bearer '$access_token'' \
    --data-urlencode 'task_id='$task_id''
    echo "Deleting local SSH key"
    rm -f $key_path* task_id.txt
}
get_token
echo "task-id: $task_id"
delete_ssh_keys
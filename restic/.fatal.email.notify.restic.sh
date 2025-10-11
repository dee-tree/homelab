#!/bin/bash

# install this file via variables substitution, for example, as following:
# bws run -- 'envsubst "\$HOST_EMAIL_SERVER \$HOST_EMAIL_ADDRESS \$HOST_EMAIL_PASSWORD \$EMAIL_ADMIN_ADDRESS" < <path to this file> | sudo tee /etc/restic/.fatal.email.notify.restic.sh'

set -e

UNIT="$1"

# get logs from last invocation
ID=$(systemctl show -p InvocationID --value "$UNIT.service")
RAW_LOGS="$(journalctl --no-hostname -o short-full INVOCATION_ID=${ID} + _SYSTEMD_INVOCATION_ID=${ID})"

LOGS=$(/usr/bin/jq -Rrsa <<< ${RAW_LOGS})
LOGS=$(sed -e 's/^"//' -e 's/"$//' <<< $LOGS) # remove heading/trailing quote

curl -X POST https://smtpapi.mxroute.com/ \
  -H "Content-Type: application/json" \
  -d "{
    \"server\": \"${HOST_EMAIL_SERVER}\",
    \"username\": \"${HOST_EMAIL_ADDRESS}\",
    \"password\": \"${HOST_EMAIL_PASSWORD}\",
    \"from\": \"${HOST_EMAIL_ADDRESS}\",
    \"to\": \"${EMAIL_ADMIN_ADDRESS}\",
    \"subject\": \"Backup FAILURE | ${UNIT} @ $(hostname -f)\",
    \"body\": \"<h2>Backup was not completed</h2><h2>${UNIT}</h2><p><pre>${LOGS}</pre></p>\"
  }"

#!/bin/bash
# Salesforce DX scratch org alias
ORG_ALIAS=$1
DURATION=$2

echo "ORG_ALIAS : $ORG_ALIAS"
echo "DURATION: : $DURATION"

# Open grandparent directory of script (bash->scripts->redtag-script)
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$SCRIPT_PATH/../../"

# Run the Salesforce CLI command and capture its output
ORG_LIST_OUTPUT=$(sf org list --json)

# Check if the org alias exists in the JSON output
if [[ $ORG_LIST_OUTPUT == *\"$ORG_ALIAS\"* ]]; then
  echo "Cleaning previous scratch org..."
  sf org delete scratch --target-org $ORG_ALIAS --no-prompt
else
  # Org alias does not exist
  echo "Org with alias '$ORG_ALIAS' does not exist."
fi

#Export records from current default org
for arg in "${@:3}"; do
  sf data export tree --query ./scripts/soql/$arg.soql -d "./data"
done

echo -e "\n Creating scratch org..." && \
sf org create scratch --set-default --definition-file ./config/project-scratch-def.json --duration-days $DURATION --alias $ORG_ALIAS && \

#Deploy metadata from package to scratch org
sf project deploy start --manifest ./manifest/package.xml --target-org $ORG_ALIAS && \

#Import records to new scratch org
for arg in "${@:3}"; do
  sf data import tree --files ./data/$arg.json --target-org $ORG_ALIAS
done

# Get and check last exit code
EXIT_CODE="$?"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
  echo "Installation failed."
fi

exit $EXIT_CODE

#!/bin/bash
# Salesforce DX scratch org alias
if [ "$#" -eq 1 ]; then
  ORG_ALIAS="$1"
else
  echo "V4S install failed: missing org alias parameter"
  exit -1
fi

# Get the Salesforce package Id (04t....) from the latest version of a GitHub repository
# Available for V4S and these five packages
# Example:  getLatestPackageId SalesforceFoundation/Affiliations
getLatestPackageId() {
  INFO_BODY="$(curl -s "https://api.github.com/repos/$1/releases/latest" | jq .body)"
  REGEX="installPackage\.apexp\?p0=(04t[a-zA-Z0-9]+)[\\\r\\\n|\"]"

  if [[ $INFO_BODY =~ $REGEX ]]; then
    echo ${BASH_REMATCH[1]};
  else
    echo "Could not extract package Id from repo: $1"
    exit -1;
  fi
}

V4S_PACKAGE="$(getLatestPackageId SalesforceFoundation/Volunteers-for-Salesforce)" && \

echo -e "\n Installing V4S on org $ORG_ALIAS \n"
echo -e "V4S's Id - $V4S_PACKAGE/n"

sf package install --package $V4S_PACKAGE --wait 30 --target-org "$ORG_ALIAS" --no-prompt

# Get and check last exit code
EXIT_CODE="$?"
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "V4S installation completed."
else
  echo "V4S installation failed."
fi
exit $EXIT_CODE
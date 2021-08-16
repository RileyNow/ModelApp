#!/usr/local/bin/bash
echo $BASH_VERSION

source myShell.library

function printHelp() {
cat <<EOF
Description:
============
This script uploads the content of a provided file to the "vars" folder of the deployable in an application.

Arguments:
==========
1 - application name
2 - deployable name
3 - file name with full path to it

Example:
========
./uploadToDeployablesVar.sh myApp02 PRD "release-1.0/paymentService-V1.0" data/deployable.json true

EOF
}

clear #start by cleaning the terminal window

#== read the mySettings.conf file
parseMySettingsFile

#== get the provided arguments settings
checkForHelp $1
getCLArgumentAppName $1
getCLArgumentDeployableName $2
getCLArgumentFileName $3

echo " ";echo -e "== uploading data from file \e[92m${fileName}\e[39m to the var folder for deployable \e[92m${deplName}\e[39m for application \e[92m${appName}\e[39m"

#== prepare the file for upload
applyReplaceThisLogic "${fileName}"

#== perform the upload
start=`date +%s`
response=$(curl -s "${sncUrl}/api/sn_cdm/request/upload-and-commit/deployable/var?deployableName=${deplName}&dataFormat=${dataFormat}&appName=${appName}" --request PUT --header "Accept:application/json" --header "Content-Type:text/plain" --user ${sncUser}:${sncPwd} --data-binary @testData.json)
end=`date +%s`
echo -ne "upload time was `expr $end - $start` seconds."

#== check if there is a valid requestId
getRequestResult "${response}"

#== loop until requestId has been processed: result.state=completed
loopUntilRequestStateComplete "30" "${requestId}"

#== get the response
printResponseProcessingState "${requestId}"

echo -e " "; echo "== finished."
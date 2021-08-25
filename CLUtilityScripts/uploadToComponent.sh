#!/usr/local/bin/bash
echo $BASH_VERSION

source myShell.library

function printHelp() {
cat <<EOF
Description:
============
This script uploads the content of a provided file to a component (either direct or somewhere in the tree) of an application. In case the component does not exist it is created automatically.
It checks if the file contains "replaceThis" and if so replaces it with a unique integer. This allows to have automatically unique values in your upload file without manual work.

Arguments:
==========
1 - application name
2 - component name (or path to it) in the datamodel under which the file content will be uploaded. Use / as node separator
3 - file name with full path to it
4 - boolean value (true|false) to set the autoDelete

Example:
========
./uploadToComponent.sh myApp02 "deliveryService/deliveryService-v1.0" data/component2.json true

EOF
}

clear #start by cleaning the terminal window

#== read the mySettings.conf file
parseMySettingsFile


#== get the provided arguments settings
checkForHelp $1
getCLArgumentAppName $1
getCLArgumentCompName $2
getCLArgumentFileName $3
getCLArgumentAutoDelete $4
autoCommit="true"
autoPublish="publish_all"  #publish_none,publish_valid or publish_all
autoValidate="true"
echo " ";echo -e "== uploading data from file \e[92m${fileName}\e[39m to component \e[92m${compName}\e[39m for application \e[92m${appName}\e[39m "

#== prepare the file for upload
curDTstamp="$(date -u +%s)"
echo " "; echo -e ".. prepare and upload the file ${fileName}"
rm testData.json; cp ${fileName} testData.json #create upload file from template
sed -i -e "s/replaceThis/$curDTstamp/g" testData.json #replace the placeholder appName with the actual application name

#== perform the upload
start=`date +%s`
response=$(curl -s "${sncUrl}/api/sn_cdm/applications/uploads/components?namePath=${compName}&dataFormat=${dataFormat}&autoDelete=${autoDelete}&appName=${appName}&autoCommit=${autoCommit}&publishOption=${autoPublish}&autoValidate=${autoValidate}" --request PUT --header "Accept:application/json" --header "Content-Type:text/plain" --user ${sncUser}:${sncPwd} --data-binary @testData.json)
echo $response; echo " "
end=`date +%s`
echo -ne "upload time was `expr $end - $start` seconds."

#== check if there is a valid requestId
getRequestResult "upload" "${response}"

#== loop until requestId has been processed: result.state=completed
loopUntilRequestStateComplete "30" "${requestId}"

#== get the response
printResponseProcessingState "${requestId}"

echo -e " "; echo "== finished."

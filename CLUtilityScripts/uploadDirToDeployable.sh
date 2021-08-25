#!/usr/local/bin/bash
echo $BASH_VERSION
totalStart=`date +%s`
source $(dirname "$0")/myShell.library

function printHelp() {
cat <<EOF
Description:
============
This script uploads all configuraiton files from a directory to the path under the deployable of an application.
One node will be created for each file found.
It checks if the file contains "replaceThis" and if so replaces it with a unique integer. This allows to have automatically unique values in your upload file without manual work.

Arguments:
==========
app = application name
dep = deployable name
node = node path in datamodel under which the file content will be uploaded. Use / as node separator
path = path to files to import
(optional) autoCommit = boolean value (true|false) to set if commit should be done after each import (default is true)
(optional) autoDelete = boolean value (true|false) to set if previous data should be deleted after each import (default is false)
(optional) autoValidate = boolean value (true|false) to set if policies should run after each import (default is false)
(optional) changesetNumber = number of the changeset to use while importing (default is created for each file import)
(optional) convertPath = boolean value (true|false) to convert a filepath to nodename (default is false)
(optional) ext = list of extensions to filter search (default is 'ini,json,properties,props,xml,yaml,yml')
(optional) publishOption = if deployable should be published after upload, possible values: publish_none,publish_valid or publish_all (default is publish_none)
(optional) recursive = boolean value (true|false) to set the recursive mode (default is false)
(optional) skip = string to remove from full filename (default is none)

-h or --help to get this screen

Example:
========
./scripts/uploadDirToDeployable.sh app=G2 dep=test ext=properties recursive=true node=/input path=./positionJEE.test.config/KBLG recursive=true convertPath=true skip=./positionJEE.test.config

EOF
}
clear #start by cleaning the terminal window
#== read the mySettings.conf file
parseMySettingsFile

scriptDir="$PWD"/$(dirname "$0")

#== get the provided arguments settings
checkForHelp $1
while [[ "$#" > "0" ]]
do
  case $1 in
    (*=*) eval $1;;
  esac
  shift
done
getCLArgumentAppName $app
getCLArgumentDeployableName $dep
getCLArgumentNamePath $node
getCLArgumentFilePath $path
autoCommit=${autoCommit:-true}
autoDelete=${autoDelete:-false}
autoValidate=${autoValidate:-false}
changesetNumber=${changesetNumber:-}
convertPath=${convertPath:-false}
ext=${ext:-"ini,json,properties,props,xml,yaml,yml"}
publishOption=${publishOption:-"publish_none"}  #publish_none,publish_valid or publish_all
recursive=${recursive:-false}
skip=${skip:-}

nbFiles=0
nbFilesOK=0
nbFilesKO=0

echo -e "this script will upload with autoDelete \e[92m${autoDelete}\e[39m"
echo -e "this script will upload with extensions \e[92m${ext}\e[39m"
echo -e "this script will upload with recursive \e[92m${recursive}\e[39m"

# Get extensions list and put it in array
EXTENSION_LIST=(${ext//,/ })

NEW_FILES_LIST=""
for extension in "${EXTENSION_LIST[@]}" ; do
  if [ ${recursive} = true ]; then
    #echo "Do recursive search for extension: ${extension}"
    EXT_FILES=$(find ${filePath} -type f -iname "*.${extension}")
  else
    #echo "Do path only search for extension: ${extension}"
    EXT_FILES=$(find ${filePath} -maxdepth 1 -type f -iname "*.${extension}")
  fi
  if [ "${EXT_FILES}" != "" ]; then
    if [ "${NEW_FILES_LIST}" != "" ]; then
      # Add to existing array
      NEW_FILES_LIST=${NEW_FILES_LIST}$'\n'${EXT_FILES}
    else
      # Build initial array list of files
      NEW_FILES_LIST=${EXT_FILES}
    fi
  fi
done

if [[ ${NEW_FILES_LIST} != "########## ERROR:"* ]] && [[ "${NEW_FILES_LIST}" != "" ]]; then
  echo "###################################################################"
  echo "These files will be imported:"
  echo "${NEW_FILES_LIST[*]}"
  echo "###################################################################"
  # Transform into shell array
  NEW_FILES_LIST=(${NEW_FILES_LIST})
  NEW_FILES_LIST_SIZE=${#NEW_FILES_LIST[@]}
  # Now upload list of files
  for file in "${NEW_FILES_LIST[@]}" ; do
    nbFiles=$(( $nbFiles + 1 ))
    getCLArgumentFileName "${file}"
    # Remove the skip in node name pattern, if present
    FILE_NODE=${file//$skip/.}
    if [ "${convertPath}" = false ]; then
      # If no path conversion, just keep filename for node name in data model
      FILE_NODE=$(basename -- "$FILE_NODE")
    fi
    # Convert any path to nodename
    # remove "./" from namePath
    thisNamePath="${namePath}/${FILE_NODE//.\//}"
    # Remove all "//" from namePath
    thisNamePath=${thisNamePath//\/\//\/}
    echo " ";echo -e "== File ($nbFiles/$NEW_FILES_LIST_SIZE): uploading data from \e[92m${fileName}\e[39m to deployable \e[92m${deplName}\e[39m for application \e[92m${appName}\e[39m under path \e[92m${thisNamePath}\e[39m"
    #$(dirname "$0")/uploadDirToDeployable.sh "${appName}" "${deplName}" "${NODE_PATH},$FILE_NODE" "${file}" ${autoDelete}
    #== perform the upload
    start=`date +%s`
    #echo "curl -s \"${sncUrl}/api/sn_cdm/applications/uploads/deployables?deployableName=${deplName}&dataFormat=${dataFormat}&autoDelete=${5}&appName=$appName&namePath=${namePath}&autoCommit=${autoCommit}&publishOption=${autoPublish}&autoValidate=${autoValidate}\" --request PUT --header 'Accept:application/json' --header 'Content-Type:text/plain' --user \"${sncUser}:${sncPwd}\" --data-binary @${file}"
    response=$(curl -s "${sncUrl}/api/sn_cdm/applications/uploads/deployables?appName=$appName&autoCommit=${autoCommit}&autoDelete=${autoDelete}&autoValidate=${autoValidate}&changesetNumber=${changesetNumber}&dataFormat=${dataFormat}&deployableName=${deplName}&namePath=${thisNamePath}&publishOption=${publishOption}" --request PUT --header "Accept:application/json" --header "Content-Type:text/plain" --user "${sncUser}:${sncPwd}" --data-binary @${file})
    end=`date +%s`
    echo -ne "upload time was `expr $end - $start` seconds."

    #== check if there is a valid requestId
    getRequestResult "upload" "${response}"

    #== loop until requestId has been processed: result.state=completed
    loopUntilRequestStateComplete "30" "${requestId}"

    #== get the response
    printResponseProcessingState "${requestId}"

    echo -e " "; echo "== finished for file ${file}."
  done
  echo "${nbFiles} have been uploaded, ${nbFilesOK} were successfull and ${nbFilesKO} failed"

else
  echo "${NEW_FILES_LIST}"
  echo "No files found!"
fi

totalEnd=`date +%s`
echo -ne "Total time of this script was `expr $totalEnd - $totalStart` seconds."

#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No argument provided. Please provide 'stage' 'releaseparty' or 'releasebuild' as an argument."
    exit 1
fi

# Function to search and display the RPM information from nesus
search_rpm_info() {
    local rpm_name=$1
    # This is a very fragile and unreliable way to parse JSON and should only be used
    # as a last resort with the understanding that it may break with any changes to the JSON structure.
    local result=$(grep -B 1 "$rpm_name" "$json_file")

    if [[ -z $result ]]; then
        echo "No entry found"
    else
        echo "Here is the current entry for $1"
        echo "$result"
        url=$(echo "$result" | grep -o '"url": "[^"]*"' | cut -d '"' -f 4)
    status_code=$(curl -o /dev/null -s -w "%{http_code}\n" -I "$url")
    if [ "$status_code" -eq 200 ]; then
    echo "The RPM is available at the location: $url"
    else
    echo "The RPM was not found at the location: $url"
    fi
    fi
}
# Function to search and display the RPM information from index
search_rpm_index() {
    local rpm_name=$1
    local tagnumber="$2/"
    # This is a very fragile and unreliable way to parse JSON and should only be used
    # as a last resort with the understanding that it may break with any changes to the JSON structure.
    local result=$( curl http://111.11.111.111/release/$tagnumber | grep -oP 'href="\K[^"]+.rpm' | $rpm_name)

    if [[ -z $result ]]; then
        echo "No entry found"
    else
        echo "Here is the current entry for $1"
        echo "$result"
    fi
}

# Run commands based on the argument
case "$1" in
    stage)
        echo "Running stageing commands..."
############## Start of case stage ######################
#set enviroment
read -p "Enter the name of the folder you want to work in: " wkdir
if [ ! -d "$wkdir" ]; then
  # Directory does not exist, so create it
  echo "Directory $wkdir does not exist. Creating it now..."
  mkdir -p "$wkdir"
  
  # Check if the directory was created successfully
  if [ $? -eq 0 ]; then
    echo "Directory $wkdir created successfully."
  else
    echo "Failed to create directory $wkdir."
  fi
else
  # Directory already exists
  echo "Directory $wkdir already exists."
fi
read -p "Enter your user name: " username 
cd $wkdir
read -p "Enter the new release number formating should be 1.23.4-12.3-RC1 or -db1: " tagnumber
versionnumber="v${tagnumber}"

#clone and create new branch
git clone $username@11.11.11.111:/opt/git/release-eng.git
cd release-eng 
git branch -a
echo "Here is a list of all available branches."
read -p "what is your starting branch?: " startingbranch
git checkout $startingbranch
git checkout -b $versionnumber

#update the release version in the script
echo "current release version is set to" 
sed -n '2p' release-manifest.json
echo "Seting the new version to $tagnumber"
sed -i "2s/.*/  \"version\": \"$tagnumber\",/" release-manifest.json
echo "new version is now"
sed -n '2p' release-manifest.json
git diff $startingbranch

read -p "Would you like to commit these changes? (yes/no) " user_response

# Convert the response to lowercase
user_response=$(echo "$user_response" | tr '[:upper:]' '[:lower:]')

# Check the user's response
if [[ "$user_response" == "no" ]]; then
  echo "Changes will not be committed. Exiting the script."
  exit 0
elif [[ "$user_response" == "yes" ]]; then
  echo "Proceeding with the commit..."
else
  echo "Invalid response. Please answer 'yes' or 'no'."
  exit 1
fi
git commit .
#git push origin $versionnumber
echo "When ready to push your changes to the remote repo run this command"
echo "cd $wkdir/release-eng && git push origin $versionnumber"
echo "You are now done with staging the release."
        ;;
    releaseparty)
############## Start of case releaseparty ######################
        echo "Running Releaseparty commands..."
        ## # Add your section 2 commands here
read -p "Are all of the developers done with their changes to the release manifest? " user_response

# Convert the response to lowercase
user_response=$(echo "$user_response" | tr '[:upper:]' '[:lower:]')

# Check the user's response
if [[ "$user_response" == "no" ]]; then
  echo "Release party will not be started. Exiting the script."
  exit 0
elif [[ "$user_response" == "yes" ]]; then
  echo "Proceeding with the Release party..."
else
  echo "Invalid response. Please answer 'yes' or 'no'."
  exit 1
fi

#Set the environment
read -p "Enter the name of the folder you want to work in: " wkdir
if [ ! -d "$wkdir" ]; then
  # Directory does not exist, so create it
  echo "Directory $wkdir does not exist. Creating it now..."
  mkdir -p "$wkdir"

  # Check if the directory was created successfully
  if [ $? -eq 0 ]; then
    echo "Directory $wkdir created successfully."
  else
    echo "Failed to create directory $wkdir."
  fi
else
  # Directory already exists
  echo "Directory $wkdir already exists."
fi
read -p "Enter your user name: " username
cd $wkdir
cd release-eng
git branch -a
read -p "what is your original develop branch?: " startingbranch
read -p "Enter the release number formating should be 1.23.4-12.3-RC1 or -db1: " tagnumber
versionnumber="v${tagnumber}"
git checkout $versionnumber
git pull origin $versionnumber
git log
read -p "Is there a entry in the get log output above for the developers updates? " user_response

# Convert the response to lowercase
user_response=$(echo "$user_response" | tr '[:upper:]' '[:lower:]')

# Check the user's response
if [[ "$user_response" == "no" ]]; then
  echo "Release party will not be started. Exiting the script."
  exit 0
elif [[ "$user_response" == "yes" ]]; then
  echo "Proceeding with the Release party..."
else
  echo "Invalid response. Please answer 'yes' or 'no'."
  exit 1
fi

# Main loop
while true; do
    # Prompt the user to enter the RPM name or type 'exit' to quit
    echo "RPM Change verification step! If a RPM or version number is not available press CTRL + C at any point during this step to exit."
    read -r -p "Enter the full RPM name and version number from the integration checklist or type 'done' to continue:  " rpm_name

    # Check if the user wants to exit
    if [[ "$rpm_name" == "done" ]]; then
        echo "Done with RPM entry check."
        break
    fi
    # Search for the RPM information in the JSON file
    search_rpm_info "$rpm_name"
done
#Verify user is ready to continue
echo "If no additional changes are needed, press Enter to continue. Otherwise, press Ctrl+C to exit the script."
echo "If additional changes are needed ensure the changes are push to ORIGIN before restarting this script"
read -p "Press Enter to proceed... or Ctrl+C to exit"

# Run the release verification Jenkins job
echo "Open a web browser and navigate to http://111.111.111.123:8080/job/release-dev/"
echo "Click "Scan Multibranch Pipeline Now""
echo "Once the job is finished grab a screenshot before continuing the script"
echo "If the build failed press Ctrl+c to exit the script and troubleshoot"
read -p "Press Enter to proceed... or Ctrl+C to exit"

## Verify with the user
read -p "Are you ready to merge the $versionnumber branch with the $startingbranch  branch? " user_response

# Convert the response to lowercase
user_response=$(echo "$user_response" | tr '[:upper:]' '[:lower:]')

# Check the user's response
if [[ "$user_response" == "no" ]]; then
  echo "."
  exit 0
elif [[ "$user_response" == "yes" ]]; then
  echo "Proceeding with the merge..."
else
  echo "Invalid response. Please answer 'yes' or 'no'."
  exit 1
fi
git checkout $startingbranch
git merge --no-ff $versionnumber
git tag -a $tagnumber
echo "When ready to push the $startingbranch to the remote repo by running this command"
echo "cd $wkdir/release-eng && git push origin $startingbranch"
echo "When ready to start the builds run this command"
echo "./sw-release.sh releasebuild"
        ;;

    releasebuild)
############## Start of case releasebuild ######################

## Verify with the user
read -p "Did you finish the releaseparty step? " user_response

# Convert the response to lowercase
user_response=$(echo "$user_response" | tr '[:upper:]' '[:lower:]')

# Check the user's response
if [[ "$user_response" == "no" ]]; then
  echo "Run the releaseparty step."
  exit 0
elif [[ "$user_response" == "yes" ]]; then
  echo "Proceeding with build instructions..."
else
  echo "Invalid response. Please answer 'yes' or 'no'."
  exit 1
fi

read -p "what is your original develop branch?: " startingbranch
read -p "Enter the release number formating should be 1.23.4-12.3-RC1 or -db1: " tagnumber
versionnumber="v${tagnumber}"

echo "Open a web browser and navigate to http://111.111.111.123:8080/job/dev-release/"
echo "Click "Configure""
echo "Click the "Pipeline" tab at the top"
echo "Set the "Branches to build field to $versionnumber""
echo "Click Save"
echo "Click Build with Parameters"
echo "Uncheck DEBUG_BUILD"
echo "Click Build"
echo "Once the job is finished grab a screanshot before coninuing the script"
echo "If the build failed press Ctrl+c to exit the script and troubleshoot"
read -p "Press Enter to proceed... or Ctrl+C to exit"

# Verify index was made with correct rpms
echo "Verify the RPMs from the intigration checklist are in the index at http://111.111.111.123/release/$tagnumber"
while true; do
    # Prompt the user to enter the RPM name or type 'exit' to quit
    echo "RPM Index verification step! If a RPM or version number is not avilable press CTRL + C at any point during this step to exit."
    read -r -p "Enter the full RPM name and version number from the integration checklist or type 'done' to continue:  " rpm_name

    # Check if the user wants to exit
    if [[ "$rpm_name" == "done" ]]; then
        echo "Done with RPM entry check."
        break
    fi
    # Search for the RPM information in the JSON file
    search_rpm_index "$rpm_name" "$tagnumber"
done

        ;;
    *)
        echo "Invalid argument: $1. Please provide 'stage' or 'releaseparty' as an argument."
        exit 1
        ;;
esac

exit 0


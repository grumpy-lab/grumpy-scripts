#!/bin/bash

######### Definitions #############

# Define the output file path
output_file="/tmp/results-system-check.txt"

# Define file for tmp text
tmptxt="/tmp/out-tmp"

# Touch the file to make sure it exists
touch /tmp/results-system-check.txt

# Get the current date and time in the specified format
current_time=$(date +"%H:%M-%d-%m-%Y")

# Add the line with the timestamp to the file
echo "Run started $current_time" > /tmp/results-system-check.txt

# Set password as a variable if another method is avilable do not use this
read -p "enter password" pass


# Define a list of hosts to check
hosts=(
    "server1"
    "server2"
    "server3"
    "server4"
    "server5"
    "server6"
    "server7"
    "server8"
    "server9"
    "server10"



    # Add more hosts as needed
)

break=#####################################################################################

###### Test connectivity ######
echo "Step 1: Connectivity Test starting" | tee -a $output_file
## Initialize counters for reachable and unreachable hosts
reachable_count=0
unreachable_count=0
total_checked_count=0

# Loop through each host in the array
for host in "${hosts[@]}"; do
  echo "Testing SSH connectivity to $host"
  
  # Attempt to SSH to the host using BatchMode
  if ssh -o BatchMode=yes -o ConnectTimeout=5 -q "$host" exit; then
    echo "Success: Connected to $host"
    ((reachable_count++))
  else
    echo "Error: Could not connect to $host"
    ((unreachable_count++))
  fi
  ((total_checked_count++))
done

# Display the summary of reachable and unreachable hosts
echo "Connectivity test summary:" | tee -a $output_file
echo "Total host checked: $total_checked_count" | tee -a $output_file
echo "Reachable hosts: $reachable_count" | tee -a $output_file
echo "Unreachable hosts: $unreachable_count" | tee -a $output_file


echo "Step 1: Connectivity Test Finished" | tee -a $output_file
echo "$break" >> $output_file
sleep 3

########################################################################################################
###### Puppet Checks ########

echo "STEP 2: Puppet Checks Starting" | tee -a "$output_file"

### Run the puppetserver ca list --all command and capture the output
ssh -qt puppet-server echo "$pass" | sudo -S /opt/puppetlabs/bin/puppetserver ca list --all > "$tmptxt"

sed command here

check_count=0

for host in "${hosts[@]}"; do
    if cat "$output_file" | grep -q "$host"; then
    echo "$host is present in the certificate list." >> "$output_file"
    ((check_count++))
else
    echo "$host" is not present in the certificate list."
fi

echo "$check_count certs found out of $total_checked_count expected" | tee -a "$output_file"
"
# Loop through each host
check_count=0
failed_count=0
for host in "${hosts[@]}"; do
    echo "Checking Puppet status on $host..." | tee -a "$output_file"

    # Run the puppet agent --configprint command via SSH and capture the output
    lockfile=$(ssh "$host" puppet agent --configprint agent_disabled_lockfile)

    # Check if the lockfile exists on the remote host
    if ssh "$host" "if [[ -f \"$lockfile\" ]]; then
        echo \"Puppet is disabled on $host.\" | tee -a \"$output_file\"
        exit 1
    else
        echo \"Puppet is enabled on $host.\" | tee -a \"$output_file\"
        exit 0
    fi"
    then
        ((check_count++))
    else
        ((failed_count++))
    fi

echo "$check_count servers with no lock file found out of $total_checked_count expected" | tee -a "$output_file"
echo "$failed_count servers have a lock file run 'puppet agent --enable' on the server" | tee -a "$output_file"

    # Check the status of the Puppet service
    puppet_service_status=$(ssh "$host" puppet resource service puppet | grep 'ensure' | awk '{print $3}')

    # Output the status of the Puppet service
    if [[ "$puppet_service_status" == "'running'" ]]; then
        echo "Puppet service is running on $host." | tee -a "$output_file"
    else
        echo "Puppet service is not running on $host." | tee -a "$output_file"
    fi
done


###Check if puppet is enabled to start on boot
check_count=0
# Loop through each host in the array
for host in "${hosts[@]}"; do
  echo "Checking if puppet service is enabled on $host"

  # Use SSH to run 'systemctl is-enabled puppet' on the remote host
  output=$(ssh "$host" systemctl is-enabled puppet 2>/dev/null)

  # Check if the output contains "enabled"
  if [[ $output == "enabled" ]]; then
    echo "puppet is  enabled on $host" >> "$output"
    ((check_count++))
  else
    echo "Failed check: puppet is disabled or not present on $host" | tee -a "$output"
  fi
done

###Check each host for if puppet service is active
check_count=0
# Loop through each host in the array
for host in "${hosts[@]}"; do
  echo "Checking if puppet service is running on $host"

  # Use SSH to run 'systemctl is-active puppet' on the remote host
  output=$(ssh "$host" systemctl is-active puppet 2>/dev/null)

  # Check if the output contains "active"
  if [[ $output == "active" ]]; then
    echo "puppet is  active on $host" >> "$output"
    ((check_count++))
  else
    echo "Failed check: puppet is not active or not present on $host" | tee -a "$output"
  fi
done

#puppet resource service critical-service1.service

echo "Step 2: puppet checks finished" | tee -a $output_file
echo "$break" >> $output_file
sleep 3

########################################################################################

# Loop through each host
for host in "${hosts[@]}"; do
    echo "Checking 'test.service' on $host..."

    # Run the yum list installed command via SSH and capture the output
    rpm_info=$(ssh your_username@"$host" "yum list installed test.service")

    # Extract the service name and version
    # Assuming the output format is 'name.arch version repo'
    service_name_and_version=$(echo "$rpm_info" | grep 'test.service' | awk '{print $1 " " $2}')

    # Write the service name and version to the output file
    echo "$host: $rpm_name_and_version" >> "$output"
done


# Define an  array with service names as keys and expected versions as values
declare -A services=(
    [httpd]="2.4.6"
    [mysqld]="5.7.29"
    # Add more services and their expected versions here
)

# Loop through the  array
for service in "${!services[@]}"; do
    expected_version=${services[$service]}
    
    # Check if the service with the specific version is installed
    installed_version=$(yum list installed "$service" | grep "$service" | awk '{print $2}')
    
    # Compare the installed version with the expected version
    if [[ "$installed_version" == "$expected_version" ]]; then
        echo "$host Service $service is installed with the expected version: $expected_version"
    else
        echo "$host Service $service is NOT installed with the expected version: $expected_version"
        echo "$host Installed version is: $installed_version"
    fi
done











########################check for errors##################################################
# Define the search terms
check_terms=("check-failed")
search_terms=("error" "disabled" "stopped" "killed" "NOT")

# Initialize a flag to indicate if a failed check was found
Check_Failures_Found=0

# Loop through each search term and check if it's in the file
for term in "${check_terms[@]}"; do
    if grep -iq "$term" "$output_file"; then
        echo "Failed Check detected: '$term' found in $output_file."
        Check_Failures_Found=1
        break
    fi
done

# Initialize a flag to indicate if an error was found
error_found=0

# Loop through each search term and check if it's in the file
for term in "${search_terms[@]}"; do
    if grep -iq "$term" "$output_file"; then
        echo "Errors detected: '$term' found in $output_file."
        error_found=1
        break
    fi
done

# If no errors were found, output the corresponding message
if [ $error_found -eq 0 ]; then
    echo "No errors detected in $output_file."
fi

# Output the location of the results file
echo "Run finished Results have been saved to $output_file"

# Add the line with the timestamp to the file
echo "Run finished $current_time" >> /tmp/results-system-check.txt

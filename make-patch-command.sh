
# ask user for the name of the tar archive
read -p "Enter the release number: " archive_name


# Use a loop to read RPM names from user input
while true; do
    # Prompt the user to enter an RPM name or press enter to finish
    read -p "Enter an RPM name (or press enter to finish): " rpm_name
    
    # Check if the user input is empty
    if [[ -z "$rpm_name" ]]; then
        # If empty, break out of the loop
        break
    else
        # If not empty, add the RPM name to the array
        rpm_names+=("$rpm_name")
    fi
done

# Create the tar command using the collected RPM names
tar_command="tar --selinux -cvf ${archive_name}.tar ${rpm_names[*]} repodata"

# Print the tar command
echo "$tar_command" > patch-cmd

read -p "Enter your user name: " username

md5sum_command="md5sum ${archive_name}.tar >> ${archive_name}-md5sum.txt"
scp_command1="scp ${archive_name}.tar ${username}@111.222.333.444:/user/path/"
scp_command2="scp ${archive_name}-md5sum.txt ${username}@111.222.333.444:/user/path/"

echo "$md5sum_command" >> patch-cmd
echo "$scp_command1" >> patch-cmd
echo "$scp_command2" >> patch-cmd

echo "Run the following command on the remote server"
echo "ssh $username@111.222.333.444 'cat /path/to/remote/file' | bash"





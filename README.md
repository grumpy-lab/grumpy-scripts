# system-check.sh
- A templet of a final system check to verify known concerns


# dumb-release.sh

- a templet for a scripted sw release process that requiers manual pipeline runs. Can varify against an artifact repository but mostly just automates git functions for a non-technical release team

# make-patch-command

- Can be used on a jump host to create file of commands that can be read into bash on a server that does not support copy paste. On a jump server copy paste can be used with the script to make long tar commands. Then from a unconfigured remote server that only has a virtual console the text file can be piped into bash.

## Usage
Run first the ```export-users-from-groups.ps1``` to create and populate files that will have the name of each group to import and will contains SAMAccountName of member users.
Then run ```import-users-membership.ps1``` to create membership based on file names and list of users in each of them.

The ```export-users-from-groups.ps1``` script will create a number of files equals to the number of groups to import. Also all the files will have the same name of group to import with extension .csv. 

For example: <br>
we want to add some users to group Group1, some others to Group2, the ```export-users-from-groups.ps1``` will create 2 files with name **Group1.csv** and **Group2.csv**

#Import active directory module for running AD cmdlets

Import-Module activedirectory
$count = 0
#Store the data from ADUsers.csv in the $ADUsers variable
$Users = Import-csv "C:\Users\Administrator\Downloads\Import-Users-In-AD\list-users-to-import.csv" -Delimiter ";"

Write-Output "There are $($Users.count) users to import in current domain:"
Get-ADDomain

#Loop through each row containing user details in the CSV file 
foreach ($User in $Users) {
    # Read user data from each field in each row
    # the username is used more often, so to prevent typing, save that in a variable

        # create a hashtable for splatting the parameters
        $userProps = @{
            SamAccountName                         = $User.SamAccountName                   
            Path                                   = $User.path
            GivenName                              = $User.GivenName 
            Surname                                = $User.Surname
            Initials                               = $User.Initials
            Name                                   = $User.Name
            DisplayName                            = $User.DisplayName
            UserPrincipalName                      = $user.UserPrincipalName 
            Department                             = $User.Department
            Description                            = $User.Description
            Office                                 = $User.Office
            OfficePhone                            = $User.OfficePhone
            StreetAddress                          = $User.StreetAddress
            POBox                                  = $User.POBox
            City                                   = $User.City
            State                                  = $User.State
            PostalCode                             = $User.PostalCode
            Title                                  = $User.Title
            Company                                = $User.Company
            Country                                = $User.Country
            EmailAddress                           = $User.Email
            AccountPassword                        = (ConvertTo-SecureString $User.password -AsPlainText -Force) 
            Enabled                                = $true
            ChangePasswordAtLogon                  = $false
            AllowReversiblePasswordEncryption      = $true
            CannotChangePassword                   = $true
            PasswordNeverExpires                   = $true
        }   #end userprops   

         New-ADUser @userProps
         Write-Output "Addedd $($user.UserPrincipalName)"
         $count++
    }

Write-Output "Addedd $count users in Active Directory"

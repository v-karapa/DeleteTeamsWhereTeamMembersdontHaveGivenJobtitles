#this script will Delete the all teams except given job titles match
#for best practice run the script quote line no 70 & 71
#keep the tenant id in info.json and save it in current folder.

#creating token id
$input = get-content info.json | ConvertFrom-Json
$Client_Secret = $input.Client_Secret
$client_Id = $input.client_Id
$Tenantid = $input.Tenantid

#Grant Adminconsent 
$Grant= 'https://login.microsoftonline.com/common/adminconsent?client_id='
$admin = '&state=12345&redirect_uri=https://localhost:1234'
$Grantadmin = $Grant + $client_Id + $admin

start $Grantadmin
write-host "login with your tenant login detials to proceed further"

$proceed = Read-host " Press Y to continue "
if ($proceed -eq 'Y')
{
    write-host "Creating Access_Token"          
              $ReqTokenBody = @{
         Grant_Type    =  "client_credentials"
        client_Id     = "$client_Id"
        Client_Secret = "$Client_Secret"
        Scope         = "https://graph.microsoft.com/.default"
    }

    $loginurl = "https://login.microsoftonline.com/" + "$Tenantid" + "/oauth2/v2.0/token"
    $Token = Invoke-RestMethod -Uri "$loginurl" -Method POST -Body $ReqTokenBody -ContentType "application/x-www-form-urlencoded"

    $Header = @{
        Authorization = "$($token.token_type) $($token.access_token)"
    }
    
   #getting All teams
   write-host "Getting All teams"

   $getTeams = "https://graph.microsoft.com/beta/groups?filter=resourceProvisioningOptions/Any(x:x eq 'Team')" 
   $Teams = Invoke-RestMethod -Headers $Header -Uri $getTeams -Method get -ContentType 'application/json'
   $values = $Teams.value
   $groupid = $values.id
   $displayname = $values | select displayName
   
   #getting members
       write-host "Getting members for each team"
        $results = foreach($team in $values)
           {
           $id = $team.id
           write-host "Inside loop"
            
            $memberuri = "https://graph.microsoft.com/v1.0/groups/"+ "$id" +"/members"
            $owners = Invoke-RestMethod -Headers $Header -Uri $memberuri -Method get -ContentType 'application/json'
            
            # for each member - check the designation
            $keepTeam = $false
            $jobtitle = $owner.jobTitle
            
            foreach($owner in $owners.value)
            {
                if( "AGM", "DGM", "GM", "MD"  -contains $owner.jobTitle)
                {
                    $keepTeam = $true
                }
            }
            # delete if flag is false
            if(!$keepTeam)
             {
                    $displayname = $team | select displayName
                    #$deleteURL = "https://graph.microsoft.com/v1.0/groups/" + "$id" 
                    #$owners = Invoke-RestMethod -Headers $Header -Uri $deleteURL -Method DELETE 
                    write-host "$displayname has been deleted"
                    $displayname | export-csv out.csv -NoTypeInformation -Append
             }
   }
   
   } 
   
   else{ write-host Re run the script and press Y}
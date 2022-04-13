# Transfer all tags associated with a particular image, specified in the $repo variable, from the source connected registry to the destination connected registry
# It's possibile also to change the destination name of repo by changing the contents of --image parameter
$SourceAcrName="source-acr"
$SourceAcrFQDN="source-acr.azurecr.io"
$DestinationAcrName="destination-acr"
$repo="repo"
$Tags = az acr repository show-tags -n $SourceAcrName --repository $repo | ConvertFrom-Json
foreach ($tag in $Tags) {
    az acr import --name $DestinationAcrName --source "${SourceAcrFQDN}/${repo}:${tag}" --image "${repo}:${tag}"
}

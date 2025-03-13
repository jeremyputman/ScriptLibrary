Clear-Host
# Load Variables for Scripts. This allows to keep variable data seperate from the script so that there is no org specific data
Get-ScriptVariables -Environment "Production" -Script "InventoryReport" -JSON "C:\DevOps\PowerShell Scripts\Variables\Variables.json"
# Entra ID App Registration Secret
$clientSecret = Get-Secret -Vault $SecretVault -Name $AzClientSecret
# Get Graph Access Token
Get-GraphAccessToken -clientID $AzAppRegistration -clientSecret $clientSecret.GetNetworkCredential().Password -tenantID $AzTenant | Out-Null
# Date Variables
$today = Get-Date
$30Days = $today.AddDays(30)
# Get list of SAML Service Principals
$principals = Get-GraphServicePrincipals -all -filter "preferredSingleSignOnMode eq 'saml'"
# Create a list of Service Principals that are expiring in 30 days
$expiringSecrets = [System.Collections.Generic.List[PSCustomObject]]@()
# Loop through all the principals to check for expiring ones within our time frame
foreach($principal in $principals){
  # Loop through each of the secrets for the SAML connection
  foreach($key in $principal.passwordCredentials){
    $message = $null
    # Check to see if expired, or expiring within 30 days
    if($key.endDateTime -lt $today){
      $message = "Certificate has Expired"
    }
    elseif($key.endDateTime -lt $30Days){
      $message = "Certificate will expire in 30 days or less"
    }
    # Store the expiring secrets in a list
    if($null -ne $message){
      $obj = [PSCustomObject]@{
        ServicePrincipal = $principal.displayName
        appid = $principal.appid
        message = $message
        endDateTime = $key.endDateTime
        displayName = $key.displayName
      }
      $expiringSecrets.add($obj)
    }        
  }
}
# Display the list of expired/expiring secrets
$expiringSecrets | format-Table
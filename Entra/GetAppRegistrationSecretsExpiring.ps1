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
# Get list of Application Registrations that have credentials
$applications = Get-GraphApplications -all -fields "id,appId,displayName,keyCredentials,passwordCredentials" | Where-Object {$null -ne $_.keyCredentials[0] -or $null -ne $_.passwordCredentials[0]}
# Create a list of Service Principals that are expiring in 30 days
$expiringSecrets = [System.Collections.Generic.List[PSCustomObject]]@()
# Loop through all the principals to check for expiring ones within our time frame
foreach($app in $applications){
  foreach($key in $app.keyCredentials){
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
        Application = $app.displayName
        appid = $app.appid
        message = $message
        endDateTime = $key.endDateTime
        displayName = $key.displayName
      }
      $expiringSecrets.add($obj)      
    }
  }
  foreach($key in $app.passwordCredentials){
    $message = $null
    # Check to see if expired, or expiring within 30 days
    if($key.endDateTime -lt $today){
      $message = "Secret has Expired"
    }
    elseif($key.endDateTime -lt $30Days){
      $message = "Secret will expire in 30 days or less"
    }  
    # Store the expiring secrets in a list
    if($null -ne $message){
      $obj = [PSCustomObject]@{
        Application = $app.displayName
        appid = $app.appid
        message = $message
        endDateTime = $key.endDateTime
        displayName = $key.displayName
      }
      $expiringSecrets.add($obj)      
    }
  }  
}
# Display the list of expired/expiring secrets
$expiringSecrets | Sort-Object -Property Application | format-table
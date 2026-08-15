$ErrorActionPreference = 'Stop'

$projectUrl = 'https://mvgpeiejwstrxjmfslke.supabase.co'
$anonKey = 'sb_publishable_rPBCsdTPJUWlslIDbF5f3g_uK-TKqxw'
$headers = @{
  apikey = $anonKey
  Authorization = "Bearer $anonKey"
  'Content-Type' = 'application/json'
}

$jobs = @()
for ($i = 1; $i -le 12; $i++) {
  $email = "ignissafe-load-$i-$(Get-Date -Format 'HHmmss')@gmail.com"
  $jobs += Start-Job -ScriptBlock {
    param($projectUrl, $headers, $email, $index)
    $started = Get-Date
    try {
      $body = @{ email = $email } | ConvertTo-Json -Compress
      $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$projectUrl/functions/v1/check_email_status" `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 30
      [pscustomobject]@{
        index = $index
        ok = $true
        status = $response.status
        elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
        error = $null
      }
    } catch {
      [pscustomobject]@{
        index = $index
        ok = $false
        status = $null
        elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
        error = $_.Exception.Message
      }
    }
  } -ArgumentList $projectUrl, $headers, $email, $i
}

$results = $jobs | Receive-Job -Wait -AutoRemoveJob
$results | Sort-Object index | ConvertTo-Json -Depth 4

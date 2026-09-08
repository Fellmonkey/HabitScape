param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]]$Paths
)

# Runs `flutter test` with a 5s per-test timeout and hard-kills the whole
# run after 90s so a stuck test can never block the developer for minutes.
$job = Start-Job -ScriptBlock {
  param($paths, $root)
  Set-Location $root
  & flutter test --no-pub --timeout 5s @paths
} -ArgumentList (, $Paths), (Get-Location).Path

if (-not (Wait-Job $job -Timeout 90)) {
  Stop-Job $job -ErrorAction SilentlyContinue
  Write-Output 'KILLED after 90s (overall timeout)'
}

Receive-Job $job | Select-Object -Last 60
Remove-Job $job -Force -ErrorAction SilentlyContinue

<#
Usage:
.\scripts\list_inactive_workflows.ps1 `
  -Owner "Ed-uardo" `
  -Repo "walmart-sales-forecasting-analysis" `
  -ThresholdDays 30 `
  -ExcludeScheduledOrReusable
#>

param(
  [string]$Owner = "ab-inbev-beertech",
  [string]$Repo  = "image-processing",
  [int]$ThresholdDays = 30,
  [switch]$ExcludeScheduledOrReusable
)

$now = (Get-Date).ToUniversalTime()

$workflows = (
  gh api "repos/$Owner/$Repo/actions/workflows?per_page=100" |
  ConvertFrom-Json
).workflows

$defaultBranch = gh repo view "$Owner/$Repo" `
  --json defaultBranchRef `
  -q '.defaultBranchRef.name'

$rows = @()

foreach ($wf in $workflows) {
  $last = gh api "repos/$Owner/$Repo/actions/workflows/$($wf.id)/runs?per_page=1" `
    --jq ".workflow_runs[0].created_at"

  $days = if ($last) {
    [math]::Floor(($now - [DateTime]::Parse($last)).TotalDays)
  } else { 99999 }

  $skip = $false

  if ($ExcludeScheduledOrReusable) {
    $yaml = gh api "repos/$Owner/$Repo/contents/$($wf.path)?ref=$defaultBranch" `
      -H "Accept: application/vnd.github.raw" 2>$null

    if ($yaml) {
      if ($yaml -match '(?i)workflow_call' -or $yaml -match '(?i)schedule:') {
        $skip = $true
      }
    }
  }

  if (-not $skip -and $days -ge $ThresholdDays) {
    $lastDisplay = if ($last) { $last } else { "never" }
    $rows += [pscustomobject]@{
      Id        = $wf.id
      Name      = $wf.name
      Path      = $wf.path
      State     = $wf.state
      LastRun   = $lastDisplay
      DaysSince = $days
    }
  }
}

$rows |
  Sort-Object DaysSince -Descending |
  Format-Table -AutoSize Id,Name,Path,State,LastRun,DaysSince

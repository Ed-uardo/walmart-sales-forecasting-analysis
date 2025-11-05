<#
Usage:
.\scripts\delete_workflow_runs.ps1 `
  -Owner "Ed-uardo" `
  -Repo "walmart-sales-forecasting-analysis" `
  -WorkflowNames @(".github/workflows/.yml","Workflow name") `
  -ThresholdDays 0 `
  -DisableWorkflows `
  -Apply `
  -LogToIssue `
  -IssueTitle "Workflow run cleanup –"
#>

param(
  [string]$Owner = "ab-inbev-beertech",
  [string]$Repo  = "image-processing",
  [string[]]$WorkflowNames,
  [string]$WorkflowNamesFile,
  [int]$ThresholdDays = 0,
  [switch]$DisableWorkflows,
  [switch]$Apply,
  [switch]$LogToIssue,
  [string]$IssueTitle = "Workflow run cleanup"
)

$ErrorActionPreference = 'Stop'

function Resolve-Workflow {
  param([array]$WorkflowList, [string]$Target)
  return ($WorkflowList | Where-Object { $_.name -eq $Target -or $_.path -eq $Target })
}

function Remove-WorkflowRunsById {
  param(
    [string]$Owner, [string]$Repo, [int]$WorkflowId,
    [int]$ThresholdDays = 0, [switch]$Apply
  )
  $now = (Get-Date).ToUniversalTime()
  $cutoff = $now.AddDays(-[math]::Abs($ThresholdDays))
  $deleted = 0

  while ($true) {
    $resp = gh api `
      "repos/$Owner/$Repo/actions/workflows/$WorkflowId/runs?per_page=100&page=1" |
      ConvertFrom-Json
    $runs = $resp.workflow_runs
    if (-not $runs -or $runs.Count -eq 0) { break }

    $toDelete = if ($ThresholdDays -gt 0) {
      $runs | Where-Object { [DateTime]::Parse($_.created_at).ToUniversalTime() -lt $cutoff }
    } else { $runs }

    if (-not $toDelete -or @($toDelete).Count -eq 0) { break }

    $preview = $toDelete |
      Select-Object id, head_branch, display_title, created_at |
      Format-Table -AutoSize | Out-String
    Write-Host ($preview.Trim())

    if ($Apply) {
      foreach ($r in $toDelete) {
        try {
          gh api "repos/$Owner/$Repo/actions/runs/$($r.id)" -X DELETE | Out-Null
          $deleted++
        } catch {
          if ($_.Exception.Message -match 'HTTP 404') {
            Write-Host "Skipped $($r.id) (already gone)"
          } else { throw }
        }
      }
    } else {
      $cnt = @($toDelete).Count
      Write-Host "Dry-run: would delete $cnt run(s)."
    }
  }
  return [int]$deleted
}

$now    = (Get-Date).ToUniversalTime()
$cutoff = $now.AddDays(-[math]::Abs($ThresholdDays))

# Collect targets
$targets = @()
if ($WorkflowNames) { $targets += $WorkflowNames }
if ($WorkflowNamesFile) {
  if (Test-Path $WorkflowNamesFile) {
    $targets += (Get-Content $WorkflowNamesFile | Where-Object { $_.Trim() -ne "" })
  } else {
    Write-Error "WorkflowNamesFile not found: $WorkflowNamesFile"
    exit 1
  }
}
$targets = $targets | ForEach-Object { $_.Trim() } | Sort-Object -Unique
if (-not $targets -or $targets.Count -eq 0) {
  Write-Error "No workflow names provided."
  exit 1
}

# Fetch workflows once
$wfList = (
  gh api "repos/$Owner/$Repo/actions/workflows?per_page=100" |
  ConvertFrom-Json
).workflows

# For issue summary
$logLines = @()
$deletedTotal = 0

foreach ($name in $targets) {
  $wf = Resolve-Workflow -WorkflowList $wfList -Target $name
  if (-not $wf) { Write-Warning "Workflow not found: '$name'"; continue }

  $id   = $wf.id
  $path = $wf.path
  Write-Host "Target: $name (id=$id, path=$path, state=$($wf.state))"

  if ($DisableWorkflows -and $wf.state -eq "active") {
    gh workflow disable "$id" --repo "$Owner/$Repo" | Out-Null
    Write-Host "Disabled '$name'."
  }

  $deleted = Remove-WorkflowRunsById `
    -Owner $Owner -Repo $Repo -WorkflowId $id -ThresholdDays $ThresholdDays -Apply:$Apply

  if ($Apply) {
    Write-Host "Deleted $deleted run(s) for '$name'."
    $deletedTotal += [int]$deleted
    $logLines += "Deleted $deleted run(s) for '$name' (path=$path)"
  } else {
    $logLines += "Dry-run: would delete runs for '$name' (path=$path)"
  }
}

# Log to GitHub Issue (no labels)
if ($LogToIssue -and $logLines.Count -gt 0) {
  $ts = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
  $body = @"
Workflow run cleanup
Repo: $Owner/$Repo
Timestamp: $ts
ThresholdDays: $ThresholdDays
Apply: $Apply
DeletedTotal: $deletedTotal

Details:
$($logLines -join "`n")
"@

  $existing = gh issue list `
    --repo "$Owner/$Repo" `
    --search "$IssueTitle" `
    --state open `
    --json number `
    --jq '.[0].number'

  if ($existing) {
    gh issue comment $existing --repo "$Owner/$Repo" --body "$body" | Out-Null
    Write-Host "Updated issue #$existing with cleanup details."
  } else {
    gh issue create `
      --repo "$Owner/$Repo" `
      --title "$IssueTitle" `
      --body "$body" | Out-Null

    $newIssueNum = gh issue list `
      --repo "$Owner/$Repo" `
      --search "$IssueTitle" `
      --state open `
      --json number `
      --jq '.[0].number'
    Write-Host "Created issue #$newIssueNum"
  }
}

Write-Host "Done."

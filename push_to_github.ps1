param(
  [ValidateSet("https","ssh")] [string]$RemoteType = "https",
  [string]$RemoteUrlHttps = "https://github.com/zahedasghar/d4d.git",
  [string]$RemoteUrlSsh = "git@github.com:zahedasghar/d4d.git",
  [string]$Branch = "main",
  [string]$CommitMessage = "Initial commit: add project files"
)

# Check for git
try {
  & git --version > $null 2>&1
} catch {
  Write-Error "git not found in PATH. Install git and re-run the script."
  exit 1
}

# Init repo if needed
if (-not (Test-Path .git)) {
  & git init
  & git checkout -b $Branch
}

# Choose remote URL
if ($RemoteType -eq "ssh") {
  $remoteUrl = $RemoteUrlSsh
} else {
  $remoteUrl = $RemoteUrlHttps
}

# Add remote origin if not present, or update it if different
$existing = & git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
  & git remote add origin $remoteUrl
} elseif ($existing -ne $remoteUrl) {
  & git remote set-url origin $remoteUrl
}

# Stage changes
& git add -A

# Commit only if there are staged changes
$changes = & git diff --cached --name-only
if ($changes) {
  & git commit -m $CommitMessage
} else {
  Write-Host "No staged changes to commit."
}

# Push (set upstream on first push)
& git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>$null
if ($LASTEXITCODE -ne 0) {
  & git push -u origin $Branch
} else {
  & git push
}

# Final note
Write-Host "Done. Repository pushed to $remoteUrl (branch: $Branch)."
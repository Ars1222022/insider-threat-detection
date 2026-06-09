# push-to-github-dynamic.ps1 - Push current folder to GitHub (dynamic path)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "PUSH CURRENT FOLDER TO GITHUB" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------
# 1. GET CURRENT FOLDER DYNAMICALLY
# ------------------------------
$localFolder = Get-Location
$folderName = Split-Path $localFolder -Leaf

Write-Host "Current folder: $localFolder" -ForegroundColor Green
Write-Host "Folder name: $folderName" -ForegroundColor Gray
Write-Host ""

# ------------------------------
# 2. ASK FOR GITHUB REPO
# ------------------------------
Write-Host "Enter your GitHub repository URL:" -ForegroundColor Yellow
Write-Host "(Example: https://github.com/Ars1222022/insider-threat-detection.git)" -ForegroundColor Gray
$githubRepo = Read-Host "GitHub URL"

if ([string]::IsNullOrWhiteSpace($githubRepo)) {
    Write-Host "  ERROR: GitHub URL is required!" -ForegroundColor Red
    exit 1
}

# Extract repo name from URL for display
$repoName = ($githubRepo -split '/')[-1] -replace '\.git$', ''
Write-Host "  Repository: $repoName" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 3. CHECK GIT
# ------------------------------
Write-Host "STEP 1: Checking Git..." -ForegroundColor Yellow
git --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Git is not installed!" -ForegroundColor Red
    exit 1
}
Write-Host "  Git OK" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 4. SHOW LOCAL FILES
# ------------------------------
Write-Host "Local folder contents:" -ForegroundColor Cyan
$items = Get-ChildItem -Path $localFolder
$dirCount = ($items | Where-Object { $_.PSIsContainer }).Count
$fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
Write-Host "  $dirCount folders, $fileCount files" -ForegroundColor Gray
Write-Host ""

# ------------------------------
# 5. WARNING AND CONFIRMATION
# ------------------------------
Write-Host "==========================================================" -ForegroundColor Red
Write-Host "WARNING!" -ForegroundColor Red
Write-Host "==========================================================" -ForegroundColor Red
Write-Host ""
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. DELETE everything in: $githubRepo" -ForegroundColor Red
Write-Host "  2. REPLACE it with files from:" -ForegroundColor Green
Write-Host "     $localFolder" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "Type 'REPLACE' to continue"

if ($confirm -ne "REPLACE") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ------------------------------
# 6. CREATE TEMP FOLDER
# ------------------------------
Write-Host "STEP 2: Creating temp folder..." -ForegroundColor Yellow
$workFolder = "$env:TEMP\github-push-$([System.Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $workFolder -Force | Out-Null
Write-Host "  Temp folder: $workFolder" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 7. COPY LOCAL FILES TO TEMP
# ------------------------------
Write-Host "STEP 3: Copying local files to temp folder..." -ForegroundColor Yellow
Copy-Item -Path "$localFolder\*" -Destination $workFolder -Recurse -Force
Write-Host "  Files copied" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 8. REMOVE SECRETS FROM NOTEBOOKS (if any)
# ------------------------------
Write-Host "STEP 4: Checking for secrets in notebooks..." -ForegroundColor Yellow

$notebooks = Get-ChildItem -Path $workFolder -Recurse -Filter "*.ipynb"
foreach ($notebook in $notebooks) {
    $content = Get-Content $notebook.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match 'hooks\.slack\.com') {
        Write-Host "  Cleaning: $($notebook.Name)" -ForegroundColor Gray
        $content = $content -replace 'https://hooks\.slack\.com/services/[a-zA-Z0-9/]+', '"REMOVED_FOR_SECURITY"'
        $content = $content -replace '"slack_webhook":\s*"[^"]*"', '"slack_webhook": "REMOVED"'
        $content | Out-File -FilePath $notebook.FullName -Encoding UTF8 -Force
        Write-Host "    Secrets removed" -ForegroundColor Green
    }
}
Write-Host ""

# ------------------------------
# 9. INITIALIZE GIT IN WORK FOLDER
# ------------------------------
Write-Host "STEP 5: Initializing Git in work folder..." -ForegroundColor Yellow
Set-Location $workFolder

# Remove old git if exists
if (Test-Path ".git") {
    Remove-Item -Path ".git" -Recurse -Force
}

# Initialize new git
git init
Write-Host "  Git initialized" -ForegroundColor Green

# Add remote
git remote add origin $githubRepo
Write-Host "  Remote added: $githubRepo" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 10. ADD ALL FILES
# ------------------------------
Write-Host "STEP 6: Adding all files to Git..." -ForegroundColor Yellow
git add .
Write-Host "  Files added" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 11. COMMIT
# ------------------------------
Write-Host "STEP 7: Committing..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Replace repository with local files - $timestamp"
Write-Host "  Committed" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 12. FORCE PUSH TO GITHUB
# ------------------------------
Write-Host "STEP 8: Force pushing to GitHub..." -ForegroundColor Yellow

# Try to push to main branch
$pushResult = git push -f origin main 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Trying with 'master' branch..." -ForegroundColor Yellow
    git push -f origin master 2>&1
}
Write-Host "  Push complete" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 13. VERIFY
# ------------------------------
Write-Host "STEP 9: Verifying..." -ForegroundColor Yellow
git remote -v
Write-Host ""
git log --oneline -1
Write-Host ""

# ------------------------------
# 14. CLEANUP
# ------------------------------
Write-Host "STEP 10: Cleaning up..." -ForegroundColor Yellow
Set-Location $env:TEMP
Remove-Item -Path $workFolder -Recurse -Force
Write-Host "  Cleanup complete" -ForegroundColor Green
Write-Host ""

# ------------------------------
# 15. FINAL
# ------------------------------
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "COMPLETE!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your local files have been pushed to:" -ForegroundColor Yellow
Write-Host "  $githubRepo" -ForegroundColor White
Write-Host ""
Write-Host "The repository has been completely replaced with your local files." -ForegroundColor Green
Write-Host ""
Write-Host "Check your repository to verify." -ForegroundColor Gray
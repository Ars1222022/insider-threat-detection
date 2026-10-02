# ==============================================================
# push_github.ps1 - Laddar upp projektet till GitHub (sakert)
# ==============================================================
# Detta skript gor fyra saker, i ordning:
#   1. Kollar att Git ar installerat och att vi ar i en git-mapp
#   2. Laddar med alla nya/andrade filer (git add)
#   3. Sparar en commit med ett meddelande du skriver
#   4. Skickar till GitHub
#
# VAD DET INTE GOR (viktigt):
#   - Det raderar INTE nagot pa GitHub
#   - Det anvander INTE --force ( overskriver inte andras andringar)
#   - Det ror INTE filerna pa disk
#
# ANVANDNING:
#   1. Hogerklicka i projektmappen -> "Open in Terminal"
#   2. Skriv:  .\push_github.ps1
#   3. Skriv ett meddelande om vad du andrade
#
# OM DU FAR FEL:
#   - "fatal: not a git repository" -> du ar fel i mappen
#   - "Updates were rejected"       -> nagon har skickat sedan sist
# ==============================================================

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------
# 1. KOLLA ATT GIT FINNS
# --------------------------------------------------------------
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " PUSHA PROJEKTET TILL GITHUB" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

git --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEL: Git ar inte installerat." -ForegroundColor Red
    Write-Host "Ladda ner det pa: https://git-scm.com/downloads" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}
Write-Host "Git finns: $(git --version)" -ForegroundColor Green

# --------------------------------------------------------------
# 2. KOLLA ATT VI AR I EN GIT-MAPP
# --------------------------------------------------------------
$isRepo = git rev-parse --is-inside-work-tree 2>$null
if ($isRepo -ne "true") {
    Write-Host ""
    Write-Host "FEL: Detta ar inte en git-mapp." -ForegroundColor Red
    Write-Host "Du behover kora skriptet INNE i projektmappen." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}
Write-Host "Git-mapp: OK" -ForegroundColor Green

# --------------------------------------------------------------
# 3. VISA VAD SOM SKA LADDAS UPP
# --------------------------------------------------------------
Write-Host ""
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Filer som kommer att laddas upp:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
$changed = git status --porcelain
if ($changed) {
    $count = 0
    foreach ($line in $changed) {

# --------------------------------------------------------------
# 4. SAKRAHETSKONTROLL: HEMLIGHETER
# --------------------------------------------------------------
Write-Host ""
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Sakerhetskoll av hemligheter" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

$secretPatterns = @(
    'hooks\.slack\.com',
    'gsk_[A-Za-z0-9]',
    'xox[baprs]-',
    'snowflakecomputing\.com',
    'AKIA[0-9A-Z]',
    'BEGIN (RSA |OPENSSH )?PRIVATE KEY'
)

$foundSecrets = @()
$filesToCheck = git status --porcelain | ForEach-Object { $_.Substring(3) } | Where-Object {
    $_ -match '\.(ipynb|py|md|ps1|txt|json|yml|yaml|csv)$'
}

foreach ($f in $filesToCheck) {
    if (Test-Path -LiteralPath $f -PathType Leaf) {
        $content = Get-Content -LiteralPath $f -Raw -ErrorAction SilentlyContinue
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                $foundSecrets += "$f  (matchade: $pattern)"
            }
        }
    }
}

if ($foundSecrets.Count -gt 0) {
    Write-Host ""
    Write-Host "VARNING: Detta ser ut som hemligheter:" -ForegroundColor Red
    foreach ($s in $foundSecrets) {
        Write-Host "   $s" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Tryck Enter for att AVBRYTA, eller skriv 'pusha' for att fortsatta." -ForegroundColor Red
    $choice = Read-Host
    if ($choice -ne "pusha") {
        Write-Host "Avbruten. Inget laddades upp." -ForegroundColor Yellow
        pause
        exit 0
    }
    Write-Host "Fortsatter trots varningen..." -ForegroundColor Yellow
} else {
    Write-Host "Inga hemligheter hittade. OK." -ForegroundColor Green
}

# --------------------------------------------------------------
# 5. FRAGA OM BEKRAFTELSE
# --------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " SAMMANFATTNING" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
$branch = git branch --show-current
$remote = git remote get-url origin 2>$null
if ($remote) {
    $remote = $remote -replace '^https://github.com/', 'github.com/'
    $remote = $remote -replace '\.git$', ''
}
Write-Host "Mapp:     $((Get-Location).Path)" -ForegroundColor White
Write-Host "Branch:   $branch" -ForegroundColor White
Write-Host "GitHub:   $remote" -ForegroundColor White
Write-Host ""
Write-Host "Detta kommer INTE att radera nagot pa GitHub." -ForegroundColor Green
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan

$go = Read-Host "Vill du ladda upp? Skriv 'ja' for att fortsatta"
if ($go -ne "ja") {

# --------------------------------------------------------------
# 6. LADDA ADD
# --------------------------------------------------------------
Write-Host ""
Write-Host "[1/3] Tar med alla filer..." -ForegroundColor Yellow
git add -A
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEL: kunde inte ladda till filer." -ForegroundColor Red
    pause
    exit 1
}
Write-Host "      OK" -ForegroundColor Green

# Finns det nagont att committa?
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Inga nya andringar att ladda upp - allt ar redan pa GitHub." -ForegroundColor Cyan
    Write-Host "Klart!" -ForegroundColor Green
    Write-Host ""
    pause
    exit 0
}

# --------------------------------------------------------------
# 7. FRAGA OM MEDDELANDE OCH COMMITTA
# --------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Skriv ett meddelande (beskriv vad du andrat):" -ForegroundColor Yellow
Write-Host "      (t.ex. 'Korning steg 8-11', 'Uppdaterade README')" -ForegroundColor Gray
$message = Read-Host "Meddelande"
if ([string]::IsNullOrWhiteSpace($message)) {
    $message = "Uppdatering $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Write-Host "      (inget meddelande - anvande: $message)" -ForegroundColor Gray
}

git commit -m $message
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEL: committen misslyckades." -ForegroundColor Red
    pause
    exit 1
}
Write-Host "      Sparad: $message" -ForegroundColor Green

# --------------------------------------------------------------
# 8. PUSH
# --------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Skickar till GitHub..." -ForegroundColor Yellow
$pushOutput = git push origin $branch 2>&1
$pushOk = ($LASTEXITCODE -eq 0)

if ($pushOk) {
    Write-Host "      OK - allt finns nu pa GitHub!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host " PUSHEN MISSLYCKADES" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $pushOutput -ForegroundColor Yellow
    Write-Host ""
    if ($pushOutput -match "rejected") {
        Write-Host "Det betyder att nagon annan har skickat andringar" -ForegroundColor Yellow
        Write-Host "sedan du senast laddade ner." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "LOSNING: Koppla ner och slaga ihop:" -ForegroundColor Cyan
        Write-Host "   git pull --rebase origin $branch" -ForegroundColor White
        Write-Host "   .\push_github.ps1" -ForegroundColor White
    } else {
        Write-Host "LOSNING: Kontrollera GitHub-anvandarnamn och losenord" -ForegroundColor Cyan
        Write-Host "i Git Credential Manager." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Dina andringar ar sparade lokalt - du har inte tappat nagot." -ForegroundColor Green
    pause
    exit 1
}

# --------------------------------------------------------------
# 9. KLART
# --------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " KLART!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
if ($remote) {
    Write-Host "Titta pa ditt projekt pa:" -ForegroundColor White
    Write-Host "   $remote" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Du kan nu fortsatta med nasta steg i Databricks." -ForegroundColor DarkGray
Write-Host ""
pause

    Write-Host ""
    Write-Host "Avbruten. Inget hande." -ForegroundColor Yellow
    pause
    exit 0
}

        $count++
        $status = $line.Substring(0, 2).Trim()
        $file = $line.Substring(3)
        switch ($status) {
            "M"   { Write-Host "   [andrad]    $file" -ForegroundColor Yellow }
            "A"   { Write-Host "   [ny]        $file" -ForegroundColor Green }
            "D"   { Write-Host "   [borttagen] $file" -ForegroundColor Red }
            "R"   { Write-Host "   [flyttad]   $file" -ForegroundColor Cyan }
            "??"  { Write-Host "   [ny]        $file" -ForegroundColor Green }
            default { Write-Host "   [$status] $file" -ForegroundColor Gray }
        }
    }
    Write-Host ""
    Write-Host "Totalt: $count fil(er)" -ForegroundColor Cyan
} else {
    Write-Host "   (inga andringar - allt redan uppladdat)" -ForegroundColor DarkGray
}

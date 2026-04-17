# Claude Token Optimizer — Windows PowerShell installer
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

Write-Host "==> Claude Token Optimizer install"
Write-Host "    repo: $RepoDir"
Write-Host "    target: $ClaudeDir"

# prerequisites
foreach ($bin in @("node","npm","python","git")) {
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
        Write-Error "missing: $bin"
    }
}

Write-Host "==> installing global CLIs"
npm install -g "@google/gemini-cli" "@openai/codex"

python -m pip install --user --upgrade pipx | Out-Null
python -m pipx ensurepath | Out-Null
python -m pipx install --force memkraft

if (Get-Command cargo -ErrorAction SilentlyContinue) {
    cargo install rtk-cli
} else {
    Write-Host "    cargo missing → skipping RTK install"
}

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

$TmpSettings = [System.IO.Path]::GetTempFileName()
Copy-Item "$RepoDir\dotclaude\settings.example.json" $TmpSettings -Force

# Patch MCP for Windows
$env:TMP_SETTINGS = $TmpSettings
python - <<'PY'
import json, os
p = os.environ["TMP_SETTINGS"]
with open(p, encoding="utf-8") as f:
    s = json.load(f)
s["mcpServers"]["gemini-cli"] = {"command": "cmd", "args": ["/c", "npx", "-y", "gemini-mcp-tool"]}
s["mcpServers"]["codex"] = {"command": "cmd", "args": ["/c", "codex", "mcp-server"]}
for k in list(s.keys()):
    if k.startswith("_"): del s[k]
for k in list(s["mcpServers"].keys()):
    if k.startswith("_"): del s["mcpServers"][k]
with open(p, "w", encoding="utf-8") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
PY

$SettingsTarget = Join-Path $ClaudeDir "settings.json"
if (Test-Path $SettingsTarget) {
    Write-Host "==> merging into existing settings.json (backup: settings.json.bak)"
    Copy-Item $SettingsTarget "$SettingsTarget.bak" -Force
    $env:EXISTING = $SettingsTarget
    python - <<'PY'
import json, os
with open(os.environ["EXISTING"], encoding="utf-8") as f: existing = json.load(f)
with open(os.environ["TMP_SETTINGS"], encoding="utf-8") as f: new = json.load(f)
existing.setdefault("env", {}).update(new.get("env", {}))
existing.setdefault("mcpServers", {}).update(new.get("mcpServers", {}))
if "permissions" in new:
    allow = set(existing.get("permissions", {}).get("allow", [])) | set(new["permissions"].get("allow", []))
    existing.setdefault("permissions", {})["allow"] = sorted(allow)
with open(os.environ["EXISTING"], "w", encoding="utf-8") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
PY
} else {
    Copy-Item $TmpSettings $SettingsTarget -Force
}
Remove-Item $TmpSettings -Force

$ClaudeMd = Join-Path $ClaudeDir "CLAUDE.md"
if (Test-Path $ClaudeMd) {
    Copy-Item "$RepoDir\dotclaude\CLAUDE.md" "$ClaudeMd.optimizer" -Force
    Write-Host "==> CLAUDE.md exists. new rules saved as CLAUDE.md.optimizer"
} else {
    Copy-Item "$RepoDir\dotclaude\CLAUDE.md" $ClaudeMd -Force
}

# slash commands
$CmdDir = Join-Path $ClaudeDir "commands"
New-Item -ItemType Directory -Force -Path $CmdDir | Out-Null
Get-ChildItem "$RepoDir\dotclaude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $target = Join-Path $CmdDir $_.Name
    if (Test-Path $target) {
        Write-Host "==> command exists: $($_.Name) (skipping)"
    } else {
        Copy-Item $_.FullName $target -Force
        Write-Host "==> installed command: /$($_.Name)"
    }
}

# refs
$RefDir = Join-Path $ClaudeDir "refs"
New-Item -ItemType Directory -Force -Path $RefDir | Out-Null
Get-ChildItem "$RepoDir\dotclaude\refs\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $target = Join-Path $RefDir $_.Name
    if (-not (Test-Path $target)) { Copy-Item $_.FullName $target -Force }
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
    $RtkCfgDir = Join-Path $env:APPDATA "rtk"
    New-Item -ItemType Directory -Force -Path $RtkCfgDir | Out-Null
    $RtkCfg = Join-Path $RtkCfgDir "config.toml"
    if (-not (Test-Path $RtkCfg)) {
        Copy-Item "$RepoDir\rtk\config.example.toml" $RtkCfg -Force
        Write-Host "==> installed RTK config at $RtkCfg"
    }
}

Write-Host ""
Write-Host "==> next steps (manual)"
Write-Host "1. /plugin install caveman"
Write-Host "   /plugin install superpowers"
Write-Host "2. gemini   # auth"
Write-Host "   codex    # auth"
Write-Host "3. per project: bash $RepoDir\scripts\setup-project.sh"
Write-Host "4. verify: bash $RepoDir\scripts\verify.sh"
Write-Host "==> done."

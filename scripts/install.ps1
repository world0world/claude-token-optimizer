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

# Strip mcpServers + comments (MCPs registered via `claude mcp add`)
$env:TMP_SETTINGS = $TmpSettings
python - <<'PY'
import json, os
p = os.environ["TMP_SETTINGS"]
with open(p, encoding="utf-8") as f:
    s = json.load(f)
s.pop("mcpServers", None)
for k in list(s.keys()):
    if k.startswith("_"): del s[k]
with open(p, "w", encoding="utf-8") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
PY

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "==> registering MCP servers via claude mcp add"
    & claude mcp add gemini-cli -s user -- cmd /c npx -y gemini-mcp-tool 2>$null
    & claude mcp add codex -s user -- cmd /c codex mcp-server 2>$null
} else {
    Write-Host "    claude CLI not found"
}

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
if "permissions" in new:
    allow = set(existing.get("permissions", {}).get("allow", [])) | set(new["permissions"].get("allow", []))
    existing.setdefault("permissions", {})["allow"] = sorted(allow)
for k in ("model", "effortLevel", "autoUpdatesChannel"):
    if k in new and k not in existing:
        existing[k] = new[k]
if "hooks" in new:
    existing.setdefault("hooks", {})
    for event, handlers in new["hooks"].items():
        if event not in existing["hooks"]:
            existing["hooks"][event] = handlers
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

# sub-agents
$AgentsDir = Join-Path $ClaudeDir "agents"
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
Get-ChildItem "$RepoDir\dotclaude\agents\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $target = Join-Path $AgentsDir $_.Name
    if (Test-Path $target) {
        Copy-Item $_.FullName "$target.optimizer" -Force
        Write-Host "    agent exists: $($_.Name) → saved as $($_.Name).optimizer"
    } else {
        Copy-Item $_.FullName $target -Force
        Write-Host "    installed agent: $($_.Name)"
    }
}

# slash commands
$CmdDir = Join-Path $ClaudeDir "commands"
New-Item -ItemType Directory -Force -Path $CmdDir | Out-Null
Get-ChildItem "$RepoDir\dotclaude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $target = Join-Path $CmdDir $_.Name
    if (Test-Path $target) {
        Copy-Item $_.FullName "$target.optimizer" -Force
        Write-Host "==> command exists: $($_.Name) → saved as $($_.Name).optimizer"
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

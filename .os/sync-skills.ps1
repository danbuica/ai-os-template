# Windows fallback: copies .agents/skills (the master copy) into .claude/skills so Claude Code sees the skills.
# The startup hook normally does this by itself (through Git's own shell). Run this by hand only if
# Claude Code shows no skills:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .os\sync-skills.ps1
#
# Never edit skills inside .claude/skills. Edit them in .agents/skills.
# .claude/skills is never uploaded to GitHub (it's in .gitignore).

param([switch]$Quiet)

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root '.agents\skills'
$dst = Join-Path $root '.claude\skills'

if (-not (Test-Path -LiteralPath $src)) {
    if (-not $Quiet) { Write-Output 'No .agents\skills folder found, nothing to do.' }
    exit 1
}

New-Item -ItemType Directory -Force -Path (Join-Path $root '.claude') | Out-Null

if (Test-Path -LiteralPath $dst) {
    $item = Get-Item -LiteralPath $dst -Force
    if ($item.LinkType -or -not $item.PSIsContainer) {
        # A link, or the small text file Git makes instead of a link: remove only that,
        # never what it points to.
        $item.Delete()
    } else {
        # An old copy: replace it.
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
}

Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force

if ($Quiet) { Write-Output 'changed' } else { Write-Output 'Copied .agents\skills into .claude\skills.' }

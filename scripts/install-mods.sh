#!/usr/bin/env bash
# Installs the 9 mods from the "9 Claude Mods" guide, once, for your user,
# so they load in every Claude Code session on this computer.
#
# Run it in a normal terminal, NOT inside a Claude Code session:
#   Mac / Linux:  bash scripts/install-mods.sh
#   Windows:      open Git Bash, then  bash scripts/install-mods.sh
#
# Safe to run again: it skips what is already there.
# Mods do not run in cloud (claude.ai/code) sessions, the regular chat or the
# VS Code extension. They run in the terminal and the desktop app's Code tab.

set -u
ok=(); failed=()

run() { # run <label> <command...>
  local label=$1; shift
  if "$@"; then ok+=("$label"); else failed+=("$label"); fi
}

market() { claude plugin marketplace add "$1" >/dev/null 2>&1 || true; }

command -v claude >/dev/null || { echo "Claude Code is not installed. Install it first."; exit 1; }
echo "Updating Claude Code (mods need 2.1.287 or newer)..."
claude update >/dev/null 2>&1 || true

# Your own forks first, so nothing is installed twice.
market apexledgerr-wq/claude-kit             # savvy-progress (your copy of johnnyvizz/claude-kit)
market apexledgerr-wq/claude-code-filetree   # filetree (your copy of data-goblin/claude-code-filetree)
market hellosverre/claude-skins
market karanb192/claude-code-mods
market bayramannakov/claude-reflect

# Blast Radius and Replay Theater live in a folder of Anthropic's playground
# repo. Keep a copy in ~/.claude/mods-src so they survive across sessions.
# Do not move or delete that folder later, or these two stop loading.
src="$HOME/.claude/mods-src/claude-code-playground"
if [ -d "$src/.git" ]; then git -C "$src" pull -q || true
else mkdir -p "$(dirname "$src")" && git clone -q --depth 1 https://github.com/anthropics/claude-code-playground.git "$src"; fi
market "$src/claude-code/mods"

run "01 Savvy Progress"    claude plugin install savvy-progress@claude-kit --scope user
run "02 Claude Skins"      claude plugin install skins@hellosverre-mods --scope user
run "03 You Should Know"   claude plugin enable cc-plugin-you-should-know@builtin --scope user
run "04 Filetree"          claude plugin install filetree@claude-code-filetree --scope user
run "05 Cache Tax"         claude plugin install cache-tax@claude-code-mods --scope user
run "06 Blast Radius"      claude plugin install blast-radius@claude-code-playground-mods --scope user
run "07 Reflect"           claude plugin install reflect-mod@claude-reflect-marketplace --scope user
run "09 Replay Theater"    claude plugin install replay-theater@claude-code-playground-mods --scope user

# Terminal Browser: Mac and Linux terminals only (not Windows, not the desktop app).
case "$(uname -s)" in
  Darwin|Linux)
    if command -v brew >/dev/null; then brew install terminal-browser >/dev/null 2>&1 || true; fi
    if command -v terminal-browser >/dev/null; then
      market zenbu-labs/terminal-browser
      run "08 Terminal Browser" claude plugin install terminal-browser@terminal-browser --scope user
    else
      failed+=("08 Terminal Browser (install Homebrew, then run this script again)")
    fi ;;
  *) echo "Skipping 08 Terminal Browser: it does not run on Windows." ;;
esac

echo
echo "Installed: ${#ok[@]}"; printf '  ok   %s\n' "${ok[@]}"
[ ${#failed[@]} -gt 0 ] && { echo "Failed: ${#failed[@]}"; printf '  FAIL %s\n' "${failed[@]}"; }
echo
echo "Now open a NEW Claude Code session, type /tui fullscreen, and try:"
echo "  /agents-info   /skin dracula   /filetree   /keepwarm 90m   /replay"
command -v terminal-browser >/dev/null && echo "  /browser"

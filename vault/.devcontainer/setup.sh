#!/bin/bash
# ==============================================================================
# AGENTS-OS v5.0 — Devcontainer / Codespaces Bootstrap
# Uruchamiany automatycznie przez postCreateCommand w devcontainer.json
# ==============================================================================
set -e

echo "🛸 Konfiguracja AGENTS-OS v5.0 w środowisku Devcontainer..."

# --------------------------------------------------------------------------- #
# 1. Python venv + zależności
# --------------------------------------------------------------------------- #
echo "🐍 Konfiguracja środowiska Python..."
python3 -m venv "$HOME/.antigravity/venv" 2>/dev/null || true
"$HOME/.antigravity/venv/bin/pip" install --upgrade pip --quiet
"$HOME/.antigravity/venv/bin/pip" install GitPython PyGithub --quiet
echo "   ✅ Python venv gotowy: ~/.antigravity/venv"

# --------------------------------------------------------------------------- #
# 2. Kopiowanie Vault (szablony projektów)
# --------------------------------------------------------------------------- #
AGY_DIR="$HOME/.antigravity"
VAULT_DIR="$AGY_DIR/templates/v5.0-swarm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🛡️ Kopiowanie szablonów projektów (Vault)..."
mkdir -p "$VAULT_DIR"
cp -ra "$PROJECT_ROOT/vault/." "$VAULT_DIR/"
echo "   ✅ Vault skopiowany do: $VAULT_DIR"

# --------------------------------------------------------------------------- #
# 3. Globalne skille
# --------------------------------------------------------------------------- #
echo "🧠 Instalacja globalnych skilli..."
for skill_dir in "$PROJECT_ROOT/global_skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$AGY_DIR/skills/$skill_name"
    cp -ra "$skill_dir." "$AGY_DIR/skills/$skill_name/"
done
echo "   ✅ Skille zainstalowane"

# --------------------------------------------------------------------------- #
# 4. Pre-commit security hook
# --------------------------------------------------------------------------- #
if [ -f "$PROJECT_ROOT/hooks/pre-commit" ] && [ -d "$PROJECT_ROOT/.git/hooks" ]; then
    cp "$PROJECT_ROOT/hooks/pre-commit" "$PROJECT_ROOT/.git/hooks/pre-commit"
    chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
    echo "   ✅ Pre-commit security hook zainstalowany"
fi

# --------------------------------------------------------------------------- #
# 5. Shell config (os-init, os-add-skill jako funkcje)
# --------------------------------------------------------------------------- #
echo "⚙️ Konfiguracja komend powłoki..."
mkdir -p "$HOME/.bashrc.d"
cat > "$HOME/.bashrc.d/antigravity" <<'SHELLEOF'
# AGENTS-OS v5.0 — shell integration (devcontainer)
export PATH="$HOME/.local/bin:$HOME/.antigravity/venv/bin:$PATH"

os-init() {
    local AGENTS_OS_SCRIPT
    AGENTS_OS_SCRIPT="$(find /workspaces -name 'os-init' -maxdepth 3 2>/dev/null | head -1)"
    if [ -z "$AGENTS_OS_SCRIPT" ]; then
        echo "❌ os-init nie znaleziony w /workspaces"
        return 1
    fi
    bash "$AGENTS_OS_SCRIPT" "$@"
    if [ -n "$OS_INIT_PROJECT_DIR" ]; then
        cd "$OS_INIT_PROJECT_DIR"
    fi
}

os-add-skill() {
    local AGENTS_OS_SCRIPT
    AGENTS_OS_SCRIPT="$(find /workspaces -name 'os-add-skill' -maxdepth 3 2>/dev/null | head -1)"
    if [ -z "$AGENTS_OS_SCRIPT" ]; then
        echo "❌ os-add-skill nie znaleziony w /workspaces"
        return 1
    fi
    python3 "$AGENTS_OS_SCRIPT" "$@"
}
SHELLEOF

# Załaduj do bieżącej sesji
echo 'source "$HOME/.bashrc.d/antigravity"' >> "$HOME/.bashrc" 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ AGENTS-OS v5.0 Devcontainer GOTOWY"
echo ""
echo "  Dostępne komendy:"
echo "    os-init <nazwa-projektu>   — Utwórz nowy projekt Swarm"
echo "    os-add-skill <skill>       — Dodaj skill do projektu"
echo ""
echo "  🔑 Zaloguj się do GitHub: gh auth login"
echo "═══════════════════════════════════════════════════════"

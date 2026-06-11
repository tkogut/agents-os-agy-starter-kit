#!/bin/bash
# ==============================================================================
# AGENTS-OS v5.0 SWARM EDITION - UNIVERSAL INSTALLER
# Platforms: Linux (Debian/Ubuntu/WSL), macOS (Homebrew, ARM + Intel)
# Architekt: Antigravity Orchestrator & Community
# ==============================================================================

set -e

echo "🚀 Starting AGENTS-OS v5.0 Swarm Edition installation..."

# Ensure required directories exist on host to avoid docker mounting issues
mkdir -p "$HOME/.ssh" "$HOME/.config/gh" "$HOME/projects" "$HOME/.antigravity"

# --------------------------------------------------------------------------- #
# 0. Platform detection
# --------------------------------------------------------------------------- #
OS_TYPE="$(uname -s)"
ARCH="$(uname -m)"

IS_MACOS=false
IS_LINUX=false
IS_WSL=false
IS_DEVCONTAINER=false
BREW_PREFIX=""

case "$OS_TYPE" in
    Darwin)
        IS_MACOS=true
        # Detect Homebrew prefix (ARM Apple Silicon vs Intel)
        if [ "$ARCH" = "arm64" ]; then
            BREW_PREFIX="/opt/homebrew"
        else
            BREW_PREFIX="/usr/local"
        fi
        echo "🍎 Platform: macOS ($ARCH) | Homebrew prefix: $BREW_PREFIX"
        ;;
    Linux)
        IS_LINUX=true
        if grep -qi microsoft /proc/version 2>/dev/null; then
            IS_WSL=true
            echo "🐧 Platform: Linux / WSL2"
        elif [ -f "/.dockerenv" ] || [ "${AGENTS_OS_ENV}" = "devcontainer" ]; then
            IS_DEVCONTAINER=true
            echo "🐳 Platform: Devcontainer / Docker"
        else
            echo "🐧 Platform: Linux"
        fi
        ;;
    *)
        echo "⚠️  Unknown platform: $OS_TYPE. Proceeding with caution..."
        IS_LINUX=true
        ;;
esac

# --------------------------------------------------------------------------- #
# 1. System dependencies
# --------------------------------------------------------------------------- #

if command -v agy &> /dev/null || [ -f "/usr/local/bin/agy" ] || [ -f "$HOME/.local/bin/agy" ]; then
    echo "Antigravity CLI (agy) is already installed. Skipping download."
else
    echo "Downloading and installing Antigravity CLI (Go Binary)..."
    # Select manifest based on platform
    if $IS_MACOS; then
        if [ "$ARCH" = "arm64" ]; then
            MANIFEST_PLATFORM="darwin_arm64"
            FALLBACK_URL="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.2-6109799369277440/darwin-arm64/cli_darwin_arm64.tar.gz"
        else
            MANIFEST_PLATFORM="darwin_amd64"
            FALLBACK_URL="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.2-6109799369277440/darwin-x64/cli_darwin_x64.tar.gz"
        fi
    else
        MANIFEST_PLATFORM="linux_amd64"
        FALLBACK_URL="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.2-6109799369277440/linux-x64/cli_linux_x64.tar.gz"
    fi
    CLI_URL=$(curl -fsSL "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/${MANIFEST_PLATFORM}.json" | grep -o '"url": *"[^"]*"' | sed 's/"url": *//;s/"//g')
    if [ -z "$CLI_URL" ]; then
        CLI_URL="$FALLBACK_URL"
    fi
    curl -fL -o antigravity.tar.gz "$CLI_URL"
    tar -xzf antigravity.tar.gz
    mv antigravity agy 2>/dev/null || true
    if sudo -n mv agy /usr/local/bin/ 2>/dev/null; then
        echo "✓ agy installed in /usr/local/bin"
    else
        mkdir -p "$HOME/.local/bin"
        mv agy "$HOME/.local/bin/"
        echo "✓ agy installed in $HOME/.local/bin"
    fi
    rm -f antigravity.tar.gz
fi

if ! command -v gh &> /dev/null; then
  if $IS_MACOS; then
      echo "📦 Installing github-cli (gh) via Homebrew..."
      # Ensure Homebrew is available
      if ! command -v brew &>/dev/null; then
          echo "   ⚠️  Homebrew not found. Installing Homebrew..."
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          # Load Homebrew into current session
          eval "$("${BREW_PREFIX}/bin/brew" shellenv)" 2>/dev/null || true
      fi
      brew install gh
      echo "   ✓ gh installed via Homebrew"
  else
      echo "📦 Installing github-cli (gh) via APT..."
      if sudo -n true 2>/dev/null; then
          sudo apt-get update -y &>/dev/null
          sudo apt-get install -y curl gpg &>/dev/null
          sudo mkdir -p /etc/apt/keyrings
          sudo chmod 0755 /etc/apt/keyrings
          curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
          sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
          sudo apt-get update -y &>/dev/null
          sudo apt-get install -y gh &>/dev/null
          echo "   ✓ gh installed via APT"
      else
          echo "⚠️ No passwordless sudo available. Attempting interactive gh installation..."
          if sudo apt-get update && sudo apt-get install -y curl gpg && \
             sudo mkdir -p /etc/apt/keyrings && sudo chmod 0755 /etc/apt/keyrings && \
             curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
             sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
             echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
             sudo apt-get update && sudo apt-get install -y gh; then
              echo "   ✓ gh installed via APT"
          else
              echo "⚠️ Failed to install gh. Install manually: https://cli.github.com"
          fi
      fi
  fi
fi

echo "📦 Configuring isolated Python environment (venv)..."
# On macOS use python3 from Homebrew if available
if $IS_MACOS && [ -x "${BREW_PREFIX}/bin/python3" ]; then
    PYTHON3_BIN="${BREW_PREFIX}/bin/python3"
else
    PYTHON3_BIN="python3"
fi

if "$PYTHON3_BIN" -m venv "$HOME/.antigravity/venv" 2>/dev/null; then
    "$HOME/.antigravity/venv/bin/pip" install --upgrade pip &>/dev/null || true
    echo "📦 Installing Python dependencies (GitPython, PyGithub) in venv..."
    "$HOME/.antigravity/venv/bin/pip" install GitPython PyGithub
else
    if $IS_MACOS; then
        echo "⚠️ Failed to create venv. Retrying with Homebrew python..."
        brew install python3 &>/dev/null || true
        "${BREW_PREFIX}/bin/python3" -m venv "$HOME/.antigravity/venv" 2>/dev/null || true
    else
        echo "⚠️ Failed to create venv. Attempting to install python3-venv..."
        if sudo -n true 2>/dev/null; then
            sudo apt-get update -y &>/dev/null
            sudo apt-get install -y python3-venv &>/dev/null
        else
            sudo apt-get update && sudo apt-get install -y python3-venv
        fi
        python3 -m venv "$HOME/.antigravity/venv" 2>/dev/null || true
    fi
    if [ -f "$HOME/.antigravity/venv/bin/pip" ]; then
        "$HOME/.antigravity/venv/bin/pip" install --upgrade pip &>/dev/null || true
        "$HOME/.antigravity/venv/bin/pip" install GitPython PyGithub
    else
        echo "⚠️ Cannot create venv. Installing Python libraries globally..."
        pip3 install GitPython PyGithub --break-system-packages || pip3 install GitPython PyGithub || echo "⚠️ Failed to install Python dependencies."
    fi
fi

# 2. Integration with identity compression module (Caveman)
echo "🛡️ Integrating identity compression module (Caveman)..."

# 3. Copying The Vault
AGY_DIR="$HOME/.antigravity"
VAULT_DIR="$AGY_DIR/templates/v5.0-swarm"

# Clean up old template versions to keep the system tidy
echo "🧹 Cleaning up old templates..."
if [ -d "$AGY_DIR/templates/v4.2-swarm" ]; then
    rm -rf "$AGY_DIR/templates/v4.2-swarm"
    echo "   ✓ Removed obsolete template v4.2-swarm"
fi

echo "✨ Deploy: The Template Vault (Golden Standard)..."
mkdir -p "$VAULT_DIR"
cp -ra ./vault/. "$VAULT_DIR/"

# 4. Global Skills
echo "🧠 Deploying automation systems (Swarm Bootstrapper)..."
mkdir -p "$AGY_DIR/skills/swarm-bootstrapper"
cp -ra ./global_skills/swarm-bootstrapper/. "$AGY_DIR/skills/swarm-bootstrapper/"

mkdir -p "$AGY_DIR/skills/browser-connectivity"
cp -ra ./global_skills/browser-connectivity/. "$AGY_DIR/skills/browser-connectivity/"

mkdir -p "$AGY_DIR/skills/github-orchestrator"
cp -ra ./global_skills/github-orchestrator/. "$AGY_DIR/skills/github-orchestrator/"

mkdir -p "$AGY_DIR/skills/logic-auditor"
cp -ra ./global_skills/logic-auditor/. "$AGY_DIR/skills/logic-auditor/"

mkdir -p "$AGY_DIR/skills/rebuild-skill"
cp -ra ./global_skills/rebuild-skill/. "$AGY_DIR/skills/rebuild-skill/"

echo "⚙️ Downloading RAG skills catalog..."
mkdir -p "$VAULT_DIR/.agents/specs"
curl -fsSL -o "$VAULT_DIR/.agents/specs/awesome-skills-catalog.md" "https://raw.githubusercontent.com/sickn33/antigravity-awesome-skills/main/CATALOG.md" || echo "⚠️  Failed to download skills catalog."

echo "⚙️ Registering system tools (backend)..."
if [ -f "./os-init" ]; then
    if sudo -n cp ./os-init /usr/local/bin/os-init-run 2>/dev/null; then
        sudo -n chmod +x /usr/local/bin/os-init-run
        echo "✓ os-init-run registered in /usr/local/bin/os-init-run"
    else
        mkdir -p "$HOME/.local/bin"
        cp ./os-init "$HOME/.local/bin/os-init-run"
        chmod +x "$HOME/.local/bin/os-init-run"
        echo "✓ os-init-run registered in $HOME/.local/bin/os-init-run"
    fi
fi

if [ -f "./os-add-skill" ]; then
    # Cleanup: remove old os-add-skill-run file from v4.1.x if it exists
    sudo -n rm -f /usr/local/bin/os-add-skill-run 2>/dev/null || rm -f "$HOME/.local/bin/os-add-skill-run" 2>/dev/null || true

    if sudo -n cp ./os-add-skill /usr/local/bin/os-add-skill 2>/dev/null; then
        sudo -n chmod +x /usr/local/bin/os-add-skill
        echo "✓ os-add-skill installed in /usr/local/bin/os-add-skill"
    else
        mkdir -p "$HOME/.local/bin"
        cp ./os-add-skill "$HOME/.local/bin/os-add-skill"
        chmod +x "$HOME/.local/bin/os-add-skill"
        echo "✓ os-add-skill installed in $HOME/.local/bin/os-add-skill"
    fi
fi

# 5. Pre-commit Security Hook installation
echo "🔐 Installing pre-commit security hook..."
if [ -f "./hooks/pre-commit" ]; then
    # Install hook in current repo (if inside a git repository)
    if [ -d ".git/hooks" ]; then
        cp ./hooks/pre-commit .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
        echo "   ✓ pre-commit hook installed in .git/hooks/"
    fi
    # Copy hook to vault template — new projects inherit it automatically
    mkdir -p "$VAULT_DIR/hooks"
    cp ./hooks/pre-commit "$VAULT_DIR/hooks/pre-commit"
    chmod +x "$VAULT_DIR/hooks/pre-commit"
    echo "   ✓ pre-commit hook added to Vault template (new projects inherit it automatically)"
fi

# 5b. Docker environment configuration
echo "🐳 Configuring Docker compose environment variables in .env..."
if [ -f ".env" ]; then
    # Remove existing entries to prevent duplicates
    sed -i '/^UID=/d' .env
    sed -i '/^GID=/d' .env
    sed -i '/^HOST_HOME=/d' .env
fi
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
echo "HOST_HOME=$HOME" >> .env
echo "   ✓ Local host user variables set in .env (HOST_HOME=$HOME)"

echo "⚙️ Generating and registering shell configuration in ~/.bashrc.d/antigravity..."
mkdir -p "$HOME/.bashrc.d"
cat << 'EOF' > "$HOME/.bashrc.d/antigravity"
# Antigravity launch function for IDE (WSL only)
antigravity() {
    local win_user
    win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [ -z "$win_user" ]; then
        local user_dir
        for user_dir in /mnt/c/Users/*; do
            if [ -f "${user_dir}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" ]; then
                win_user=$(basename "$user_dir")
                break
            fi
        done
    fi
    if [ -z "$win_user" ]; then
        echo "⚠️  Antigravity IDE (Windows) not found. Open manually."
        return 1
    fi
    "/mnt/c/Users/${win_user}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" --remote wsl+Ubuntu "$(pwd)"
}
alias antigravity-ide='antigravity'

# PATH: ~/.local/bin (Linux/WSL)
export PATH="$HOME/.local/bin:$HOME/.antigravity/venv/bin:$PATH"

# ==============================================================================
# os-init <project-name>
# Shell function wrapper — enables cd into the new project after creation.
# Calls the actual os-init-run script, then changes into the new directory.
# ==============================================================================
os-init() {
    local script
    # Look for the installed script
    if command -v os-init-run &>/dev/null; then
        script="os-init-run"
    elif [ -f "$HOME/.local/bin/os-init-run" ]; then
        script="$HOME/.local/bin/os-init-run"
    elif [ -f "/usr/local/bin/os-init-run" ]; then
        script="/usr/local/bin/os-init-run"
    else
        echo "❌ os-init: script not found. Run INSTALL.sh."
        return 1
    fi

    # Run script and capture project path
    local output
    output=$(bash "$script" "$@")
    local exit_code=$?

    # Print full output
    echo "$output"

    if [ $exit_code -ne 0 ]; then
        return $exit_code
    fi

    # Extract path and enter project directory
    local project_dir
    project_dir=$(echo "$output" | grep "^__PROJECT_DIR__:" | sed 's/^__PROJECT_DIR__://')
    if [ -n "$project_dir" ] && [ -d "$project_dir" ]; then
        echo ""
        echo "🔀 Switching to project directory..."
        cd "$project_dir" && echo "📁 Now in: $(pwd)"
    fi
}

EOF
chmod +x "$HOME/.bashrc.d/antigravity"
echo "✓ File ~/.bashrc.d/antigravity saved."

# Add to ~/.bashrc (Linux/WSL)
if ! grep -q "source ~/.bashrc.d/antigravity" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Import Antigravity environment settings" >> "$HOME/.bashrc"
    echo "source ~/.bashrc.d/antigravity" >> "$HOME/.bashrc"
    echo "✓ Import added to ~/.bashrc"
fi

# macOS: add Homebrew shellenv + antigravity config to ~/.zprofile
if $IS_MACOS; then
    ZPROFILE="$HOME/.zprofile"
    if [ -n "$BREW_PREFIX" ] && ! grep -q "brew shellenv" "$ZPROFILE" 2>/dev/null; then
        echo "" >> "$ZPROFILE"
        echo "# Homebrew" >> "$ZPROFILE"
        echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$ZPROFILE"
        echo "✓ Homebrew shellenv added to ~/.zprofile"
    fi
    if ! grep -q "source ~/.bashrc.d/antigravity" "$ZPROFILE" 2>/dev/null; then
        echo "" >> "$ZPROFILE"
        echo "# AGENTS-OS" >> "$ZPROFILE"
        echo "source ~/.bashrc.d/antigravity" >> "$ZPROFILE"
        echo "✓ AGENTS-OS config added to ~/.zprofile"
    fi
fi

# 5. WSL extension installation for Antigravity IDE
echo "🔌 Configuring WSL integration for Antigravity IDE..."
IDE_BIN=""
for user_dir in /mnt/c/Users/*; do
    if [ -f "${user_dir}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" ]; then
        IDE_BIN="${user_dir}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide"
        break
    fi
done

if [ -z "$IDE_BIN" ]; then
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [ -n "$WIN_USER" ] && [ -f "/mnt/c/Users/${WIN_USER}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide" ]; then
        IDE_BIN="/mnt/c/Users/${WIN_USER}/AppData/Local/Programs/Antigravity IDE/bin/antigravity-ide"
    fi
fi

if [ -n "$IDE_BIN" ]; then
    echo "   📦 Installing Remote - WSL extension..."
    if "$IDE_BIN" --install-extension ms-vscode-remote.remote-wsl &>/dev/null; then
        echo "   ✓ Remote - WSL extension installed successfully."
    else
        echo "   ⚠️  Failed to automatically install Remote - WSL extension."
        echo "      Install it manually in the IDE or run:"
        echo "      \"$IDE_BIN\" --install-extension ms-vscode-remote.remote-wsl"
    fi
else
    echo "   ⚠️  Antigravity IDE installation not found on Windows."
fi

echo ""
echo "ℹ️  To activate os-init and os-add-skill in the current terminal:"
echo "   source ~/.bashrc.d/antigravity"

# 6. Authorization and login to CLI services (interactive mode only)
if [ -t 0 ]; then
    echo "🔑 Interactive terminal detected. Configuring CLI authorization..."
    
    # GitHub CLI login
    if command -v gh &> /dev/null; then
        if ! gh auth status &>/dev/null; then
            echo "🐙 Logging in to GitHub CLI (required for repository synchronization):"
            gh auth login || echo "⚠️ GitHub authorization skipped."
        else
            echo "✓ GitHub CLI is already authenticated."
        fi
    fi
    
    # Antigravity CLI login
    if command -v agy &> /dev/null; then
        echo "🪐 Starting Antigravity CLI login..."
        # Call agy without parameters or force login
        # (Most agy versions automatically trigger login flow on first use)
        agy --version &>/dev/null || echo "⚠️ Failed to check agy login status."
        
        echo "🛡️ Installing Caveman plugin in agy..."
        agy plugin install https://github.com/juliusbrussee/caveman || echo "⚠️ Failed to install Caveman plugin (log in and install manually: agy plugin install https://github.com/juliusbrussee/caveman)."
    fi
else
    echo "🖥️ Non-interactive environment. Skipping CLI authorization (run manually after installation)."
fi

echo "===================================================================="
echo "✅ DEPLOY SUCCESSFUL: AGENTS-OS v5.0 SYSTEM READY."
echo ""
echo "Next steps:"
echo "  1. Load shell config:      source ~/.bashrc.d/antigravity"
echo "  2. Create a project:       os-init project-name"
echo ""
echo "  The os-init command automatically:"
echo "    ✓ Creates folder structure (Golden Standard)"
echo "    ✓ Creates a GitHub repo (username/project-name)"
echo "    ✓ Makes initial commit and push"
echo "    ✓ Opens Antigravity IDE in the project folder"
echo "    ✓ Changes to the project folder in the terminal (cd)"
echo "===================================================================="

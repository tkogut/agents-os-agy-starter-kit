FROM python:3.11-slim

# Prevent python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV AGENTS_OS_ENV=devcontainer

# Install basic system tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    gnupg \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN mkdir -p /etc/apt/keyrings \
    && chmod 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Antigravity CLI (agy)
RUN echo "Downloading Antigravity CLI..." \
    && MANIFEST_PLATFORM="linux_amd64" \
    && FALLBACK_URL="https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.2-6109799369277440/linux-x64/cli_linux_x64.tar.gz" \
    && CLI_URL=$(curl -fsSL "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/${MANIFEST_PLATFORM}.json" | grep -o '"url": *"[^"]*"' | sed 's/"url": *//;s/"//g') \
    || CLI_URL="$FALLBACK_URL" \
    && if [ -z "$CLI_URL" ]; then CLI_URL="$FALLBACK_URL"; fi \
    && curl -fL -o /tmp/antigravity.tar.gz "$CLI_URL" \
    && tar -xzf /tmp/antigravity.tar.gz -C /tmp \
    && mv /tmp/antigravity /usr/local/bin/agy 2>/dev/null || mv /tmp/agy /usr/local/bin/agy \
    && chmod +x /usr/local/bin/agy \
    && rm -f /tmp/antigravity.tar.gz

# Install required Python dependencies globally (no venv needed in isolated container)
RUN pip install --no-cache-dir GitPython PyGithub

# Create workspace directory
WORKDIR /workspace

# Setup shell environment prompt and trust all git directories in container
RUN echo 'export PS1="🐳 \[\033[01;32m\]agents-os-container\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc \
    && echo 'alias ll="ls -la"' >> ~/.bashrc \
    && git config --global --add safe.directory '*' \
    && ln -sf /workspace/os-init /usr/local/bin/os-init \
    && ln -sf /workspace/os-add-skill /usr/local/bin/os-add-skill

CMD ["/bin/bash"]

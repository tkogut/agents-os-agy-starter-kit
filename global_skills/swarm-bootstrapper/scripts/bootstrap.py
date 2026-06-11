#!/usr/bin/env python3
"""
AGENTS-OS v5.0 SWARM - Project Bootstrapper
Order: folder → vault → .gitignore → git init → commit → gh repo create → push
Prints __PROJECT_DIR__:<path> as the last line (used by os-init to cd into the project).
Uses native GitPython and PyGithub libraries instead of raw subprocess calls.
"""
import os
import sys
import shutil

import git
import github
from github import Github, GithubException

VAULT_DIR = os.path.expanduser("~/.antigravity/templates/v5.0-swarm")
if not os.path.exists(VAULT_DIR):
    # Default fallback to local folder if global installation is missing
    local_vault = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "vault")
    if os.path.exists(local_vault):
        VAULT_DIR = local_vault

# --------------------------------------------------------------------------- #
# Argument handling
# --------------------------------------------------------------------------- #
if len(sys.argv) > 1:
    arg1 = sys.argv[1]
    if os.path.isabs(arg1):
        TARGET_DIR = os.path.abspath(arg1)
        project_name = os.path.basename(TARGET_DIR)
    elif "/" in arg1 or "\\" in arg1:
        # Contains path separator -> treat as a relative path
        TARGET_DIR = os.path.abspath(arg1)
        project_name = os.path.basename(TARGET_DIR)
    else:
        project_name = arg1
        # Allow override via env var (set by Docker entrypoint or compose environment)
        PROJECTS_ROOT = os.environ.get("PROJECTS_ROOT") or os.path.expanduser("~/projects")
        TARGET_DIR = os.path.join(PROJECTS_ROOT, project_name)
else:
    project_name = os.path.basename(os.getcwd())
    TARGET_DIR = os.getcwd()

# SAFETY GUARDRAIL
if os.path.abspath(TARGET_DIR) == os.path.expanduser("~"):
    print("❌ ERROR: Initialization in the home directory ($HOME) is FORBIDDEN.")
    sys.exit(1)

# --------------------------------------------------------------------------- #
# 1. Create project folder
# --------------------------------------------------------------------------- #
if not os.path.exists(TARGET_DIR):
    print(f"📦 Creating project: {TARGET_DIR}")
    os.makedirs(TARGET_DIR)

print(f"🚀 INITIALIZING AGENTS-OS v5.0 SWARM IN: {TARGET_DIR}")

# --------------------------------------------------------------------------- #
# 2. Copy Vault (Golden Standard)
# --------------------------------------------------------------------------- #
if os.path.exists(VAULT_DIR):
    print("🛡️  Identity transfer (Copying Golden Standard)...")
    for item in os.listdir(VAULT_DIR):
        src = os.path.join(VAULT_DIR, item)
        dst = os.path.join(TARGET_DIR, item)
        if os.path.isdir(src):
            if not os.path.exists(dst):
                shutil.copytree(src, dst)
        else:
            if not os.path.exists(dst):
                shutil.copy2(src, dst)
else:
    print(f"⚠️  Vault not found at {VAULT_DIR}. Creating minimal structure...")
    for d in [".agents/plans", ".agents/skills", "execution", "tmp"]:
        os.makedirs(os.path.join(TARGET_DIR, d), exist_ok=True)

# --------------------------------------------------------------------------- #
# 3. Create .gitignore if missing
# --------------------------------------------------------------------------- #
gitignore_path = os.path.join(TARGET_DIR, ".gitignore")
if not os.path.exists(gitignore_path):
    print("📝 Creating .gitignore...")
    with open(gitignore_path, "w") as f:
        f.write("# AGENTS-OS v5.0\ntmp/\n*.log\n__pycache__/\n.DS_Store\nnode_modules/\n.env\n")

# Create README.md if missing (required for the initial commit)
readme_path = os.path.join(TARGET_DIR, "README.md")
if not os.path.exists(readme_path):
    with open(readme_path, "w") as f:
        f.write(f"# {project_name}\n\nAGENTS-OS v5.0 Swarm Edition\n")

# --------------------------------------------------------------------------- #
# 4. Obtain GitHub token and determine user
# --------------------------------------------------------------------------- #
token = os.environ.get("GITHUB_TOKEN")
if not token:
    # Use native read from hosts.yml to avoid subprocess calls
    gh_hosts_path = os.path.expanduser("~/.config/gh/hosts.yml")
    if os.path.exists(gh_hosts_path):
        try:
            with open(gh_hosts_path, "r") as f:
                content = f.read()
                # Simple token extraction (assuming hosts.yml structure)
                if "oauth_token: " in content:
                    token = content.split("oauth_token: ")[1].split("\n")[0].strip()
        except Exception:
            pass

gh_user = None
if token:
    try:
        g = Github(auth=github.Auth.Token(token))
        gh_user = g.get_user().login
    except Exception as e:
        print(f"⚠️  PyGithub auth failed: {e}. Using git configuration.")

if not gh_user:
    try:
        config = git.GitConfigParser(os.path.expanduser("~/.gitconfig"), read_only=True)
        gh_user = config.get_value("github", "user", default="") or config.get_value("user", "name", default="").replace(" ", "")
    except Exception:
        pass

if not gh_user:
    gh_user = "your-github-username"

# --------------------------------------------------------------------------- #
# 5. Git init (natively via GitPython)
# --------------------------------------------------------------------------- #
git_path = os.path.join(TARGET_DIR, ".git")
try:
    if not os.path.exists(git_path):
        print("📦 Initializing local git repo...")
        repo = git.Repo.init(TARGET_DIR)
        with repo.config_writer() as writer:
            writer.set_value("init", "defaultBranch", "main")
    else:
        repo = git.Repo(TARGET_DIR)

    # Ensure branch is main
    try:
        repo.git.checkout("-b", "main")
    except Exception:
        try:
            repo.git.branch("-M", "main")
        except Exception:
            pass
except Exception as e:
    print(f"❌ Error during git init: {e}")
    sys.exit(1)

# Ensure git identity is configured before committing
try:
    with repo.config_reader() as reader:
        has_name = reader.has_option("user", "name")
        has_email = reader.has_option("user", "email")
    if not has_name or not has_email:
        print(f"   ⚙️  Git identity missing. Setting locally: {gh_user}")
        with repo.config_writer() as writer:
            writer.set_value("user", "name", gh_user)
            writer.set_value("user", "email", f"{gh_user}@users.noreply.github.com")
except Exception as e:
    print(f"⚠️  Failed to configure git identity: {e}")

# --------------------------------------------------------------------------- #
# 6. Initial commit (natively via GitPython)
# --------------------------------------------------------------------------- #
if repo.is_dirty(untracked_files=True):
    print("📝 Initial commit...")
    try:
        repo.git.add(A=True)
        repo.index.commit("init: agents-os v5.0 swarm bootstrap")
        print("   ✅ Commit done.")
    except Exception as e:
        print(f"❌ Commit failed: {e}")
        sys.exit(1)
else:
    print("   ℹ️  No changes to commit (repo already initialized).")

# --------------------------------------------------------------------------- #
# 7. GitHub repo — create if it does not exist (natively via PyGithub)
# --------------------------------------------------------------------------- #
print(f"🐙 Checking GitHub repo for user {gh_user}...")
repo_exists = False
if token:
    try:
        g = Github(auth=github.Auth.Token(token))
        g.get_repo(f"{gh_user}/{project_name}")
        repo_exists = True
        print(f"   ✅ Repo already exists: {gh_user}/{project_name}")
    except GithubException as e:
        if e.status == 404:
            repo_exists = False
        else:
            print(f"⚠️  GitHub API returned status {e.status}: {e.data}")
    except Exception as e:
        print(f"⚠️  GitHub API error: {e}")

if not repo_exists and token:
    try:
        print(f"🐙 Creating public repo: {gh_user}/{project_name}...")
        g = Github(auth=github.Auth.Token(token))
        user = g.get_user()
        gh_repo = user.create_repo(
            name=project_name,
            private=False,
            description=f"AGENTS-OS v5.0 — {project_name}"
        )
        print(f"   ✅ Repo created: {gh_repo.html_url}")
    except Exception as e:
        print(f"   ⚠️  Failed to create repository via API: {e}")

# Set origin remote
try:
    origin = repo.remote("origin")
    origin.set_url(f"https://github.com/{gh_user}/{project_name}.git")
except ValueError:
    origin = repo.create_remote("origin", f"https://github.com/{gh_user}/{project_name}.git")
    print(f"   🔗 Remote origin set: https://github.com/{gh_user}/{project_name}.git")
except Exception as e:
    print(f"⚠️  Failed to configure remote origin: {e}")

# --------------------------------------------------------------------------- #
# 8. Push (natively via GitPython)
# --------------------------------------------------------------------------- #
print("🚀 Pushing to GitHub...")
try:
    # Get current branch name
    current_branch = repo.active_branch.name
    origin.push(refspec=f"{current_branch}:{current_branch}", set_upstream=True)
    print(f"   ✅ Push complete ({current_branch} → origin).")
except Exception as e:
    print(f"   ⚠️  Push failed: {e}")
    print(f"      You can push manually: git push -u origin {repo.active_branch.name}")

print(f"\n✨ AGENTS-OS v5.0 Swarm — project READY.")
print(f"   GitHub: https://github.com/{gh_user}/{project_name}")

# IMPORTANT: last line = signal for os-init (shell function) to cd
print(f"__PROJECT_DIR__:{TARGET_DIR}")

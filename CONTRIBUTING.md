# Contributing to AGENTS-OS

Thank you for your interest in contributing to **AGENTS-OS**! This document explains how to get involved — whether you're fixing a bug, adding a new skill, or improving documentation.

---

## Table of Contents

1. [Ways to Contribute](#ways-to-contribute)
2. [Development Setup](#development-setup)
3. [Creating a Skill](#creating-a-skill)
4. [Submitting a Pull Request](#submitting-a-pull-request)
5. [Code Style & Conventions](#code-style--conventions)
6. [Reporting Bugs](#reporting-bugs)
7. [Security Vulnerabilities](#security-vulnerabilities)

---

## Ways to Contribute

| Type | How |
|---|---|
| 🐛 **Bug fix** | Open an issue, then a PR with the fix |
| 🚀 **New skill** | Follow the [Creating a Skill](#creating-a-skill) guide |
| 📖 **Documentation** | Edit `.md` files and submit a PR |
| 🌍 **Translation** | Add a new language section to `README.md` |
| 💡 **Feature idea** | Open a Feature Request issue first |
| 🔐 **Security issue** | See [Security Vulnerabilities](#security-vulnerabilities) — do NOT open a public issue |

---

## Development Setup

### Prerequisites

- **Linux / WSL2 / macOS** — see [README.md](./README.md#requirements)
- **Python 3.10+** — `python3 --version`
- **Node.js 18+ LTS** — `node --version`
- **GitHub CLI** — `gh --version`
- **Git** — `git --version`

### 1. Fork & clone

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/<your-username>/agents-os-agy-starter-kit.git
cd agents-os-agy-starter-kit
```

### 2. Run the installer

```bash
bash INSTALL.sh
source ~/.bashrc.d/antigravity
```

### 3. Install the pre-commit security hook

The hook is installed automatically by `INSTALL.sh`. To install manually:

```bash
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 4. Verify the setup

```bash
# Test os-init in dry-run mode
OS_INIT_TEST=true os-init test-project 2>&1 | head -20

# Test os-add-skill validation
python3 os-add-skill 2>&1
# Expected: "Usage: os-add-skill <skill-name>"
```

---

## Creating a Skill

Skills are modular AI agent capabilities installed via `os-add-skill`. Each skill lives in a self-contained directory.

### Skill directory structure

```
my-skill/
├── SKILL.md          ← Required: instructions + YAML frontmatter
├── scripts/          ← Optional: helper scripts (.py, .sh, .js)
├── examples/         ← Optional: usage examples
└── resources/        ← Optional: assets, templates, references
```

### `SKILL.md` format

```markdown
---
name: my-skill
description: One-line description of what this skill does.
version: 1.0.0
author: your-github-username
tags: [category, keyword]
---

# My Skill

## What it does
Brief explanation of the skill's purpose.

## Usage
How the AI agent should invoke this skill.

## Examples
Concrete examples of inputs and outputs.
```

### Skill naming conventions

| Rule | Example |
|---|---|
| Lowercase letters, digits, hyphens only | `postgresql-optimization` ✅ |
| No underscores, spaces, or uppercase | `My_Skill` ❌ |
| Max 64 characters | — |
| Descriptive, not generic | `react-component-generator` ✅, `helper` ❌ |

### Testing your skill locally

```bash
# Create a test project
os-init skill-test-project
cd ~/projects/skill-test-project

# Copy your skill directly (bypasses the registry for local testing)
mkdir -p .agents/skills/my-skill
cp -r /path/to/my-skill/. .agents/skills/my-skill/

# Verify structure
ls .agents/skills/my-skill/
```

### Submitting a skill to the registry

Skills are published in the separate [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) registry. Open a Pull Request there with your skill directory.

---

## Submitting a Pull Request

1. **Create a branch** from `main`:
   ```bash
   git checkout -b fix/descriptive-name
   # or
   git checkout -b feat/my-new-skill
   ```

2. **Make your changes** and ensure all tests pass.

3. **Commit** using the conventional commit format:
   ```
   type(scope): short description

   Types: feat | fix | docs | refactor | security | chore
   ```
   Examples:
   ```bash
   git commit -m "fix(os-init): handle missing WSL terminal gracefully"
   git commit -m "feat(install): add FreeBSD support"
   git commit -m "docs(readme): clarify macOS installation steps"
   git commit -m "security(hooks): add GitLab token pattern to pre-commit"
   ```

4. **Push** and open a Pull Request against `main`:
   ```bash
   git push origin fix/descriptive-name
   gh pr create --title "fix(os-init): ..." --body "Fixes #<issue-number>"
   ```

5. **PR checklist** — ensure your PR:
   - [ ] Has a clear title using conventional commits format
   - [ ] References the related issue (if any)
   - [ ] Includes a brief description of what changed and why
   - [ ] Does not introduce new hardcoded paths or usernames
   - [ ] Passes the pre-commit security scanner (no leaked tokens)
   - [ ] Updates relevant documentation if behavior changed

---

## Code Style & Conventions

### Shell scripts (`.sh`)

- Use `set -e` at the top
- Quote all variable expansions: `"$VAR"` not `$VAR`
- Use `[[ ]]` for conditionals where possible
- Echo messages use emojis consistently: `✅` success, `⚠️` warning, `❌` error, `📦` installing
- No hardcoded usernames, paths, or OS-specific values — use `$HOME`, `$(uname -s)`, etc.

### Python scripts (`.py`)

- Compatible with **Python 3.10+**
- Use f-strings for formatting
- Type hints on function signatures
- No `subprocess` calls where native libraries (`GitPython`, `PyGithub`) are available
- Use `sys.exit(1)` on unrecoverable errors

### Markdown (`.md`)

- Use ATX headings (`##`, not underline style)
- Tables for structured data
- Code blocks with language identifiers (` ```bash `, ` ```python `)
- English for all new content; Polish sections may be added as secondary

---

## Reporting Bugs

Use the [Bug Report](./.github/ISSUE_TEMPLATE/bug_report.md) issue template. Include:

- Your OS and shell version
- The exact command you ran
- Full error output (copy-paste, not screenshot)
- AGENTS-OS version: `git log --oneline -1`

---

## Security Vulnerabilities

**Do NOT open a public GitHub issue for security vulnerabilities.**

If you discover a security issue (token leak, path traversal bypass, remote code execution, etc.), please report it privately by emailing the maintainers or using GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) feature.

We aim to acknowledge all security reports within **48 hours** and release a fix within **7 days** for critical issues.

---

*Thank you for helping make AGENTS-OS better for everyone.* 🛸

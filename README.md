# AGENTS-OS v5.0 Swarm Edition — User Guide

> **Who is this for?**
> Everyone — even if you don't code every day.
> Step-by-step instructions explaining what to do and why.

---

## Table of Contents

1. [What is AGENTS-OS?](#what-is-agents-os)
2. [Requirements](#requirements)
3. [Installation — one-time setup](#installation)
4. [Creating a new project — `os-init`](#os-init)
5. [Project structure](#project-structure)
6. [Daily workflow](#daily-workflow)
7. [Common issues & fixes](#common-issues)
8. [How the system works internally](#how-it-works)
9. [Polska wersja / Polish version](#polska-wersja)

---

## What is AGENTS-OS?

**AGENTS-OS** is a toolkit and configuration framework that makes the Antigravity AI assistant work like an experienced developer — instead of lengthy explanations, it receives a concrete task and executes it.

| Component | What it is | Purpose |
|---|---|---|
| **INSTALL.sh** | Installation script | One-time setup on your machine |
| **os-init** | Startup command | Create a new project with one command |
| **Vault (Golden Standard)** | Folder template | Ready-made structure copied into every project |

---

## Requirements

| Tool | How to check | Where to get |
|---|---|---|
| **WSL2 + Ubuntu** (Windows) | `wsl --version` in PowerShell | [docs.microsoft.com](https://docs.microsoft.com/en-us/windows/wsl/install) |
| **Antigravity IDE** | Icon in Start Menu | Official installer |
| **Antigravity (chat window)** | Does the assistant app work | Same as above |
| **Python 3** | `python3 --version` in WSL | Pre-installed in Ubuntu |
| **Git** | `git --version` | `sudo apt install git` |
| **GitHub CLI** | `gh --version` | Auto-installed by INSTALL.sh |

> **How to open a WSL terminal?**
> On Windows press `Win + R`, type `wsl` and press Enter. A black Ubuntu terminal will open.

---

## Installation

> ⚠️ **Run this only once** — when setting up the system for the first time.

```bash
# 1. Open WSL terminal (Windows: Win+R → type "wsl" → Enter)

# 2. Clone the repository
mkdir -p ~/projects
git clone https://github.com/YOUR_ORG_OR_USERNAME/agents-os-agy-starter-kit.git ~/projects/agents-os-agy-starter-kit
cd ~/projects/agents-os-agy-starter-kit

# 3. Run the installer
bash INSTALL.sh

# 4. Log in to GitHub
gh auth login

# 5. Load shell configuration
source ~/.bashrc.d/antigravity
```

The installer automatically:
- Installs GitHub CLI (`gh`) via the official APT repository
- Creates an isolated Python virtual environment (`~/.antigravity/venv`) with dependencies (`GitPython`, `PyGithub`)
- Copies project templates to `~/.antigravity/templates/`
- Registers the `os-init` command system-wide
- Adds configuration to `~/.bashrc.d/antigravity`

---

## `os-init` — Creating a new project

> 💡 **One command does everything.**

```bash
os-init my-project-name
```

**What happens automatically:**

```
1. 📦  Creates folder: ~/projects/my-project-name
2. 🛡️  Copies Golden Standard (file/folder templates)
3. 📝  Creates .gitignore and README.md
4. 🔀  Initializes local Git repository
5. 📝  Makes first commit ("init: agents-os v5.0 swarm bootstrap")
6. 🐙  Creates public GitHub repo: github.com/<your-github-username>/my-project-name
7. 🚀  Pushes code to GitHub
8. 🖥️  Opens Antigravity IDE in WSL:Ubuntu environment
9. 🔀  Changes terminal directory to the new project (cd)
```

After completion your terminal automatically moves into the new folder:

```bash
📁 Now in: /home/<linux-user>/projects/my-project-name
```

---

## Project structure

Every project created by `os-init` has an identical, ready-to-use structure:

```
my-project-name/
│
├── README.md                ← Project description
├── .gitignore               ← Files ignored by Git
├── agents.yaml              ← AI assistant role config
├── design-tokens.md         ← Visual guidelines (colors, fonts, etc.)
├── task.md                  ← 📋 WRITE AI TASKS HERE
│
├── execution/               ← Runtime scripts
├── tmp/                     ← Temporary logs (Git-ignored)
│
├── .github/                 ← GitHub Actions automation
│   └── workflows/
│
└── .agents/                 ← AI assistant memory & config
    ├── plans/               ← Long-term project plans
    ├── skills/              ← AI skills (auto-downloaded)
    ├── specs/               ← Technical documentation & RAG knowledge
    └── workflows/           ← Automated instructions
```

### Most important file: `task.md`

This is where you tell the AI assistant what to do. Example:

```markdown
## Task
Create a landing page in HTML and CSS.
Use colors: blue (#2563EB), white (#FFFFFF).
Add a header, hero section, and footer.
```

---

## Daily workflow

**Option A — from WSL terminal:**
```bash
source ~/.bashrc.d/antigravity   # only if new terminal
cd ~/projects/my-project
antigravity .
```

**Option B — from Windows Start Menu:**
1. Launch **Antigravity IDE**
2. `File` → `Open Folder`
3. In the Explorer address bar type: `\\wsl.localhost\Ubuntu\home\<linux-user>\projects\`
4. Select your project folder

> ⚠️ **Note:** If Windows Explorer freezes when opening a WSL folder, run:
> ```powershell
> # In PowerShell (Windows):
> wsl --shutdown
> ```
> Then restart the WSL terminal.

**Push changes to GitHub:**

```bash
git add -A
git commit -m "describe: what you did"
git push
```

---

## Common issues

| Error | Cause | Fix |
|---|---|---|
| `Permission denied` on `~/.bashrc.d/antigravity` | Running instead of sourcing | Use `source ~/.bashrc.d/antigravity` |
| `os-init: command not found` | Shell config not loaded | Run `source ~/.bashrc.d/antigravity` |
| IDE opens without WSL:Ubuntu | Opening via .exe directly | Use `antigravity .` from WSL terminal |
| Explorer freezes at `\\wsl.localhost` | Known WSL2 network bug | Run `wsl --shutdown` in PowerShell, then restart WSL |
| `gh repo create failed: no commits` | Old script version | Run `git pull && bash INSTALL.sh` |
| `antigravity` opens chat instead of editor | App name conflict | Use `antigravity .` for IDE, `agy` for CLI chat |

---

## How it works

> This section is for the curious — you don't need to read it to use the system.

### Why is `os-init` a shell function, not a script?

In Linux, a script run as a separate process **cannot change the directory** (`cd`) in the parent terminal. This is a fundamental OS constraint.

That's why `os-init` is a **shell function** defined in `~/.bashrc.d/antigravity`:
1. It calls `os-init-run` (the actual script)
2. The script prints `__PROJECT_DIR__:/path/to/project` as its last line
3. The function captures that line and runs `cd` — **in the current terminal**

### Operation order in `bootstrap.py`

```
git init  →  vault copy  →  .gitignore  →  README.md  →  git commit  →  gh repo create  →  git push
```

> This order **must** be followed — `gh repo create` requires a commit to exist before it can push.

### The Swarm Triad — 3 AI roles

| Role | When active | What it does |
|---|---|---|
| **Coordinator** | Planning | Reads `task.md`, creates a plan, does NOT write code |
| **Builder** | Implementation | Writes code, edits files, runs commands |
| **Auditor** | Verification | Checks errors, logs, and code quality |

---

## MCP & GitOps Integration

**MCP (Model Context Protocol) integrated with GitOps** allows dynamic updating and distribution of the Antigravity IDE documentation directly via GitHub.

### How it works:

1. **MCP Server (`antigravity-docs`)**:
   Located in `.agents/mcp-servers/antigravity-docs/`. It runs on Node.js/stdio, providing the AI agent with documentation resources (`docs://index`) and search/read tools.

2. **Scraper & Extractor**:
   Python scripts (`scraper.py` and `extractor.py`) use Playwright to crawl the official Antigravity Docs site (`https://antigravity.google/docs/get-started`) and generate clean Markdown files under `knowledge_base/`.

3. **Cyclic GitHub Actions Pipeline (`mcp-docs-updater.yml`)**:
   Located in `.github/workflows/mcp-docs-updater.yml`. It runs automatically:
   * Monthly (cron) or via manual trigger (`workflow_dispatch`).
   * Installs Python 3.11, Playwright (Chromium), and runs the scraper and extractor.
   * Compares differences and automatically commits/pushes updates with `chore(mcp): auto-refresh Antigravity docs`.

4. **Local IDE Integration (`.gemini/mcp_config.json`)**:
   The editor dynamically registers the local MCP server when opening the workspace, giving the AI agent instant, zero-setup access to the latest documentation.

---

<br><hr><br>

<a name="polska-wersja"></a>
# [PL] AGENTS-OS v5.0 Swarm Edition — Instrukcja obsługi

> **Dla kogo jest ten dokument?**
> Dla każdego — nawet jeśli nie programujesz na co dzień.
> Wyjaśniamy krok po kroku co robić i dlaczego.

---

## Spis treści

1. [Czym jest AGENTS-OS?](#czym-jest-agents-os)
2. [Co potrzebujesz zanim zaczniesz](#wymagania)
3. [Instalacja — jednorazowa konfiguracja](#instalacja)
4. [Tworzenie nowego projektu — komenda `os-init`](#os-init-pl)
5. [Struktura nowego projektu](#struktura-projektu)
6. [Codzienna praca — jak otwierać projekty](#codzienna-praca)
7. [Najczęstsze problemy i rozwiązania](#najczestsze-problemy)
8. [Jak działa system od środka](#jak-dziala-od-srodka)

---

## Czym jest AGENTS-OS?

**AGENTS-OS** to zestaw narzędzi i konfiguracji, który sprawia że asystent AI (Antigravity) działa jak doświadczony programista — zamiast pisać długie elaboraty, dostaje konkretne zadanie i je wykonuje.

System składa się z trzech elementów:

| Element | Co to jest | Do czego służy |
|---|---|---|
| **INSTALL.sh** | Skrypt instalacyjny | Jednorazowe ustawienie wszystkiego na komputerze |
| **os-init** | Komenda startowa | Tworzenie nowego projektu jedną komendą |
| **Vault (Złoty Standard)** | Szablon folderów | Gotowa struktura, która kopiuje się do każdego projektu |

---

## Wymagania

Zanim zaczniesz, upewnij się że masz zainstalowane:

| Narzędzie | Jak sprawdzić | Gdzie pobrać |
|---|---|---|
| **WSL2 + Ubuntu** (Windows) | `wsl --version` w PowerShell | [docs.microsoft.com](https://docs.microsoft.com/pl-pl/windows/wsl/install) |
| **Antigravity IDE** | Czy masz ikonę w Menu Start | Zainstaluj przez oficjalny instalator |
| **Antigravity (okno czatu)** | Czy działa aplikacja asystenta | Jak wyżej |
| **Python 3** | `python3 --version` w terminalu WSL | Preinstalowany w Ubuntu |
| **Git** | `git --version` | `sudo apt install git` |
| **GitHub CLI** | `gh --version` | Instaluje się automatycznie przez INSTALL.sh |

> **Skąd wziąć terminal WSL?**
> W Windows naciśnij `Win + R`, wpisz `wsl` i Enter. Otworzy się czarny terminal Ubuntu.

---

## Instalacja

> ⚠️ **Wykonujesz to tylko raz** — przy pierwszym ustawieniu systemu na komputerze.

### Krok 1 — Otwórz terminal WSL (Ubuntu)

W Windows: `Win + R` → wpisz `wsl` → Enter

### Krok 2 — Pobierz repozytorium

```bash
mkdir -p ~/projects
git clone https://github.com/YOUR_ORG_OR_USERNAME/agents-os-agy-starter-kit.git ~/projects/agents-os-agy-starter-kit
cd ~/projects/agents-os-agy-starter-kit
```

### Krok 3 — Uruchom instalator

```bash
bash INSTALL.sh
```

Instalator automatycznie:
- Instaluje GitHub CLI (`gh`) przez repozytorium APT
- Tworzy izolowane środowisko wirtualne Python (`~/.antigravity/venv`) z zależnościami (`GitPython`, `PyGithub`)
- Kopiuje szablony projektów do `~/.antigravity/templates/`
- Rejestruje komendę `os-init` w systemie
- Dodaje konfigurację do `~/.bashrc.d/antigravity`

### Krok 4 — Zaloguj się do GitHub

```bash
gh auth login
```

Wybierz: `GitHub.com` → `HTTPS` → `Login with a web browser` → wklej kod na stronie GitHub.

### Krok 5 — Załaduj konfigurację shella

```bash
source ~/.bashrc.d/antigravity
```

> **Co to robi?**
> Ładuje skróty i funkcje (w tym `os-init`) do Twojego terminala.
> **Nowe terminale** ładują to automatycznie. Przy pierwszym razie musisz to zrobić ręcznie.

---

## `os-init` — Tworzenie nowego projektu

> 💡 **Jedna komenda robi wszystko.**

```bash
os-init nazwa-twojego-projektu
```

**Co się dzieje automatycznie:**

```
1. 📦  Tworzy folder: ~/projects/moja-aplikacja
2. 🛡️  Kopiuje do niego Złoty Standard (szablony plików i folderów)
3. 📝  Tworzy .gitignore i README.md
4. 🔀  Inicjalizuje lokalne repozytorium Git
5. 📝  Robi pierwszy commit ("init: agents-os v5.0 swarm bootstrap")
6. 🐙  Tworzy publiczne repozytorium na GitHubie: github.com/<twój-użytkownik-git>/moja-aplikacja
7. 🚀  Wysyła (push) kod na GitHub
8. 🖥️  Otwiera Antigravity IDE w środowisku WSL:Ubuntu w folderze projektu
9. 🔀  Przechodzi do folderu projektu w Twoim terminalu (cd)
```

Po zakończeniu Twój terminal automatycznie przejdzie do nowego folderu:

```bash
📁 Jesteś w: /home/<użytkownik-linux>/projects/moja-aplikacja
```

---

## Struktura projektu

Każdy projekt tworzony przez `os-init` ma identyczną, gotową strukturę:

```
moja-aplikacja/
│
├── README.md                ← Opis projektu (tu możesz pisać co to za projekt)
├── .gitignore               ← Lista plików ignorowanych przez Git
├── agents.yaml              ← Konfiguracja ról asystenta AI
├── design-tokens.md         ← Wytyczne wizualne (kolory, fonty, itp.)
├── task.md                  ← 📋 TU PISZESZ CO AI MA ZROBIĆ
│
├── execution/               ← Skrypty uruchomieniowe
├── tmp/                     ← Logi tymczasowe (ignorowane przez Git)
│
├── .github/                 ← Konfiguracja automatyzacji GitHub Actions
│   └── workflows/
│
└── .agents/                 ← Pamięć i konfiguracja asystenta AI
    ├── plans/               ← Długoterminowe plany projektu
    ├── skills/              ← Umiejętności asystenta (pobierane automatycznie)
    ├── specs/               ← Dokumentacja techniczna i wiedza RAG
    └── workflows/           ← Zautomatyzowane instrukcje
```

---

## Codzienna praca

**Opcja A — z terminala WSL:**
```bash
source ~/.bashrc.d/antigravity   # tylko jeśli nowy terminal
cd ~/projects/nazwa-projektu
antigravity .
```

**Opcja B — z Menu Start Windows:**
1. Uruchom **Antigravity IDE**
2. `File` → `Open Folder`
3. W pasku adresu Eksploratora wpisz: `\\wsl.localhost\Ubuntu\home\<użytkownik-linux>\projects\`
4. Wybierz folder projektu

> ⚠️ **Uwaga:** Jeśli Eksplorator Windows się zawiesza przy otwieraniu folderu WSL, wykonaj reset:
> ```powershell
> # W PowerShell (Windows):
> wsl --shutdown
> ```
> Następnie uruchom ponownie terminal WSL.

**Wysyłanie zmian na GitHub:**

```bash
git add -A
git commit -m "opis: co zrobiłem"
git push
```

Lub powiedz asystentowi: *„zapisz i wyślij na GitHub"* — zrobi to za Ciebie.

---

## Najczęstsze problemy

### ❌ `Permission denied` przy `~/.bashrc.d/antigravity`

**Problem:** Próbujesz uruchomić plik zamiast go załadować.

**Rozwiązanie:**
```bash
# ❌ ŹLE — uruchamia jako osobny proces
~/.bashrc.d/antigravity

# ✅ DOBRZE — ładuje do bieżącego terminala
source ~/.bashrc.d/antigravity
```

---

### ❌ `os-init: command not found`

**Problem:** Konfiguracja shella nie jest załadowana.

**Rozwiązanie:**
```bash
source ~/.bashrc.d/antigravity
```

Jeśli nadal nie działa, sprawdź instalację:
```bash
ls ~/.local/bin/os-init-run   # powinien istnieć
```

Jeśli pliku nie ma — uruchom ponownie `bash INSTALL.sh`.

---

### ❌ IDE otwiera się bez WSL:Ubuntu

**Problem:** IDE otwiera pliki w trybie Windows, nie WSL — brak dostępu do narzędzi Linux.

**Rozwiązanie:** Otwieraj IDE zawsze przez terminal WSL:
```bash
antigravity .
```

Lub używaj `os-init` — otwiera IDE automatycznie z flagą `--remote wsl+Ubuntu`.

---

### ❌ Eksplorator Windows zawiesza się przy `\\wsl.localhost`

**Problem:** Błąd integracji WSL2 z systemem plików Windows (znany bug WSL).

**Rozwiązanie:**
```powershell
# W PowerShell Windows:
wsl --shutdown
```
Następnie uruchom ponownie terminal WSL. Reset trwa ~5 sekund.

---

### ❌ `antigravity` otwiera okno czatu zamiast edytora kodu

**Rozwiązanie:** Używaj konkretnych komend:
```bash
antigravity .          # otwiera IDE (edytor kodu) w bieżącym folderze
agy                    # uruchamia CLI asystenta (czat w terminalu)
```

---

## Jak działa system od środka

> Ta sekcja jest dla ciekawskich — nie musisz tego czytać żeby używać systemu.

### Dlaczego `os-init` jest funkcją shella, a nie skryptem?

W systemie Linux, skrypt uruchomiony jako osobny proces **nie może zmienić katalogu** (`cd`) w terminalu rodzica. To fundamentalne ograniczenie systemu.

Dlatego `os-init` jest **funkcją shella** zdefiniowaną w `~/.bashrc.d/antigravity`:
1. Wywołuje `os-init-run` (właściwy skrypt)
2. Skrypt wypisuje na końcu `__PROJECT_DIR__:/ścieżka/do/projektu`
3. Funkcja przechwytuje tę linię i wykonuje `cd` — **w bieżącym terminalu**

### Kolejność operacji w `bootstrap.py`

```
git init  →  vault copy  →  .gitignore  →  README.md  →  git commit  →  gh repo create  →  git push
```

> Kolejność **musi** być taka — `gh repo create` wymaga żeby commit istniał zanim się go wywoła.

### The Swarm Triad — 3 role asystenta

| Rola | Kiedy aktywna | Co robi |
|---|---|---|
| **Coordinator** | Planowanie | Czyta `task.md`, tworzy plan, NIE pisze kodu |
| **Builder** | Implementacja | Pisze kod, edytuje pliki, uruchamia komendy |
| **Auditor** | Weryfikacja | Sprawdza błędy, logi, jakość kodu |

---

## Integracja MCP & GitOps

**MCP (Model Context Protocol) zintegrowany z GitOps** umożliwia dynamiczne aktualizowanie i dystrybucję bazy wiedzy o Antigravity IDE bezpośrednio z repozytorium GitHub.

### Jak to działa?

1. **Serwer MCP (`antigravity-docs`)**: Zlokalizowany w `.agents/mcp-servers/antigravity-docs/`. Dostarcza zasoby (`docs://index`) oraz narzędzia (`search_docs`, `read_doc`, `list_document_names`) dla asystenta AI.

2. **Scraper & Extractor**: Skrypty Pythonowe (`scraper.py` i `extractor.py`) używające Playwright pobierają dokumentację ze strony `https://antigravity.google/docs/get-started` do formatu Markdown w `knowledge_base/`.

3. **Pipeline GitHub Actions (`mcp-docs-updater.yml`)**: Automatycznie odpala się raz w miesiącu lub na żądanie, commituje i pushuje nową wiedzę jako `chore(mcp): auto-refresh Antigravity docs`.

4. **Lokalna konfiguracja IDE (`.gemini/mcp_config.json`)**: Środowisko automatycznie wczytuje serwer MCP podczas otwierania projektu.

---

*Document maintained by Antigravity Agent & Community. Last updated: June 2026.*

# Build Log: Job Hunt Agent

A day-by-day record of building an AI job hunt agent with n8n, OpenAI and SQL: what I did, what broke, and how I fixed it.

---

## Day 1: Wednesday, Nov 11, 2026

### Planning (1:47 – 1:53 PM)
- My instructor recommended building with tools from an AI automation skills list (n8n / Power Automate / Zapier, Python + OpenAI SDK / LangGraph, UiPath, JIRA).
- Compared options and picked an **AI Job Hunt Agent** instead of a basic Gmail auto-responder, so the project covers n8n, AI, a SQL database and JIRA in one build.
- **Plan:** n8n reads my Indeed/LinkedIn job alert emails → AI pulls out job details → AI scores each job (0–100) against my resume → jobs are saved to a SQL table (no duplicates) → I get a morning email with my top matches → I mark jobs as Applied or Skip.
- Set up a build tracker to log every task and minute.

### Install Docker Desktop (1:53 – 2:27 PM)
- Checked for Docker with `docker --version` → not installed.
- Installed it with one command using Windows' package manager: `winget install -e --id Docker.DockerDesktop` → **Successfully installed** (Docker Desktop 4.99.0).
- 🐛 **Problem:** Docker Desktop opened with *"WSL not installed."* Docker on Windows runs on WSL (Windows Subsystem for Linux).
- 🐛 **Problem 2:** `wsl --install` returned *"'wsl' is not recognized."* The cause: I had opened **Windows PowerShell (x86)**, the 32-bit version, which can't see the 64-bit `wsl` command.
- ✅ **Fix:** Ran `C:\Windows\Sysnative\wsl.exe --install` from the same Administrator window. `Sysnative` lets a 32-bit window reach the real 64-bit System32 folder. Ubuntu installed and I created a Linux user.
- ✅ Docker Desktop: **Engine running**.
- **Lesson:** Always open the 64-bit *Windows PowerShell*, not *(x86)*.

### Run n8n in Docker (2:27 – 2:39 PM)
- Started n8n as a container:

```
docker run -d --name n8n --restart unless-stopped -p 5678:5678 -e GENERIC_TIMEZONE=America/Chicago -e TZ=America/Chicago -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
```

  - `-d`: runs in the background
  - `--restart unless-stopped`: comes back automatically after a reboot
  - `-p 5678:5678`: n8n opens at http://localhost:5678
  - `-e ...Chicago`: scheduled runs use my local time zone
  - `-v n8n_data:...`: saves workflows to a Docker volume so nothing is lost on restart
- Created the n8n owner account (local only) and activated n8n's free community license (advanced debugging, execution search, folders).
- ✅ n8n is running at `localhost:5678`.

### Create GitHub repo + build log (2:39 – 2:55 PM)
- Created this repo: `job-hunt-agent-vtb`.
- Added this build log. 🤖 Agentic touch: I had my AI assistant (Claude) open GitHub in my browser and commit this file for me.

**Day 1 time so far:** about 1 hour 10 minutes

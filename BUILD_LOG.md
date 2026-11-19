# Build Log: Job Hunt Agent

A day-by-day record of building an AI job hunt agent with n8n, OpenAI and SQL: what I did, what broke, and how I fixed it.

## ⏱️ Time Tracking

Time tracked task-by-task in a live tracker. Times are estimated from session timestamps.

| Date | Time | Running total |
|---|---|---|
| Nov 11, 2026 | 1h 09m | 1h 09m |
| Nov 16, 2026 | 52m | 2h 01m |
| Nov 18, 2026 | 1h 03m | 3h 04m |
| Nov 19, 2026 | 49m | **3h 53m** |

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

---

## Day 2: Monday, Nov 16, 2026

### OpenAI API key (4:00 – 4:15 PM)
- Created a **separate API key just for this project** instead of reusing a key from another build. Why: if one key leaks I can revoke it without breaking other projects (least privilege), and OpenAI's usage page shows this project's cost on its own.
- Saved the key in **n8n's encrypted Credentials vault** (never in a workflow file or on GitHub). ✅ *Connection tested successfully.*

### Job alert setup: Dice + Monster (4:15 – 4:43 PM)
- Added **Dice** and **Monster** as sources alongside Indeed and LinkedIn. The agent reads alert *emails*, so any job board that emails alerts can plug in; the AI step handles each site's different email format (source-agnostic design).
- Updated my target roles to match my new positioning: **AI Automation Engineer | Agentic AI, Workflow Automation & Data Analytics**.
- **Dice:** daily alerts for AI Automation Engineer, Automation Engineer, Workflow Automation, Integration Analyst, Integration Engineer, GenAI Engineer, Data Analyst, AI Solutions Analyst and AI Implementation Analyst, each as a Remote alert + a local alert.
- 🐛 **Problem:** 3 of my "local" Dice alerts had silently kept the Remote filter from the previous search, so they would only send remote jobs (duplicates) and miss local hybrid/onsite jobs. ✅ **Fix:** deleted and re-created them with Remote off. **Lesson:** check the filter tags on every saved search.
- **Monster:** hit Monster's **10-alert limit**. Removed 4 old DBA alerts that no longer fit my focus, kept Database Analyst, and filled the rest with Remote-only alerts (Dice already covers local).
- 🤖 Claude created the Monster alerts for me in my browser.

### JIRA board (4:43 – 4:52 PM)
- Created a free JIRA Cloud site and a **Kanban** space: **Job Hunt Agent (key `JHA`)**.
- 🤖 Instead of clicking through the setup screens, Claude built the board with the **Jira REST API**: 6 epics (one per phase), 20 linked tasks, and 2 bugs for the Day 1 WSL issues (JHA-27, JHA-28), with statuses matching my build tracker.

**Day 2 time:** about 52 minutes · **Running total:** about 2 hours

---

## Day 3: Wednesday, Nov 18, 2026

### Database design (3:22 – 3:31 PM)
- Picked **PostgreSQL** (free, runs in Docker next to n8n, built-in n8n node, in-demand skill).
- Designed two tables:
  - **`jobs`**: one row per posting, with a `job_key` fingerprint (company | title | location) so the same job sent by two boards is stored once. Links differ per site, so the URL can't be the key.
  - **`target_roles`**: the titles the AI scores against, with a Primary/Safety lane and an on/off switch, so I can change targets with one line of SQL instead of editing the workflow. Seeded 11 titles.

### PostgreSQL in Docker + n8n connection (3:31 – 3:59 PM)
- Started PostgreSQL 17 as its own container (`jobhunt-db`, port 5432, persistent volume).
- 🐛 **Problem:** `docker run` failed with *"failed to connect to the docker API"*. Cause: Docker Desktop wasn't running after a reboot. ✅ **Fix:** started Docker Desktop, waited for *Engine running*, re-ran. (JHA-30)
- 🐛 **Problem:** locked out of n8n (owner password lost). ✅ **Fix:** `docker exec -u node -it n8n n8n user-management:reset` + `docker restart n8n`, then recreated the owner account. Saved credentials (OpenAI key) survived because they live in the Docker volume. (JHA-31)
- Created the n8n **Postgres** credential. Host is `host.docker.internal`, not `localhost`: inside the n8n container, *localhost* means the container itself.
- 🤖 Claude built and ran a **DB Setup** workflow in n8n that creates both tables, CHECK rules, indexes, and a **trigger** that auto-stamps `status_updated_at` when a job's status changes. Verified: `target_roles` = 11 rows, `jobs` = 0.
- Script saved to GitHub: [`sql/01_create_tables.sql`](sql/01_create_tables.sql).

### Schema changes after reviewing my manual tracker (3:59 – 4:10 PM)
- Compared the design to the job tracker I keep with ChatGPT. Decided to keep the two **separate** and compare them later in Power BI (manual vs. automated tracking).
- **Migration 02:** `source` limited to LinkedIn, Dice, Indeed, Monster.
- **Migration 03:** full status pipeline (New, Skip, Applied, Recruiter Contact, Interview, Offer, Rejected, No Response) and a **generated `fit_label` column** (Strong Fit 75+, Potential Fit 50–74, Not a Fit under 50) so the agent speaks the same language as my tracker. Fit stays separate from outcome, so a rejection doesn't erase that a job was a good match.

### Design decisions (4:10 – 4:25 PM)
- **One daily report email** (instead of dozens of alert emails): today's numbers, top matches with apply links, a safety-lane section, and my pipeline.
- **Alert emails go to Trash after processing**, but only *after* their jobs are saved, so a failed run never loses a job.
- **The agent never applies for me.** It sorts and scores; I review and apply (human in the loop).

**Day 3 time:** about 1 hour 3 minutes · **Running total:** about 3 hours 4 minutes
---

## Day 4: Thursday, Nov 19, 2026

### Job alert sources (3:40 – 4:02 PM)
- **LinkedIn:** alert already matched my target titles (AI Automation Engineer, Automation Engineer, AI Engineer, Data Analyst), daily by email. Kept "Top job picks" on; the AI score will filter weak picks.
- **Indeed:** I had job *preferences* but no saved-search *alerts*. Created 8 daily alerts (4 titles × Remote + local).
- Found that every job site sends alerts to the same Gmail inbox, so the agent only needs **one** Gmail connection.
- Decision: the first run will also process saved alerts from the **last 7 days** (real test data on day one).

### Gmail connection via Google Cloud OAuth 2.0 (4:02 – 4:29 PM)
- Self-hosted n8n needs its own Google app to read Gmail, so I set it up in **Google Cloud**:
  1. Created a project (`Job Hunt Agent`) and enabled the **Gmail API**
  2. Configured the **OAuth consent screen** (External, Testing mode, my inbox as the only test user, so no Google app review is needed)
  3. Created an **OAuth Web client** with n8n's redirect URI (`http://localhost:5678/rest/oauth2-credential/callback`)
  4. Added a **Gmail OAuth2** credential in n8n and signed in: *Account connected* ✅
- Skipped the Google Cloud \$300 free trial (not needed; the Gmail API is free).
- All three connections are now in place: **Gmail** (email in), **OpenAI** (AI brain), **PostgreSQL** (memory).

**Day 4 time:** about 49 minutes · **Running total:** about 3 hours 53 minutes

-- =============================================================
-- Job Hunt Agent: database setup (PostgreSQL 17)
-- Author: Tabitha Bebee
-- Creates the target_roles and jobs tables, rules, indexes,
-- a status-change trigger, and seeds my target job titles.
-- Safe to re-run (IF NOT EXISTS / ON CONFLICT DO NOTHING).
-- =============================================================

-- Titles the AI scores each job against. Add, pause or re-lane
-- titles here without touching the n8n workflow.
CREATE TABLE IF NOT EXISTS target_roles (
  role_id     SERIAL PRIMARY KEY,
  title       VARCHAR(100) NOT NULL UNIQUE,
  lane        VARCHAR(10)  NOT NULL DEFAULT 'Primary' CHECK (lane IN ('Primary','Safety')),
  active      BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- One row per job posting found in a job alert email.
-- job_key = normalized company|title|location fingerprint, so the
-- same job sent by two job boards is only stored once.
CREATE TABLE IF NOT EXISTS jobs (
  job_id             SERIAL PRIMARY KEY,
  job_key            TEXT         NOT NULL UNIQUE,
  source             VARCHAR(20)  NOT NULL CHECK (source IN ('Indeed','LinkedIn','Dice','Monster','Jobright','Other')),
  title              TEXT         NOT NULL,
  company            TEXT,
  location           TEXT,
  work_type          VARCHAR(10)  NOT NULL DEFAULT 'Unknown' CHECK (work_type IN ('Remote','Hybrid','Onsite','Unknown')),
  salary_text        TEXT,
  job_url            TEXT,
  match_score        SMALLINT     CHECK (match_score BETWEEN 0 AND 100),
  match_reason       TEXT,
  status             VARCHAR(10)  NOT NULL DEFAULT 'New' CHECK (status IN ('New','Applied','Skip')),
  email_received_at  TIMESTAMPTZ,
  found_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  status_updated_at  TIMESTAMPTZ
);

-- Fast "top new matches" queries
CREATE INDEX IF NOT EXISTS idx_jobs_match_score ON jobs (match_score DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_status      ON jobs (status);

-- Automatically stamp status_updated_at when I mark a job Applied/Skip
CREATE OR REPLACE FUNCTION set_status_updated_at() RETURNS trigger AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.status_updated_at := now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_jobs_status_updated ON jobs;
CREATE TRIGGER trg_jobs_status_updated
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION set_status_updated_at();

-- Starter target roles
INSERT INTO target_roles (title, lane) VALUES
  ('AI Automation Engineer','Primary'),
  ('AI Engineer','Primary'),
  ('Automation Engineer','Primary'),
  ('Workflow Automation','Primary'),
  ('Integration Analyst','Primary'),
  ('Integration Engineer','Primary'),
  ('GenAI Engineer','Primary'),
  ('AI Solutions Analyst','Primary'),
  ('AI Implementation Analyst','Primary'),
  ('Database Analyst','Primary'),
  ('Data Analyst','Safety')
ON CONFLICT (title) DO NOTHING;

-- Quick check
-- SELECT 'target_roles' AS table_name, COUNT(*) FROM target_roles
-- UNION ALL SELECT 'jobs', COUNT(*) FROM jobs;

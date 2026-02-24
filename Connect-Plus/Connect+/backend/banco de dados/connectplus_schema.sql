
-- Connect+ (MVP) - PostgreSQL DDL
-- Focus: Islands = Onboarding + Benefits/HR
-- Naming: snake_case, avoid reserved words (use app_user instead of user)
-- IDs: UUID (requires pgcrypto)

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==============
-- Lookup tables
-- ==============
CREATE TABLE IF NOT EXISTS island_type (
  island_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,          -- e.g. 'onboarding', 'benefits_hr'
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS mission_status (
  mission_status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,          -- e.g. 'not_started','in_progress','completed'
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS task_type (
  task_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,          -- e.g. 'video','quiz','link','form','reading'
  name TEXT NOT NULL
);

-- =========
-- Core
-- =========
CREATE TABLE IF NOT EXISTS app_user (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  document_id TEXT,                   -- CPF/RG/etc (optional)
  phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- profile / gamification stats (what your diagram calls "Pontuation")
CREATE TABLE IF NOT EXISTS user_stats (
  user_id UUID PRIMARY KEY REFERENCES app_user(user_id) ON DELETE CASCADE,
  xp_total BIGINT NOT NULL DEFAULT 0,
  level INT NOT NULL DEFAULT 1,
  last_level_up_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_level_positive CHECK (level >= 1),
  CONSTRAINT chk_xp_nonnegative CHECK (xp_total >= 0)
);

-- Island instance (one per type for MVP, but supports more later)
CREATE TABLE IF NOT EXISTS island (
  island_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  island_type_id UUID NOT NULL REFERENCES island_type(island_type_id),
  name TEXT NOT NULL,                 -- display name
  size_label TEXT,                    -- optional: e.g. 'small','medium' or map size
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (island_type_id)
);

-- Optional: areas/sections inside an island (your "AREA")
CREATE TABLE IF NOT EXISTS island_area (
  area_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  island_id UUID NOT NULL REFERENCES island(island_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 1,
  UNIQUE (island_id, name)
);

-- Missions live inside an island (and optionally inside an area)
CREATE TABLE IF NOT EXISTS mission (
  mission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  island_id UUID NOT NULL REFERENCES island(island_id) ON DELETE CASCADE,
  area_id UUID REFERENCES island_area(area_id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  category TEXT,                      -- keep as TEXT for MVP; can be lookup later
  description TEXT,
  sort_order INT NOT NULL DEFAULT 1,
  xp_reward INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_mission_xp_nonnegative CHECK (xp_reward >= 0)
);

-- Tasks: content units inside a mission (your "TAREFA")
CREATE TABLE IF NOT EXISTS mission_task (
  task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mission_id UUID NOT NULL REFERENCES mission(mission_id) ON DELETE CASCADE,
  task_type_id UUID REFERENCES task_type(task_type_id),
  title TEXT NOT NULL,
  content_url TEXT,                   -- URL to content (video, doc, etc.)
  instructions TEXT,
  sort_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (mission_id, sort_order)
);

-- Rewards / items (your OBJETORECOMPENSA)
CREATE TABLE IF NOT EXISTS reward_item (
  item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  asset_url TEXT,                     -- image/icon
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (name)
);

-- Optional: a mission may grant one or more items
CREATE TABLE IF NOT EXISTS mission_reward_item (
  mission_id UUID NOT NULL REFERENCES mission(mission_id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES reward_item(item_id) ON DELETE RESTRICT,
  quantity INT NOT NULL DEFAULT 1,
  PRIMARY KEY (mission_id, item_id),
  CONSTRAINT chk_reward_qty_positive CHECK (quantity >= 1)
);

-- User progress on missions (your Progress_Mission)
CREATE TABLE IF NOT EXISTS user_mission_progress (
  user_id UUID NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES mission(mission_id) ON DELETE CASCADE,
  mission_status_id UUID NOT NULL REFERENCES mission_status(mission_status_id),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, mission_id)
);

-- User progress on tasks (granular)
CREATE TABLE IF NOT EXISTS user_task_progress (
  user_id UUID NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES mission_task(task_id) ON DELETE CASCADE,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, task_id)
);

-- Inventory (your Inventory) - DO NOT repeat user columns here
CREATE TABLE IF NOT EXISTS user_inventory (
  user_id UUID NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES reward_item(item_id) ON DELETE RESTRICT,
  quantity INT NOT NULL DEFAULT 1,
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, item_id),
  CONSTRAINT chk_inventory_qty_positive CHECK (quantity >= 1)
);

-- Optional: object placement on map (your POSICAOOBJETO)
CREATE TABLE IF NOT EXISTS island_item_placement (
  placement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  island_id UUID NOT NULL REFERENCES island(island_id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES reward_item(item_id) ON DELETE RESTRICT,
  coord_x INT NOT NULL,
  coord_y INT NOT NULL,
  rotation INT NOT NULL DEFAULT 0,
  placed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, island_id, item_id),
  CONSTRAINT chk_coords_nonnegative CHECK (coord_x >= 0 AND coord_y >= 0)
);

-- ==========
-- Indexes
-- ==========
CREATE INDEX IF NOT EXISTS idx_mission_island ON mission(island_id);
CREATE INDEX IF NOT EXISTS idx_task_mission ON mission_task(mission_id);
CREATE INDEX IF NOT EXISTS idx_user_mission_status ON user_mission_progress(mission_status_id);

-- ==========
-- Seed data for MVP islands
-- ==========
INSERT INTO island_type (code, name, description)
VALUES
 ('onboarding','Onboarding','Trilha de entrada, cultura, setup e primeiras missões'),
 ('benefits_hr','Benefícios / RH','Benefícios, políticas, processos e people ops')
ON CONFLICT (code) DO NOTHING;

INSERT INTO mission_status (code, name)
VALUES
 ('not_started','Not started'),
 ('in_progress','In progress'),
 ('completed','Completed')
ON CONFLICT (code) DO NOTHING;

INSERT INTO task_type (code, name)
VALUES
 ('video','Video'),
 ('quiz','Quiz'),
 ('link','Link'),
 ('reading','Reading'),
 ('form','Form')
ON CONFLICT (code) DO NOTHING;

-- Create one island per type for MVP
INSERT INTO island (island_type_id, name, size_label)
SELECT island_type_id, name, 'mvp'
FROM island_type
ON CONFLICT (island_type_id) DO NOTHING;

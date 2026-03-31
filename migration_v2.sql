-- ============================================
-- MARUOKO V2 MIGRATION
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Menu Categories
CREATE TABLE IF NOT EXISTS menu_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  position INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Restaurant Config (single row)
CREATE TABLE IF NOT EXISTS restaurant_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  restaurant_name TEXT NOT NULL DEFAULT 'MARUOKO',
  restaurant_phone TEXT,
  opening_message TEXT DEFAULT 'O que vais querer?',
  closed_title TEXT DEFAULT 'Estamos fechados!',
  closed_message TEXT DEFAULT 'O sistema de reservas esta fechado de momento.',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Schedule Config (one row per day of week)
CREATE TABLE IF NOT EXISTS schedule_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  day_name TEXT NOT NULL,
  mode TEXT NOT NULL DEFAULT 'closed' CHECK (mode IN ('closed', 'walk_in', 'online')),
  is_active BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(day_of_week)
);

-- 4. Add columns to menu_items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES menu_categories(id) ON DELETE SET NULL;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ============================================
-- RLS for new tables
-- ============================================
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read categories" ON menu_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public read config" ON restaurant_config FOR SELECT USING (true);
CREATE POLICY "Public read schedule" ON schedule_config FOR SELECT USING (true);

-- ============================================
-- SEED DATA
-- ============================================

-- Categories
INSERT INTO menu_categories (name, position) VALUES
  ('Okonomiyaki', 1),
  ('Toppings', 2),
  ('Dessert', 3),
  ('Drinks', 4);

-- Restaurant config
INSERT INTO restaurant_config (restaurant_name, restaurant_phone, opening_message, closed_title, closed_message)
VALUES ('MARUOKO', '', 'O que vais querer?', 'Reservas apenas ao Sabado!', 'O sistema de reservas esta aberto apenas aos sabados.');

-- Schedule (7 days)
INSERT INTO schedule_config (day_of_week, day_name, mode, is_active) VALUES
  (0, 'Domingo', 'closed', false),
  (1, 'Segunda', 'walk_in', false),
  (2, 'Terca', 'closed', false),
  (3, 'Quarta', 'walk_in', false),
  (4, 'Quinta', 'walk_in', false),
  (5, 'Sexta', 'walk_in', false),
  (6, 'Sabado', 'online', true);

-- ============================================
-- Assign existing menu items to categories
-- (run after categories are seeded)
-- ============================================
UPDATE menu_items SET category_id = (SELECT id FROM menu_categories WHERE name = 'Okonomiyaki' LIMIT 1) WHERE LOWER(name) LIKE '%okonomiyaki%';
UPDATE menu_items SET category_id = (SELECT id FROM menu_categories WHERE name = 'Toppings' LIMIT 1) WHERE LOWER(name) LIKE '%topping%';
UPDATE menu_items SET category_id = (SELECT id FROM menu_categories WHERE name = 'Dessert' LIMIT 1) WHERE LOWER(name) LIKE '%mochi%';
UPDATE menu_items SET category_id = (SELECT id FROM menu_categories WHERE name = 'Drinks' LIMIT 1) WHERE category_id IS NULL AND LOWER(name) LIKE '%drink%' OR LOWER(name) LIKE '%boisson%';

-- ============================================
-- FOOD TRUCK PRE-ORDER SYSTEM
-- Supabase Schema Migration
-- ============================================

-- Menu items
CREATE TABLE menu_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL DEFAULT 0,
  available BOOLEAN NOT NULL DEFAULT true,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Orders
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number SERIAL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  slot_time TEXT NOT NULL,           -- e.g. "12:30"
  slot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','picked_up','no_show','cancelled')),
  notes TEXT,
  total_amount REAL NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Order line items
CREATE TABLE order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id),
  item_name TEXT NOT NULL,          -- snapshot du nom au moment de la commande
  item_price REAL NOT NULL,         -- snapshot du prix
  quantity INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Config: time slots template + capacity
CREATE TABLE slot_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slot_time TEXT NOT NULL,           -- e.g. "12:00"
  max_orders INT NOT NULL DEFAULT 5,
  is_active BOOLEAN NOT NULL DEFAULT true,
  day_of_week INT,                   -- 0=Sun, 6=Sat. NULL = every day
  position INT NOT NULL DEFAULT 0
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_orders_slot ON orders(slot_date, slot_time);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- ============================================
-- RLS (public read for menu, anon insert for orders)
-- ============================================
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE slot_config ENABLE ROW LEVEL SECURITY;

-- Public: anyone can read active menu items
CREATE POLICY "Public read menu" ON menu_items
  FOR SELECT USING (available = true);

-- Public: anyone can read slot config
CREATE POLICY "Public read slots" ON slot_config
  FOR SELECT USING (is_active = true);

-- Public: anyone can create an order (anon)
CREATE POLICY "Anon insert orders" ON orders
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anon insert order_items" ON order_items
  FOR INSERT WITH CHECK (true);

-- Public: read own order by id (for confirmation page)
CREATE POLICY "Public read own order" ON orders
  FOR SELECT USING (true);

CREATE POLICY "Public read order_items" ON order_items
  FOR SELECT USING (true);

-- Admin: full access via service_role key (used in admin.html)
-- Note: admin page should use service_role or authenticated user

-- ============================================
-- FUNCTION: count orders per slot (for availability)
-- ============================================
CREATE OR REPLACE FUNCTION get_slot_availability(target_date DATE)
RETURNS TABLE(slot_time TEXT, max_orders INT, current_orders BIGINT) AS $$
  SELECT 
    sc.slot_time,
    sc.max_orders,
    COALESCE(COUNT(o.id), 0) AS current_orders
  FROM slot_config sc
  LEFT JOIN orders o 
    ON o.slot_time = sc.slot_time 
    AND o.slot_date = target_date
    AND o.status NOT IN ('cancelled', 'no_show')
  WHERE sc.is_active = true
  GROUP BY sc.slot_time, sc.max_orders, sc.position
  ORDER BY sc.position, sc.slot_time;
$$ LANGUAGE sql;

-- ============================================
-- SEED DATA: exemple menu + slots samedi
-- ============================================
INSERT INTO menu_items (name, description, price, position) VALUES
  ('Menu Classique', 'Le best-seller du truck', 8.50, 1),
  ('Menu Spécial', 'La spécialité du chef', 10.00, 2),
  ('Accompagnement', 'Side dish', 3.50, 3),
  ('Boisson', 'Soft drink', 2.00, 4);

-- Slots samedi: 12h00 - 15h00, toutes les 15 min, max 5 commandes par créneau
INSERT INTO slot_config (slot_time, max_orders, day_of_week, position) VALUES
  ('12:00', 5, 6, 1),
  ('12:15', 5, 6, 2),
  ('12:30', 5, 6, 3),
  ('12:45', 5, 6, 4),
  ('13:00', 5, 6, 5),
  ('13:15', 5, 6, 6),
  ('13:30', 5, 6, 7),
  ('13:45', 5, 6, 8),
  ('14:00', 5, 6, 9),
  ('14:15', 5, 6, 10),
  ('14:30', 5, 6, 11),
  ('14:45', 5, 6, 12);

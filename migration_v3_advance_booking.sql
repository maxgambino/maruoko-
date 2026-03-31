-- Migration V3: Update get_slot_availability to filter by day_of_week
-- This enables advance booking by loading slots for any target date

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
    AND (sc.day_of_week IS NULL OR sc.day_of_week = EXTRACT(DOW FROM target_date)::INT)
  GROUP BY sc.slot_time, sc.max_orders, sc.position
  ORDER BY sc.position, sc.slot_time;
$$ LANGUAGE sql;

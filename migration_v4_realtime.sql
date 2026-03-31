-- Migration V4: Enable Realtime on orders and order_items tables
-- Run this in Supabase SQL Editor to enable instant WebSocket updates

-- Enable realtime for orders table
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Enable realtime for order_items table
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;

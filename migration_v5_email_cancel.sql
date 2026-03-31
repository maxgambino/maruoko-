-- Migration V5: Add email + cancel token to orders
-- Run this in Supabase SQL Editor

-- Add columns
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancel_token TEXT;

-- Create index on cancel_token for fast lookups
CREATE INDEX IF NOT EXISTS idx_orders_cancel_token ON orders(cancel_token) WHERE cancel_token IS NOT NULL;

-- Allow anon users to update order status via cancel token (RLS policy)
CREATE POLICY "Allow cancel via token" ON orders
  FOR UPDATE
  USING (cancel_token IS NOT NULL)
  WITH CHECK (status = 'cancelled');

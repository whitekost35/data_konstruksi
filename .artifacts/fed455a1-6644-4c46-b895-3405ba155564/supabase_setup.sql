-- 1. Create Tables for Koko's Billing
-- Table for Billing Periods
CREATE TABLE IF NOT EXISTS koko_billing_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for White Kost 35
CREATE TABLE IF NOT EXISTS koko_white_kost_35 (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_id UUID REFERENCES koko_billing_periods(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC DEFAULT 0 NOT NULL,
    receipt_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Table for Mykost 179
CREATE TABLE IF NOT EXISTS koko_mykost_179 (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    period_id UUID REFERENCES koko_billing_periods(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC DEFAULT 0 NOT NULL,
    receipt_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Storage Buckets (Execute via Supabase Dashboard or API if available)
-- Note: Supabase SQL doesn't directly support creating buckets,
-- Please create these manually in the Supabase Storage Dashboard:
-- Bucket Name: koko-white-kost-receipts (Public)
-- Bucket Name: koko-mykost-receipts (Public)

-- 3. Enable RLS (Optional but recommended)
ALTER TABLE koko_billing_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE koko_white_kost_35 ENABLE ROW LEVEL SECURITY;
ALTER TABLE koko_mykost_179 ENABLE ROW LEVEL SECURITY;

-- Allow all access for now (Development)
CREATE POLICY "Allow public access" ON koko_billing_periods FOR ALL USING (true);
CREATE POLICY "Allow public access" ON koko_white_kost_35 FOR ALL USING (true);
CREATE POLICY "Allow public access" ON koko_mykost_179 FOR ALL USING (true);

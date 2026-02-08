-- Mastermind Billing Portal - Supabase Database Schema
-- Run this in your Supabase SQL Editor to set up the database
--
-- NOTE: This schema uses TEXT primary keys to match the app's ID generation
-- (e.g., 'id_abc123xyz', 'chase_2024-01-15_VENDOR_100')
--
-- IMPORTANT: This app uses Supabase Auth for authentication, NOT the
-- billing_users table. Create users via Authentication > Users in the
-- Supabase dashboard.

-- ============================================
-- MEMBERS TABLE (from Kajabi)
-- ============================================
CREATE TABLE IF NOT EXISTS members (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    kajabi_id TEXT,
    subscription_plan TEXT,
    subscription_amount DECIMAL(10,2) DEFAULT 0,
    billing_frequency TEXT CHECK (billing_frequency IN ('monthly', 'annual', 'one-time', 'lifetime')) DEFAULT 'monthly',
    subscription_status TEXT CHECK (subscription_status IN ('active', 'canceled', 'past_due', 'trialing', 'paused')) DEFAULT 'active',
    join_date DATE,
    first_payment_date DATE,
    last_payment_date DATE,
    next_payment_date DATE,
    total_paid DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_members_email ON members(email);
CREATE INDEX IF NOT EXISTS idx_members_status ON members(subscription_status);

-- ============================================
-- STRIPE TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS stripe_transactions (
    id TEXT PRIMARY KEY,
    stripe_id TEXT UNIQUE,
    stripe_account TEXT CHECK (stripe_account IN ('reignation', 'coaching')) NOT NULL,
    member_id TEXT REFERENCES members(id) ON DELETE SET NULL,
    member_email TEXT,
    customer_name TEXT,
    amount DECIMAL(10,2) NOT NULL,
    fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2),
    currency TEXT DEFAULT 'usd',
    status TEXT CHECK (status IN ('succeeded', 'failed', 'pending', 'refunded', 'disputed', 'canceled')) DEFAULT 'succeeded',
    failure_reason TEXT,
    transaction_date TIMESTAMPTZ NOT NULL,
    description TEXT,
    product_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Stripe transactions
CREATE INDEX IF NOT EXISTS idx_stripe_member_email ON stripe_transactions(member_email);
CREATE INDEX IF NOT EXISTS idx_stripe_date ON stripe_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_stripe_account ON stripe_transactions(stripe_account);
CREATE INDEX IF NOT EXISTS idx_stripe_status ON stripe_transactions(status);
CREATE INDEX IF NOT EXISTS idx_stripe_stripe_id ON stripe_transactions(stripe_id);

-- ============================================
-- EXPENSE CATEGORIES TABLE
-- (Created before bank_transactions due to foreign key)
-- ============================================
CREATE TABLE IF NOT EXISTS expense_categories (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    type TEXT CHECK (type IN ('income', 'expense')) NOT NULL,
    parent_category TEXT,
    color TEXT DEFAULT '#6c757d',
    icon TEXT,
    is_tax_deductible BOOLEAN DEFAULT FALSE,
    tax_category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BANK STATEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bank_statements (
    id TEXT PRIMARY KEY,
    account_name TEXT NOT NULL,
    account_type TEXT CHECK (account_type IN ('checking', 'savings', 'credit_card')) DEFAULT 'checking',
    statement_month DATE NOT NULL,
    start_balance DECIMAL(12,2),
    end_balance DECIMAL(12,2),
    total_deposits DECIMAL(12,2) DEFAULT 0,
    total_withdrawals DECIMAL(12,2) DEFAULT 0,
    file_path TEXT,
    file_name TEXT,
    import_method TEXT CHECK (import_method IN ('csv', 'pdf', 'manual')) DEFAULT 'csv',
    imported_by TEXT,
    imported_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_statements_month ON bank_statements(statement_month);
CREATE INDEX IF NOT EXISTS idx_statements_account ON bank_statements(account_name);

-- ============================================
-- BANK/CC TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bank_transactions (
    id TEXT PRIMARY KEY,
    statement_id TEXT REFERENCES bank_statements(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL,
    post_date DATE,
    description TEXT NOT NULL,
    original_description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    transaction_type TEXT CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')) DEFAULT 'withdrawal',
    category_id TEXT REFERENCES expense_categories(id) ON DELETE SET NULL,
    is_reconciled BOOLEAN DEFAULT FALSE,
    reconciled_with_stripe TEXT,
    is_tax_deductible BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_txn_date ON bank_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_bank_txn_category ON bank_transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_bank_txn_type ON bank_transactions(transaction_type);

-- ============================================
-- BILLING DISCREPANCIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS billing_discrepancies (
    id TEXT PRIMARY KEY,
    member_id TEXT REFERENCES members(id) ON DELETE CASCADE,
    member_email TEXT,
    member_name TEXT,
    discrepancy_type TEXT CHECK (discrepancy_type IN (
        'missing_kajabi_record',
        'missing_stripe_payment',
        'amount_mismatch',
        'failed_payment',
        'duplicate_charge',
        'refund_not_recorded',
        'member_not_in_stripe'
    )) NOT NULL,
    expected_amount DECIMAL(10,2),
    actual_amount DECIMAL(10,2),
    difference DECIMAL(10,2),
    period_start DATE,
    period_end DATE,
    stripe_account TEXT,
    related_stripe_id TEXT,
    status TEXT CHECK (status IN ('open', 'investigating', 'resolved', 'ignored')) DEFAULT 'open',
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
    resolution_notes TEXT,
    resolved_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_discrepancies_status ON billing_discrepancies(status);
CREATE INDEX IF NOT EXISTS idx_discrepancies_type ON billing_discrepancies(discrepancy_type);
CREATE INDEX IF NOT EXISTS idx_discrepancies_member ON billing_discrepancies(member_email);

-- ============================================
-- IMPORT LOGS TABLE (audit trail)
-- ============================================
CREATE TABLE IF NOT EXISTS import_logs (
    id TEXT PRIMARY KEY,
    import_type TEXT NOT NULL,
    file_name TEXT,
    records_total INTEGER DEFAULT 0,
    records_imported INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    errors JSONB,
    warnings JSONB,
    imported_by TEXT,
    imported_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_import_logs_type ON import_logs(import_type);
CREATE INDEX IF NOT EXISTS idx_import_logs_date ON import_logs(imported_at);

-- ============================================
-- APP SETTINGS TABLE (configuration)
-- ============================================
CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by TEXT
);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to members table
DROP TRIGGER IF EXISTS update_members_updated_at ON members;
CREATE TRIGGER update_members_updated_at
    BEFORE UPDATE ON members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- Monthly revenue summary view
CREATE OR REPLACE VIEW monthly_revenue_summary AS
SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    stripe_account,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN status = 'succeeded' THEN amount ELSE 0 END) AS gross_revenue,
    SUM(CASE WHEN status = 'succeeded' THEN fee ELSE 0 END) AS total_fees,
    SUM(CASE WHEN status = 'succeeded' THEN net_amount ELSE 0 END) AS net_revenue,
    SUM(CASE WHEN status = 'refunded' THEN amount ELSE 0 END) AS refunds,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_count
FROM stripe_transactions
GROUP BY DATE_TRUNC('month', transaction_date), stripe_account
ORDER BY month DESC, stripe_account;

-- Member status summary view
CREATE OR REPLACE VIEW member_status_summary AS
SELECT
    subscription_status,
    COUNT(*) AS member_count,
    SUM(subscription_amount) AS total_mrr,
    AVG(subscription_amount) AS avg_subscription
FROM members
GROUP BY subscription_status;

-- ============================================
-- ROW LEVEL SECURITY
-- Enable RLS and create policies for authenticated users
-- ============================================

ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_discrepancies ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Policies: Authenticated users can access all data
CREATE POLICY "Authenticated users can read members" ON members
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert members" ON members
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update members" ON members
    FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete members" ON members
    FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read stripe_transactions" ON stripe_transactions
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert stripe_transactions" ON stripe_transactions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update stripe_transactions" ON stripe_transactions
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read bank_transactions" ON bank_transactions
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert bank_transactions" ON bank_transactions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update bank_transactions" ON bank_transactions
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read bank_statements" ON bank_statements
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert bank_statements" ON bank_statements
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read billing_discrepancies" ON billing_discrepancies
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert billing_discrepancies" ON billing_discrepancies
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update billing_discrepancies" ON billing_discrepancies
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read import_logs" ON import_logs
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert import_logs" ON import_logs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read expense_categories" ON expense_categories
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert expense_categories" ON expense_categories
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update expense_categories" ON expense_categories
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read app_settings" ON app_settings
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update app_settings" ON app_settings
    FOR UPDATE USING (auth.role() = 'authenticated');

-- ============================================
-- NOTES
-- ============================================
--
-- 1. This schema uses TEXT primary keys, not UUIDs, because the app
--    generates its own string IDs (e.g., 'id_abc123', 'chase_2024-01-15_...')
--
-- 2. Authentication is handled by Supabase Auth, not a custom table.
--    Create users in the Supabase dashboard under Authentication > Users.
--
-- 3. RLS is enabled with policies allowing all authenticated users
--    full access. Adjust policies if you need role-based restrictions.
--
-- 4. The app uses 'email' as the merge key for members, and 'stripe_id'
--    for transactions, to handle upserts correctly.
--

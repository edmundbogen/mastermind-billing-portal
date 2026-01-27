-- Mastermind Billing Portal - Supabase Database Schema
-- Run this in your Supabase SQL Editor to set up the database

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS billing_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'full_admin')) NOT NULL DEFAULT 'full_admin',
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed initial users (passwords will be set via the portal)
-- Default password: 'changeme' - CHANGE IMMEDIATELY after first login
INSERT INTO billing_users (username, name, password_hash, role) VALUES
    ('edmund', 'Edmund Bogen', 'changeme', 'admin'),
    ('eytan', 'Eytan', 'changeme', 'full_admin')
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- MEMBERS TABLE (from Kajabi)
-- ============================================
CREATE TABLE IF NOT EXISTS members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_id TEXT UNIQUE,
    stripe_account TEXT CHECK (stripe_account IN ('reignation', 'coaching')) NOT NULL,
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,
    member_email TEXT,
    customer_name TEXT,
    amount DECIMAL(10,2) NOT NULL,
    fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2),
    currency TEXT DEFAULT 'usd',
    status TEXT CHECK (status IN ('succeeded', 'failed', 'pending', 'refunded', 'disputed')) DEFAULT 'succeeded',
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

-- ============================================
-- KAJABI TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS kajabi_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kajabi_id TEXT,
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,
    member_email TEXT,
    amount DECIMAL(10,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL,
    product_name TEXT,
    offer_name TEXT,
    status TEXT CHECK (status IN ('paid', 'refunded', 'failed', 'pending')) DEFAULT 'paid',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kajabi_member_email ON kajabi_transactions(member_email);
CREATE INDEX IF NOT EXISTS idx_kajabi_date ON kajabi_transactions(transaction_date);

-- ============================================
-- BANK STATEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS bank_statements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    statement_id UUID REFERENCES bank_statements(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL,
    post_date DATE,
    description TEXT NOT NULL,
    original_description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    transaction_type TEXT CHECK (transaction_type IN ('income', 'expense', 'transfer')) DEFAULT 'expense',
    category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
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
-- EXPENSE CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    category_type TEXT CHECK (category_type IN ('income', 'expense')) NOT NULL,
    parent_category TEXT,
    color TEXT DEFAULT '#6c757d',
    icon TEXT,
    is_tax_deductible BOOLEAN DEFAULT FALSE,
    tax_category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default expense categories
INSERT INTO expense_categories (name, category_type, color, is_tax_deductible, sort_order) VALUES
    -- Income categories
    ('Mastermind Subscriptions', 'income', '#28a745', false, 1),
    ('Coaching Revenue', 'income', '#00a8e1', false, 2),
    ('Speaking Fees', 'income', '#6f42c1', false, 3),
    ('Affiliate Income', 'income', '#20c997', false, 4),
    ('Other Income', 'income', '#17a2b8', false, 5),

    -- Expense categories
    ('Kajabi Platform', 'expense', '#dc3545', true, 10),
    ('AI Tools (Claude/ChatGPT)', 'expense', '#fd7e14', true, 11),
    ('Software Subscriptions', 'expense', '#007bff', true, 12),
    ('Contractors/VA', 'expense', '#e83e8c', true, 13),
    ('Marketing & Ads', 'expense', '#ffc107', true, 14),
    ('Travel & Events', 'expense', '#17a2b8', true, 15),
    ('Professional Services', 'expense', '#6c757d', true, 16),
    ('Office & Equipment', 'expense', '#343a40', true, 17),
    ('Bank & Processing Fees', 'expense', '#adb5bd', false, 18),
    ('Refunds Issued', 'expense', '#dc3545', false, 19),
    ('Meals & Entertainment', 'expense', '#fd7e14', true, 20),
    ('Education & Training', 'expense', '#6f42c1', true, 21),
    ('Insurance', 'expense', '#20c997', true, 22),
    ('Other Expenses', 'expense', '#6c757d', false, 99)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- DOCUMENTS TABLE (receipts, invoices)
-- ============================================
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT,
    file_size INTEGER,
    document_type TEXT CHECK (document_type IN ('invoice', 'receipt', 'statement', 'contract', 'tax_document', 'other')) DEFAULT 'receipt',
    related_transaction_id UUID,
    related_member_id UUID REFERENCES members(id) ON DELETE SET NULL,
    description TEXT,
    document_date DATE,
    amount DECIMAL(12,2),
    uploaded_by TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_date ON documents(document_date);

-- ============================================
-- BILLING DISCREPANCIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS billing_discrepancies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES members(id) ON DELETE CASCADE,
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
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_type TEXT CHECK (import_type IN (
        'kajabi_members',
        'kajabi_transactions',
        'stripe_reignation',
        'stripe_coaching',
        'bank_statement',
        'credit_card_statement'
    )) NOT NULL,
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
-- SETTINGS TABLE (app configuration)
-- ============================================
CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by TEXT
);

-- Default settings
INSERT INTO app_settings (key, value) VALUES
    ('csv_mappings', '{
        "kajabi": {
            "email": "Email",
            "name": "Full Name",
            "plan": "Offer Name",
            "amount": "Amount",
            "status": "Subscription Status",
            "date": "Created At"
        },
        "stripe": {
            "id": "id",
            "email": "Customer Email",
            "name": "Customer Name",
            "amount": "Amount",
            "fee": "Fee",
            "status": "Status",
            "date": "Created (UTC)",
            "description": "Description"
        }
    }'::jsonb),
    ('notification_settings', '{
        "email_on_failed_payment": false,
        "weekly_summary": false,
        "alert_threshold": 100
    }'::jsonb),
    ('business_info', '{
        "name": "Edmund''s Mastermind",
        "monthly_target": 50000,
        "member_target": 100
    }'::jsonb)
ON CONFLICT (key) DO NOTHING;

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

-- Apply to tables that need it
DROP TRIGGER IF EXISTS update_billing_users_updated_at ON billing_users;
CREATE TRIGGER update_billing_users_updated_at
    BEFORE UPDATE ON billing_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_members_updated_at ON members;
CREATE TRIGGER update_members_updated_at
    BEFORE UPDATE ON members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate member total paid
CREATE OR REPLACE FUNCTION calculate_member_total_paid(member_email_param TEXT)
RETURNS DECIMAL AS $$
DECLARE
    total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM stripe_transactions
    WHERE member_email = member_email_param
    AND status = 'succeeded';

    RETURN total;
END;
$$ LANGUAGE plpgsql;

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

-- Open discrepancies view
CREATE OR REPLACE VIEW open_discrepancies AS
SELECT
    d.id,
    d.member_id,
    d.member_email,
    d.member_name,
    d.discrepancy_type,
    d.expected_amount,
    d.actual_amount,
    d.difference,
    d.period_start,
    d.period_end,
    d.stripe_account,
    d.related_stripe_id,
    d.status,
    d.priority,
    d.resolution_notes,
    d.resolved_by,
    d.created_at,
    d.resolved_at,
    m.subscription_plan,
    m.subscription_amount
FROM billing_discrepancies d
LEFT JOIN members m ON d.member_id = m.id
WHERE d.status IN ('open', 'investigating')
ORDER BY
    CASE d.priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        ELSE 4
    END,
    d.created_at DESC;

-- ============================================
-- ROW LEVEL SECURITY (Optional - enable if using Supabase Auth)
-- ============================================
-- Uncomment these if you want to use Supabase's built-in auth instead of custom auth

-- ALTER TABLE billing_users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE stripe_transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY "Authenticated users can access all data" ON members
--     FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- GRANTS (if needed for specific roles)
-- ============================================
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

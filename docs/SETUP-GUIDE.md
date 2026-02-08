# Mastermind Billing Portal - Setup Guide

## Current Status
- **Portal URL**: https://edmundbogen.github.io/mastermind-billing-portal/
- **GitHub Repo**: https://github.com/edmundbogen/mastermind-billing-portal
- **Authentication**: Supabase Auth (email/password)
- **Database**: Supabase PostgreSQL (shared between all users)
- **Sync**: Realtime sync between browsers

---

## Features Overview

| Feature | Status |
|---------|--------|
| Supabase Auth (email/password login) | Working |
| Dashboard with MRR, member stats, alerts | Working |
| Members list, search, and filtering | Working |
| Kajabi subscriptions import (CSV) | Working |
| Stripe payments import (CSV) | Working |
| Reconciliation engine (Kajabi vs Stripe) | Working |
| Bookkeeping & expense tracking | Working |
| Chase bank statement import (CSV & PDF) | Working |
| Reports & revenue charts | Working |
| Data export/import (JSON backup) | Working |
| Realtime sync between users | Working |

---

## Initial Setup (Already Done)

The portal is already configured with Supabase. If you need to set up a new instance:

### 1. Supabase Project Setup

1. Create a project at https://supabase.com
2. Run the schema from `docs/supabase-setup.sql` in SQL Editor
3. Enable Row Level Security (RLS) with appropriate policies
4. Create user accounts in Authentication > Users

### 2. Configure the Portal

Update `index.html` with your Supabase credentials (around line 2450):
```javascript
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key';
```

### 3. Deploy

Push to GitHub and GitHub Pages will auto-deploy.

---

## Daily Usage

### Logging In

1. Go to https://edmundbogen.github.io/mastermind-billing-portal/
2. Enter your email and password
3. Click **Sign In**

### Importing Kajabi Members

1. Export from Kajabi: **Analytics > Revenue > Subscriptions > Export**
2. In the portal: **Settings > Import Kajabi CSV**
3. Upload the CSV file
4. Members are added/updated automatically

### Importing Stripe Transactions

1. Export from Stripe Dashboard: **Payments > Export**
2. In the portal: **Settings > Import Stripe (REIGNation or Coaching)**
3. Upload the CSV file
4. Transactions are matched to members by email

### Running Reconciliation

1. Go to **Reconciliation** tab
2. Click **Run Reconciliation**
3. Review discrepancies:
   - Missing payments
   - Failed payments
   - Amount mismatches
   - Members not in Stripe
4. Click **Resolve** on each issue after addressing it

### Importing Bank Statements (Chase)

1. Download statement from Chase (CSV or PDF)
2. Go to **Bookkeeping** tab
3. Click **Import Chase Statement**
4. Upload the file
5. Transactions are auto-categorized by vendor

### Viewing Reports

1. Go to **Reports** tab
2. Select time period (this month, last quarter, etc.)
3. View:
   - Revenue trends
   - Member growth
   - Top members by revenue
   - Churn metrics

### Changing Your Password

1. Go to **Settings** tab
2. Click **Change Your Password**
3. Enter new password (must be 8+ chars with uppercase and number)
4. Click **Update Password**

Note: Each user can only change their own password. To reset another user's password, use the Supabase dashboard.

---

## Data Backup & Restore

### Export Backup

1. Go to **Settings > Data Management**
2. Click **Export JSON**
3. Save the file securely

### Import Backup

1. Go to **Settings > Data Management**
2. Click **Import Backup**
3. Select your backup JSON file
4. Confirm the import (this replaces all current data)

---

## Sync Status Indicator

The sync indicator in the header shows:
- **Green "Synced"**: Connected and up to date
- **Yellow "Syncing..."**: Currently syncing data
- **Gray "Offline"**: No internet connection (changes saved locally)
- **Red "Error"**: Sync failed (check browser console)

Click the sync indicator to manually trigger a sync.

---

## Troubleshooting

### "Login keeps failing"
- Verify email and password are correct (case-sensitive)
- Clear browser cache and try again
- Check Supabase dashboard to confirm user exists

### "Data not syncing between browsers"
- Check sync indicator - is it green?
- Open browser console (F12) and look for errors
- Click sync indicator to force manual sync

### "Import shows 0 records"
- Check CSV has expected columns (Customer Email, Amount, etc.)
- Open browser console to see which columns were detected
- Try a different export format from Kajabi/Stripe

### "Sync shows Error"
- Open browser console (F12) for details
- Check if Supabase project is paused (free tier pauses after inactivity)
- Verify RLS policies allow access

---

## File Locations

| File | Purpose |
|------|---------|
| `index.html` | Main application (single-file app) |
| `docs/supabase-setup.sql` | Database schema |
| `docs/SETUP-GUIDE.md` | This guide |
| `docs/TESTING-GUIDE.md` | Testing checklist |

---

## Architecture Notes

- **Single-file app**: Everything is in `index.html` for simplicity
- **No build step**: Works directly on GitHub Pages
- **Supabase Auth**: Handles login, password hashing, sessions
- **Realtime subscriptions**: Changes sync automatically between browsers
- **LocalStorage fallback**: Data persists locally if offline

---

## Need Help?

Open Claude Code and describe what you need - whether it's adding features, fixing bugs, or understanding the codebase.

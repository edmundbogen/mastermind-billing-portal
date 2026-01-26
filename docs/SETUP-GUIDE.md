# Mastermind Billing Portal - Setup Guide

## Current Status
- **Portal URL**: https://edmundbogen.github.io/mastermind-billing-portal/
- **GitHub Repo**: https://github.com/edmundbogen/mastermind-billing-portal
- **Storage**: Browser localStorage (local to each device)
- **Supabase**: Not connected yet

---

## Step 1: Change Default Passwords (Do This Now)

1. Go to https://edmundbogen.github.io/mastermind-billing-portal/
2. Log in as **Edmund Bogen** with password `changeme`
3. Go to **Settings** tab
4. Click **Change Password** for Edmund → set a secure password
5. Click **Change Password** for Eytan → set his password
6. Share Eytan's password with him securely

**Note**: Passwords are stored in your browser. Each person sets their own on first login.

---

## Step 2: Connect Supabase (For Shared Database)

This step enables Edmund and Eytan to see the same data from any device.

### 2a. Create Supabase Project (if you don't have one)

1. Go to https://supabase.com
2. Sign in or create account
3. Click **New Project**
4. Name it `mastermind-billing` (or similar)
5. Set a database password (save this somewhere safe)
6. Choose region closest to you
7. Wait for project to spin up (~2 minutes)

### 2b. Run the Database Schema

1. In Supabase, go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open this file on your computer:
   ```
   /Users/edmundbogen/mastermind-billing-portal/docs/supabase-setup.sql
   ```
4. Copy the entire contents
5. Paste into Supabase SQL Editor
6. Click **Run**
7. You should see "Success" messages

### 2c. Get Your API Credentials

1. In Supabase, go to **Settings** → **API**
2. Copy these two values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (long string)

### 2d. Update the Portal Code

1. Open the file:
   ```
   /Users/edmundbogen/mastermind-billing-portal/index.html
   ```

2. Find these lines (around line 1730):
   ```javascript
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```

3. Replace with your actual values:
   ```javascript
   const SUPABASE_URL = 'https://your-project.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJhbGc...your-actual-key...';
   ```

4. Save the file

### 2e. Push to GitHub

Run these commands in Terminal:
```bash
cd /Users/edmundbogen/mastermind-billing-portal
git add -A
git commit -m "Connect Supabase database"
git push
```

Wait 1-2 minutes for GitHub Pages to update.

---

## Step 3: Import Your Data

### Import Kajabi Subscriptions (Members)

1. Export from Kajabi: **Analytics → Revenue → Subscriptions → Export**
2. In the portal, go to **Members** tab
3. Click **Import Kajabi CSV**
4. Upload `subscriptions.csv`

### Import Kajabi Payouts (Transactions) - Coming in Phase 2

This will be available after Phase 2 is built.

### Import Stripe Data - Coming in Phase 3

This will be available after Phase 3 is built.

---

## Step 4: Daily/Weekly Use

### Refresh Member Data
1. Export fresh `subscriptions.csv` from Kajabi
2. Go to **Members** → **Import Kajabi CSV**
3. Upload the file (existing members are updated, new ones added)

### Check for Issues
1. Go to **Reconciliation** tab
2. Click **Run Reconciliation**
3. Review any discrepancies

### View Dashboard
- **MRR**: Monthly recurring revenue from active members
- **Active Members**: Count of members with "Active" status
- **Outstanding**: Revenue at risk from past-due members
- **Failed Payments**: Count of failed transactions this month

---

## File Locations

| File | Purpose |
|------|---------|
| `/Users/edmundbogen/mastermind-billing-portal/index.html` | Main application |
| `/Users/edmundbogen/mastermind-billing-portal/docs/supabase-setup.sql` | Database schema |
| `/Users/edmundbogen/mastermind-billing-portal/docs/SETUP-GUIDE.md` | This guide |

---

## Troubleshooting

### "Import shows 0 imported"
- Check that your CSV has `Customer Email` column
- Open browser console (F12) to see which columns were detected

### "Data disappeared"
- If using localStorage only, data is per-browser
- Clear browser cache = data gone
- Solution: Connect Supabase for persistent storage

### "Eytan sees different data"
- Without Supabase, each person has their own local database
- Connect Supabase to share data between users

### "Supabase not syncing"
- Check browser console for errors
- Verify your SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Make sure you ran the SQL schema in Supabase

---

## What's Built vs. Coming Soon

| Feature | Status |
|---------|--------|
| Login & password management | ✅ Working |
| Dashboard with stats | ✅ Working |
| Members list & search | ✅ Working |
| Kajabi subscriptions import | ✅ Working |
| Member detail modal | Phase 2 |
| Stripe CSV import | Phase 3 |
| Reconciliation engine | Phase 4 |
| Bookkeeping & expenses | Phase 5 |
| Reports & exports | Phase 6 |
| PDF statement parsing | Phase 5 |

---

## Need Help?

Open Claude Code and ask to continue building Phase 2, or troubleshoot any issues.

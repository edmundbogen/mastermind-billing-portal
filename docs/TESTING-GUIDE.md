# Mastermind Billing Portal - Testing Guide

## Quick Test Checklist

After pushing changes to GitHub, wait 1-2 minutes for GitHub Pages to update, then run through these tests.

---

## Test 1: Login Works

### Edmund Login
1. Go to https://edmundbogen.github.io/mastermind-billing-portal/
2. Select **Edmund Bogen** from dropdown
3. Enter password: `StanleyBogen1!`
4. Click **Sign In**
5. **Expected**: Dashboard loads, shows "Edmund Bogen" in header

### Eytan Login
1. Logout (click name in header, then Logout)
2. Select **Eytan** from dropdown
3. Enter password: `Eytanisgay1!`
4. Click **Sign In**
5. **Expected**: Dashboard loads, shows "Eytan" in header

---

## Test 2: Data Persists (No More Clearing)

1. Login as Edmund
2. Go to **Members** tab
3. Note how many members are listed (or import a test CSV)
4. **Close the browser completely**
5. Reopen the portal
6. Login as Edmund
7. **Expected**: Same members still visible (data was NOT cleared)

---

## Test 3: Supabase Sync Status

1. Login to the portal
2. Look at top-right of header - should see sync indicator
3. **Green dot + "Synced"** = Connected to Supabase
4. **Gray dot + "Offline"** = Not connected (check console for errors)
5. Click the sync indicator to manually trigger sync

---

## Test 4: Multi-Browser Sync (Edmund + Eytan)

### Setup
- **Browser 1**: Open portal, login as Edmund
- **Browser 2**: Open portal in different browser (or incognito), login as Eytan

### Test Data Sync
1. In Browser 1 (Edmund): Go to Members tab
2. Import a Kajabi CSV or manually note the member count
3. Wait 5-10 seconds for sync
4. In Browser 2 (Eytan): Refresh the page
5. **Expected**: Same members appear in both browsers

### Test Password Sync
1. In Browser 1 (Edmund): Go to Settings > Change Edmund's password
2. Change to a new password (e.g., `NewPassword123!`)
3. Logout
4. In Browser 2 (Eytan): Logout, then try logging in as Edmund
5. Use the NEW password
6. **Expected**: Login succeeds with new password

---

## Test 5: Bookkeeping Sync (Bank Transactions)

1. Login as Edmund
2. Go to **Bookkeeping** tab (if available)
3. Import a bank statement or add a manual transaction
4. Wait for sync (green dot should flash)
5. In another browser, login and check Bookkeeping
6. **Expected**: Same transactions appear

---

## Troubleshooting

### "Login keeps failing"
- Clear browser cache/cookies for the site
- Check browser console (F12) for errors
- Verify password matches exactly (case-sensitive)

### "Data not syncing between browsers"
- Check sync indicator - is it green?
- Open browser console and look for "Sync to Supabase completed"
- Click sync indicator to force manual sync
- If errors appear, check Supabase project status

### "Sync shows Error (red dot)"
- Open browser console (F12)
- Look for Supabase errors
- Common issues:
  - Supabase project paused (free tier pauses after inactivity)
  - API key expired or incorrect
  - Network connectivity issues

### "Old password still works / new password doesn't"
- Password sync takes a few seconds
- Try manual sync (click sync indicator)
- Clear localStorage: In console, run `localStorage.clear()` then refresh

---

## Console Commands for Debugging

Open browser console (F12) and try these:

```javascript
// Check current users/passwords
console.log(users);

// Check app data
console.log(appData);

// Check Supabase connection
console.log('Supabase client:', supabaseClient);
console.log('Sync status:', syncStatus);

// Force a sync
fullSync();

// Check what's in localStorage
console.log(JSON.parse(localStorage.getItem('mastermind_billing_data')));
```

---

## Expected Results After All Tests Pass

| Test | Result |
|------|--------|
| Edmund login | Works with `StanleyBogen1!` |
| Eytan login | Works with `Eytanisgay1!` |
| Data persists after close | Yes |
| Sync indicator | Green "Synced" |
| Multi-browser sync | Members match in both |
| Password changes sync | Yes |
| Bookkeeping syncs | Yes |

---

## After Testing

If all tests pass, the portal is ready for daily use. If issues arise, check the Troubleshooting section or open Claude Code for debugging.

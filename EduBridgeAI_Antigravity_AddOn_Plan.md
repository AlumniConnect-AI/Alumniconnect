# EduBridge AI — Extension Plan (Add-Ons to Existing Antigravity Project)
**This is NOT a new app build. This is a set of additions to the existing AlumniConnect / EduBridge AI codebase already running in Antigravity.**
Team Sight Flub | SIH 2026 | PS ID: SIH26135

---

## 0. Instruction for Antigravity — read first

**Do not scaffold a new project, new navigation shell, or new auth flow.** The app already exists with:
- Working Login/Register screens
- A single shared Home Dashboard (all users currently land here)
- 4 working AI engines (Career Twin, Career GPS, Skill Gap Analyzer, Mentor Match) — fully functional, do not touch their internal logic
- Existing Firebase Auth + Firestore + Supabase setup
- Existing bottom navigation: Home, Community, Staff, Jobs, Events, Messages

Your job is to **extend** this existing codebase with the additions below — new fields on existing collections, new cards on the existing Home screen, a role-based fork in navigation, and a few new screens. Every item below should be implemented as a **modification or addition to an existing file/screen**, not a rebuild.

Where a new screen is genuinely required (it doesn't exist today), it's marked **[NEW SCREEN]** below. Everything else is marked **[EXTEND EXISTING]**.

---

## 1. What's changing at a high level

| Area | Current state | Add-on |
|---|---|---|
| Home screen | Single shared dashboard for everyone | **[EXTEND]** Fork into Student Home and Alumni Home based on a `role` field — reuse the same layout shell, swap the content cards |
| Registration | Basic signup form | **[EXTEND]** Add role selector, consent checkbox, graduation year field |
| Firestore `users` doc | Basic profile fields | **[EXTEND]** Add `role`, `consentGiven`, `verificationStatus`, `graduationYear` fields |
| Firestore | No outcome-tracking collection | **[NEW]** Add `outcome_tracking` collection |
| Firestore | Existing `mentorship` collection (from Mentor Match engine) | **[EXTEND]** Add `requestStatus`, `mentorUid`, `menteeUid` fields to support two-way accept/decline |
| Navigation | One bottom nav for all users | **[EXTEND]** Same nav bar component, swap the tab set based on role (Student tabs vs Alumni tabs) |

**Nothing about the 4 AI engines changes.** Career Twin, Career GPS, Skill Gap Analyzer, and Mentor Match keep their exact current screens and logic — the additions below sit around them, not inside them.

---

## 2. Registration screen — additions only

**File to extend:** existing registration/signup screen

Add these fields to the existing form (do not rebuild the form):
- Role selector: radio buttons "Student" / "Alumni" (new)
- Graduation year field (new — required for Alumni, expected-year for Student)
- Consent checkbox (new — required to submit):
  > "I consent to periodic outcome tracking (employment status check-ins) to help measure the impact of my training."

On submit, write to the **existing** `users/{uid}` document, adding these fields to whatever's already being written:
```
role: "student" | "alumni"
graduationYear: number
consentGiven: boolean
consentTimestamp: timestamp
verificationStatus: "verified" | "pending"   // only set if role == "alumni"
```

If role == "alumni" at signup, run the lightweight verification check (Section 3) before completing registration.

---

## 3. Alumni verification — new lightweight check (no Admin module involved)

**[NEW — small utility, not a full screen]**

Since the Admin/Staff module is being built separately and isn't part of this add-on:
- On Alumni signup or role-flip, check submitted College ID + graduation year against a `verified_students` Firestore collection (seed with sample/demo data)
- Match found → `verificationStatus: "verified"`
- No match → `verificationStatus: "pending"` — user still gets full Alumni Home access, but a small dismissible banner shows: *"Verification pending — your college hasn't confirmed this record yet."*

This keeps the demo flow unblocked without needing the Admin approval screen to exist yet.

---

## 4. Home screen fork — [EXTEND EXISTING]

**Do not create two separate screens from scratch.** Take the existing Home screen and:

1. Wrap it with a role check at the top (read `users/{uid}.role` once after login, via a lightweight `RoleRouter` — a single conditional, not a new architecture layer)
2. Keep the existing header, Quote of the Day card, and AI Hub card **exactly as they are today** — these are shared between Student and Alumni
3. **Below the AI Hub card**, branch the rest of the screen:

### If role == "student" — add these cards to the existing layout
- **[NEW CARD] "My Career Journey"** — retention timeline widget (Section 6)
- **[NEW CTA]** small button/card: "Update your placement status" → opens the placement self-report form (Section 5)
- Keep the existing 2x3 icon grid and Latest Updates section as-is

### If role == "alumni" — swap in these cards instead
- **[NEW CARD] "Mentorship Requests"** — pending requests from the existing `mentorship` collection, filtered where `mentorUid == currentUser` and `requestStatus == "pending"`
- **[NEW CARD] "My Mentees"** — accepted mentorships, simple avatar row
- **[NEW CARD] "Post a Referral / Internship"** — CTA opening a small form (Section 7)
- **[NEW CARD] "Employment Verification"** — pending verification count (Section 8)
- **[NEW CARD] "My Career Journey"** — same retention timeline widget as Student (Section 6), reused, not duplicated
- Keep the icon grid pattern but relabel tiles: My Profile, Referrals, Mentees, Jobs Posted, Events, Search

**Bottom navigation swap:**
- Student keeps existing tabs: Home, Community, Jobs, Events, Messages
- Alumni gets: Home, Mentees, Referrals, Verify, Profile

Implement this as one nav bar component with two tab-set configs, not two separate nav bar widgets.

---

## 5. Placement self-report form — [NEW SCREEN, small]

Accessible from the new CTA on Student Home (and reused for Alumni ongoing updates).

Fields:
- Employment status dropdown: Trained / Placed / Self-Employed / Apprenticeship / Still Searching
- If "Still Searching" is selected and it's been 6+ months since `graduationYear` → show non-placement reason dropdown: No relevant openings / Relocated / Low wage offers / Pursuing further studies / Other

On submit, write to `outcome_tracking/{uid}` (new collection — see Section 9), appending to a `checkIns` array and updating the top-level `status` field.

---

## 6. Retention Timeline widget — [NEW, shared component]

Build once, use in both Student Home and Alumni Home (per Section 4). Do not build two versions.

- Reads `outcome_tracking/{uid}.status`
- Renders 5 stage-dots: Trained → Placed → Retained 3mo → Retained 6mo → Retained 12mo
- Completed stages glow/filled, future stages greyed out
- If status is `"dropped_off"`, render the last-completed stage in red/amber instead of showing the next stage as simply pending

---

## 7. Post Referral screen — [NEW SCREEN, small]

Accessible from Alumni Home's new CTA card.

Fields: Title, Company Name, Type (Job/Internship/Referral), Description → Submit

Writes to a new `referrals` collection:
```
referrals/{referralId}
  postedByUid: string
  title: string
  companyName: string
  type: "job" | "internship" | "referral"
  description: string
  postedAt: timestamp
```

**Connect to existing Jobs tab:** the existing Jobs screen (Student-facing) should also pull from this new `referrals` collection alongside whatever it currently displays — this is the one place where an *existing* screen needs a data-source addition, not just a new screen.

---

## 8. Employment Verification screen — [NEW SCREEN, small]

Accessible from Alumni Home's new CTA card.

- Lists pending verification requests — simple MVP matching: any `outcome_tracking` check-in where `employerName` roughly matches the alumnus's own listed employer
- Each row: student name, claimed employer/role, Approve / Reject buttons
- Approve → sets `verified: true` on that check-in entry inside `outcome_tracking/{studentUid}.checkIns`

---

## 9. Firestore additions — summary of new/changed fields

### Extend existing `users/{uid}`
```
+ role: "student" | "alumni"
+ graduationYear: number
+ consentGiven: boolean
+ consentTimestamp: timestamp
+ verificationStatus: "verified" | "pending"
+ engagementStats: { mentorshipCount, referralsPosted, verificationsCompleted }  // increment on relevant actions, no new screen needed yet
```

### New collection `outcome_tracking/{uid}`
```
status: "trained" | "placed" | "retained_3mo" | "retained_6mo" | "retained_12mo" | "dropped_off"
placementDate: timestamp | null
employmentType: "formal" | "self_employed" | "apprenticeship" | "unemployed" | null
employerName: string | null
nonPlacementReason: string | null
checkIns: [ { date, status, employmentType, note, verified } ]
```

### Extend existing `mentorship` collection
```
+ requestStatus: "pending" | "accepted" | "declined"
+ mentorUid: string
+ menteeUid: string
```

### New collection `referrals/{referralId}`
(see Section 7)

**Critical rule:** `outcome_tracking/{uid}` is ONE document per user for their entire lifetime — it does not get recreated or duplicated when `role` flips from student to alumni. The timeline must show one continuous history.

---

## 10. Role-flip logic — [NEW, small utility]

Wire this as a Cloud Function or in-app check (whichever the existing codebase already uses for similar background logic):

**Trigger A (primary):** `outcome_tracking.status == "placed"` AND `users.consentGiven == true` → set `users.role = "pending_alumni_verification"`, show in-app prompt to complete verification (Section 3)

**Trigger B (manual):** Add a single button on the existing Profile screen: "I've graduated — become an alumnus" → runs same verification step

**Trigger C (fallback nudge, in-app only):** If `graduationYear` has passed by 18+ months with no placement report, show an in-app banner prompting a status update — this does not auto-flip the role, it just nudges toward Trigger A/B

On successful flip: `users.role = "alumni"`. Do not touch `career_profile` or `outcome_tracking` data — they carry forward untouched.

---

## 11. Explicitly NOT part of this add-on pass

- Staff/Admin role, screens, or dashboard — separate module, being built independently. Leave the existing "Staff" nav tile pointing at whatever placeholder it currently points to.
- SMS/WhatsApp integration — all reminders/nudges in this pass are in-app only (existing notification bell icon / in-app banner pattern). Data fields are structured so a messaging provider can be wired in later without a schema change.
- External employer verification links (token-based, no-login) — this pass only builds the in-app alumni-side approval (Section 8). External-link verification is a future add-on.
- Wage/salary progression capture — not in this pass.
- Any changes to the 4 existing AI engines — their screens and logic are untouched.

---

## 12. Build order for this add-on pass

1. Extend `users` schema + registration form (role, consent, grad year) — Section 2
2. Add `outcome_tracking` and `referrals` collections — Section 9
3. Build `RoleRouter` fork on existing Home screen — Section 4
4. Build Retention Timeline shared widget — Section 6 (needed by both roles)
5. Build Placement self-report form — Section 5
6. Build Alumni-side new cards (Mentorship Requests, My Mentees, Post Referral CTA, Verification CTA) — Section 4
7. Build Post Referral screen — Section 7
8. Build Employment Verification screen — Section 8
9. Connect existing Jobs screen to also read from `referrals` collection — Section 7
10. Wire role-flip triggers A, B, C — Section 10
11. Wire `engagementStats` increments on relevant actions — Section 9

---

## 13. One-line summary for Antigravity's context window

*"Extend the existing EduBridge AI Flutter app — do not scaffold a new project. Add role-based forking to the existing shared Home screen (Student vs Alumni), extend the existing registration form and Firestore `users` schema with role/consent/verification fields, add two new Firestore collections (`outcome_tracking`, `referrals`), add a shared Retention Timeline widget used by both roles, and add 3 new lightweight screens (Placement self-report, Post Referral, Employment Verification). Leave the 4 existing AI engines and the Staff nav tile untouched — those are out of scope for this pass."*

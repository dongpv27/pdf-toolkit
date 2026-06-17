# Privacy Policy — PDF Toolkit

> **Two parts in this file:**
> 1. The **Privacy Policy** text — host it publicly and paste the URL into Play Console.
> 2. **Data Safety form** — recommended answers for the Play Console form (AdMob compliance).
>
> 🔧 Before publishing, replace the placeholders: `[DEVELOPER_NAME]`,
> `[CONTACT_EMAIL]`, `[POLICY_URL]`. Suggested contact: dongpv2702@gmail.com.

---

# PART 1 — PRIVACY POLICY (hostable text)

**Effective date:** 17 June 2026
**App:** PDF Toolkit (package `com.[yourcompany].pdftoolkit`)
**Developer:** [DEVELOPER_NAME]
**Contact:** [CONTACT_EMAIL]

## 1. Overview
PDF Toolkit ("the app", "we", "us") is an offline utility that lets you convert
images to PDF, merge PDF files and compress PDF files entirely on your device.
We respect your privacy. **We do not collect, store, or upload your documents or
images to any server.** All file processing happens locally on your device.

This policy explains what data is handled, by us and by the third-party
advertising service we use (Google AdMob).

## 2. Data we collect ourselves
**None.** The app has no account system, no analytics of our own, and no backend.
The images and PDF files you select are processed on-device and saved to the
app's local storage. They are never transmitted to us or to any third party by
the app itself.

## 3. Data collected by third parties (Google AdMob)
The app displays ads through **Google AdMob**. To serve and measure ads, Google
and its partners may collect and process certain data, including:

- **Advertising ID** and other device identifiers
- **IP address** and approximate (coarse) location derived from it
- **Device information** (model, OS version, language)
- **Ad interaction data** (ads viewed, clicked, rewarded events)

This data is used to serve ads (including personalized ads where permitted),
measure ad performance, and prevent fraud. Google acts as an independent data
controller for this data.

- Google's Privacy Policy: https://policies.google.com/privacy
- How Google uses data from apps that use its services:
  https://policies.google.com/technologies/partner-sites
- Google Ads/AdMob policies: https://policies.google.com/technologies/ads

## 4. Permissions used
- **Photos / Media (read selected images):** only to let you pick images you
  choose to convert to PDF. We access only the files you explicitly select.
- **File access (PDF selection):** only to let you pick PDF files you choose to
  merge or compress.
- **Internet / Network state:** required to load and display ads.
- **Advertising ID (`AD_ID`):** used by AdMob as described above.

We do **not** request broad storage access (no "All files" / MANAGE_EXTERNAL_STORAGE),
camera, contacts, microphone, or precise GPS location.

## 5. Children
PDF Toolkit is a general-audience productivity tool and is **not directed to
children under 13** (or the equivalent minimum age in your country). We do not
knowingly collect personal information from children. If you believe a child has
provided data through the ads service, contact us and we will assist.

## 6. Your choices
- **Reset or delete your Advertising ID:** Android Settings → Privacy → Ads.
- **Opt out of personalized ads:** Android Settings → Privacy → Ads → "Delete
  advertising ID" (you will still see non-personalized ads).
- **Stop all data sharing with AdMob:** uninstall the app.

## 7. Data security & retention
The app stores generated PDFs only in its local app storage; you can delete them
via your device file manager or by uninstalling the app. Data handled by AdMob is
transmitted over encrypted (HTTPS) connections and retained per Google's policies.

## 8. Changes to this policy
We may update this policy from time to time. Material changes will be reflected
by updating the "Effective date" above and, where appropriate, within the app or
store listing.

## 9. Contact
Questions about this policy: **[CONTACT_EMAIL]**

---

### How to host this policy (pick one — all free)
1. **GitHub Pages:** create a public repo, add `privacy.md` or `index.html`,
   enable Pages → you get a URL like `https://you.github.io/pdftoolkit/privacy`.
2. **Google Sites:** new site → paste the text → publish → use the public URL.
3. **Notion / Carrd / your own domain:** any publicly reachable HTTPS URL works.

Paste that URL into Play Console → **Policy → App content → Privacy policy**.
The same URL also goes in the store listing's Privacy Policy field.

---

# PART 2 — DATA SAFETY FORM (Play Console recommended answers)

> Play Console → **Policy → App content → Data safety**. Answers below reflect a
> standard AdMob integration with no first-party data collection.
>
> ✅ **Verify against Google's official source** before submitting — the exact set
> depends on your ad formats/settings:
> "AdMob & Data safety" → https://support.google.com/admob/answer/11150250

## Q1. Does your app collect or share any of the required user data types?
**Yes.** (Because the AdMob SDK collects data, even though *your* code does not.)

## Q2. Is all of the user data collected by your app encrypted in transit?
**Yes.** (AdMob uses HTTPS.)

## Q3. Do you provide a way for users to request that their data be deleted?
**No account data is stored by the app.** Select that users can manage/reset
their Advertising ID via device settings. (There is no in-app account to delete.)

## Q4. Data types — declare these (from AdMob):

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| **Device or other IDs** (Advertising ID) | ✔ Yes | ✔ Yes | Advertising or marketing; Analytics; Fraud prevention | Required |
| **Location → Approximate location** | ✔ Yes | ✔ Yes | Advertising or marketing | Required |
| **App activity → App interactions** | ✔ Yes | ✔ Yes | Advertising or marketing; Analytics | Required |
| **App info & performance → Diagnostics / Crash logs** | ✔ Yes | ✔ Yes | Analytics; Fraud prevention | Required |

> Do **NOT** declare: Personal info (name/email), Photos/Videos, Files/Docs,
> Contacts, Messages, Financial info. The app processes images/PDFs **locally**
> and never uploads them, so they are not "collected" under Play's definition.

## Q5. Data usage notes
- Mark each declared type as **"Collected"** AND **"Shared"** (shared = sent to
  Google as a third party).
- Mark **not** "processed ephemerally" (AdMob may retain it).
- Data is **not** used for account management (no accounts).

## Q6. Ads declaration (separate toggle)
- Play Console → **App content → Ads** → **"Yes, my app contains ads."**
- This adds the "Contains ads" badge on your store listing (required & honest).

## Q7. Advertising ID permission
- The `com.google.android.gms.permission.AD_ID` permission is auto-added by the
  ads SDK. Declare its use as **Advertising** in the Console if prompted.
- If you ever target children/Families, you must **remove** AD_ID and use
  non-personalized ads — out of scope for this general-audience MVP.

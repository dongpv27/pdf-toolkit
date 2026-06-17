# PDF Toolkit — UI Design System (Professional Productivity)

> Goal: make the app read as a **trustworthy, enterprise-grade productivity
> tool** (Google Drive / Adobe Scan / Notion vibe) — not a playful toy.
> Direction: **Blue primary · Slate-gray neutrals · Teal accent**.
> ✅ Already implemented in [lib/app/theme.dart](lib/app/theme.dart).

---

## 1. NEW COLOR PALETTE (hex)

### Core roles
| Role | Hex | Use |
|---|---|---|
| **Primary** | `#2563EB` | Buttons, PDF icons, active states, links |
| Primary container | `#DBEAFE` | Icon backdrops, soft highlights |
| On primary container | `#1E3A8A` | Text/icon on the soft blue |
| **Secondary** | `#475569` | Neutral controls, secondary text emphasis |
| Secondary container | `#E2E8F0` | Chips, subtle fills |
| **Accent (Tertiary)** | `#0D9488` | Success-ish highlights, badges (sparingly) |
| **Background** | `#F8FAFC` | App scaffold (cool near-white) |
| **Card / Surface** | `#FFFFFF` | Cards, sheets, dialogs |
| Surface container | `#F1F5F9` | List rows, grouped fills |
| **Text primary** | `#0F172A` | Headings & body |
| **Text secondary** | `#64748B` | Captions, subtitles, hints |
| Outline / border | `#CBD5E1` | Dividers, borders |
| Error (only!) | `#DC2626` | Genuine errors/destructive only |

### Dark mode (bonus — also implemented)
| Role | Hex |
|---|---|
| Primary | `#60A5FA` |
| Background | `#0F172A` |
| Surface/Card | `#1E293B` |
| Text primary | `#E2E8F0` |
| Text secondary | `#94A3B8` |
| Accent | `#2DD4BF` |

**Why this palette:** Blue is the universal "trust + productivity" color (banks,
Dropbox, LinkedIn, Google Drive). Slate-gray neutrals keep it calm and
enterprise. A single teal accent adds modern freshness without the childish feel
of purple/pink. Red is *reserved exclusively for errors*, so nothing else
competes with or mimics an alert state.

---

## 2. PDF ICON COLOR FIX

| | Before | After |
|---|---|---|
| Color | 🔴 Red `#F44336`-ish | 🔵 **`#2563EB`** (primary blue) |
| Reads as | error / delete / danger | trust / a healthy document |

**Recommendation:** PDF and tool icons use **`#2563EB`** on a **`#DBEAFE`**
(soft blue) backdrop.

**Reasoning:**
- Red is the system color for **errors and destructive actions**. A red PDF icon
  subconsciously signals "something is wrong" or "delete" — the opposite of the
  confidence you want before someone trusts the app with their documents.
- Red also clashes with the genuine error state, hurting clarity.
- Blue is associated with security, reliability and software tooling. It makes
  the icon look like a *feature*, not a *warning*.
- The soft-blue backdrop (`#DBEAFE`) creates a friendly "chip" that lifts the
  icon and matches the Google-Drive/SaaS pattern of tinted icon tiles.

> Note: for the **Play Store launcher icon**, a deep blue/indigo PDF mark also
> outperforms red on the white search background — see
> [ASO-PLAY-STORE-ASSETS.md](ASO-PLAY-STORE-ASSETS.md) §7.

---

## 3. UI STYLE GUIDE

### Buttons
- **Primary action:** `FilledButton`, full-width (`min height 52`), **14 px**
  radius, label weight **600**, 16 px. One primary action per screen.
- **Secondary action:** `TextButton`/`FilledButton.tonal` in primary blue.
- **Destructive:** only here may you use the error red.
- States: rely on Material 3 elevation/overlay; no custom glows.

### Cards
- **Surface:** white (`#FFFFFF`) on the `#F8FAFC` background.
- **Elevation:** very low (1–1.5) with a soft, low-alpha shadow — *separation by
  light, not by heavy borders*. No hard 1px borders.
- **Radius:** **20 px** for content cards, **14 px** for list rows / inputs.
- **Icon tile:** 56×56, 16 px radius, `#DBEAFE` fill, primary-blue glyph.

### Spacing system (4-pt grid)
`4 · 8 · 12 · 16 · 20 · 24 · 32`
- Screen padding: **16–20**.
- Between cards: **12**.
- Inside cards: **16–20**.
- Section gaps: **24**.
- Icon ↔ text: **12–16**.

### Typography tone
- Family: system default (Roboto) now; **Inter** or **Plus Jakarta Sans**
  recommended for a sharper SaaS feel (add later via `google_fonts`).
- Headings: weight **700**, tight; titles weight **600**.
- Body: weight 400, `#0F172A`; captions weight 400, `#64748B`, line-height ~1.4.
- Tone: concise, confident, lowercase-free labels ("Convert to PDF", not
  "convert!!"). No emojis in core UI.

### Elevation & depth
- Background flat. Cards float subtly. Dialogs/sheets get the most elevation.
- Use color/tint for hierarchy before shadows.

---

## 4. BEFORE / AFTER

### Why the old red + purple was wrong here
- **Purple/lavender (old seed `#3D5AFE` → pastel containers):** reads as
  playful/consumer/creative — fine for a kids' or social app, but it
  *undersells* a document utility and lowers perceived reliability. Users
  hesitate to trust playful apps with important files.
- **Red PDF icon:** mimics an error/alert/delete state, creating subtle anxiety
  exactly at the moment of action ("Convert", "Merge", "Save").
- **Combined effect:** inconsistent signals → lower trust → lower install
  conversion and lower willingness to grant file access.

### How the new palette improves things
| Dimension | Improvement |
|---|---|
| **Trust** | Blue + slate is the established "serious software" language; nothing looks like an error. Users feel safe handing over documents. |
| **Conversion** | Clean white cards, one clear blue primary button, and calm neutrals reduce cognitive load → higher store→use and feature completion. The blue CTA stands out unmistakably. |
| **Perceived value** | The Google-Drive/Notion aesthetic signals "premium, well-built" — users perceive higher quality, are more tolerant of ads, and rate higher. |
| **Consistency** | Red now means *only* error; teal = positive highlight; blue = action. Predictable color semantics = a more professional, learnable UI. |

---

## IMPLEMENTATION STATUS
- ✅ [lib/app/theme.dart](lib/app/theme.dart) — full light + dark ColorSchemes & component themes.
- ✅ [lib/widgets/tool_card.dart](lib/widgets/tool_card.dart) — white cards, soft shadow, blue icon tiles.
- ✅ [lib/screens/compress_pdf_screen.dart](lib/screens/compress_pdf_screen.dart) — PDF icon now primary blue.
- ✅ Empty states & buttons inherit the new scheme automatically.
- 🔜 Optional next: add `google_fonts` (Inter) and a custom launcher icon.

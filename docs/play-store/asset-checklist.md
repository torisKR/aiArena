# Google Play asset checklist (current requirements)

Status: CHECKLIST ONLY — no final Play asset upload or AAB audit is claimed. Confirm requirements in Play Console at upload time because Google may revise them.

Official references (checked 2026-08-05):

- Listing text limits: https://support.google.com/googleplay/android-developer/answer/9859152?hl=en-GB
- Preview assets and dimensions: https://support.google.com/googleplay/android-developer/answer/9866151?hl=en

## Required listing text

- [ ] App name: maximum **30 characters** per locale (full-width and half-width characters both count).
- [ ] Short description: maximum **80 characters** per locale.
- [ ] Full description: maximum **4,000 characters** per locale.
- [ ] English (US), Korean, Japanese, and Simplified Chinese copy reviewed by a fluent owner/reviewer.
- [ ] No ranking, awards, price/promotion, call-to-action, unrelated keywords, or invented online/AI-service claims.

## Required graphics for this game

- [ ] App icon: **512 × 512 px**, **32-bit PNG with alpha**, maximum **1,024 KB**. No badges or misleading price/ranking/store text.
- [ ] Feature graphic: **1,024 × 500 px**, **JPEG or 24-bit PNG**, **no alpha**. Keep important branding inside the center safe area; no Play badge, price, ranking, or call to action.
- [ ] Phone screenshots: at least **2 screenshots** to publish; each **JPEG or 24-bit PNG**, **no alpha**, minimum dimension **320 px**, maximum dimension **3,840 px**, and maximum dimension no more than **2×** the minimum dimension.
- [x] Game recommendation-quality set: five opaque **1,920 × 1,080 px** landscape JPEG captures of the current Flutter UI: Command Deck, live Directive, command Handoff, Chronicle Debrief, and Signal Archive. Recreate them with `tooling/capture_play_store_screenshots.sh` on `emulator-5554`; rerun the asset test before upload.
- [ ] Maximum **8 screenshots per supported device type**. Add only device types actually supported; do not claim TV, Wear OS, Automotive, tablet, Chromebook, or XR support without matching captures.
- [ ] Each uploaded screenshot/graphic has alt text of **140 characters or fewer**, describing the important visible experience without “photo of”/“image of”.

## Asset review gates

- [ ] Captures show the actual current app, with no personal notifications, device IDs, email, debug overlays, console chrome, fabricated ratings, price, or unavailable features.
- [ ] Screenshots are not stretched, clipped, sideways, or compressed; UI text is legible at Play display sizes.
- [ ] Feature graphic and icon use the approved Tokenfront branding and contain no third-party marks.
- [ ] Owner records source commit and final asset hashes after capture. This checklist does not assert that those assets exist or that an AAB has passed audit.

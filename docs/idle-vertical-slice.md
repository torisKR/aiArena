# Idle mode vertical slice

This slice is an optional, clearly labeled `IDLE FRONT // OPTIONAL MODE` entered from the existing command deck. It does not replace Chronicle/Skirmish and does not read or write the story, WT wallet, billing, ad, or branding state.

## Provisional tuning model

- Idle save key: `tokenfront.idle_mode.v1`; schema version 1.
- Level 1 earns 2.5 credits per elapsed second; settlement stores integer credits and floors half-credit fractions.
- A stage requires 20 progress points. Level 1 generates 1 point/second; each core level adds one point/second.
- Upgrade cost is `50 * 2^(coreLevel - 1)` credits. The first upgrade is reachable after 20 seconds, with a 10-second cost target if fractional income is viewed continuously.
- Offline settlement caps elapsed time at 8 hours and clamps clock rollback to zero. The saved timestamp advances only by the accepted elapsed duration.
- Claims and upgrades are serialized through a repository operation queue. A second claim at the same timestamp returns zero and cannot duplicate credits.
- The local clock is injectable in the domain/repository tests. Device-clock tampering is not prevented without a server; this is deliberately an offline-first prototype.

## Implemented experience

The portrait screen keeps the ongoing automatic battle and stage progress above the growth panel, shows one next goal, and exposes one real core upgrade. Accessibility labels describe the active battle and all controls use standard touch targets. English, Korean, Japanese, and Simplified Chinese strings are real translations.

## Missing long-term content

Boss-specific combat rules, multiple core roles, formation choices, prestige/reset, long-term stage map, audio cues, cloud backup, anti-clock-tamper verification, and any store/IAP integration remain out of scope. No fake tabs, rewards, shop, guild, PvP, summon, or monetization UI was added.

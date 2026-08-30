# Tokenfront: Orbital Signal War — Design

**Status:** Active product direction
**Date:** 2026-08-31

## Decision

Tokenfront is an original **AI token war simulation** titled **Tokenfront: Orbital Signal War**. Four fictional autonomous command cores fight through a shared orbital relay network. Each simulated unit is one live AI token in its core's fixed 1,000-token compute supply. The deterministic 4,000-unit battle remains mechanically intact; the product now names that existing survivor economy clearly.

Real product brands such as Claude, Gemini, ChatGPT, Grok, and Codex will not be factions, logos, character likenesses, or public identifiers. The project owns its fiction end to end.

## Product promise

> Four AI cores. 4,000 live tokens. One last relay. Burn the enemy supply before your command signal is erased.

The player chooses one of four equally powered command cores and directly steers one linked token. When that token is burned, command relays to a surviving token in the same supply. Victory still comes from live-token survival or the existing time-limit ranking; the Last Relay is the narrative prize, not a new capture-point mechanic.

## Token economy

- **Live AI tokens** are the existing simulated units. A core starts with 1,000, its HUD count is the current live supply, and each destroyed unit is one burned token.
- **Command signal** is the player's control link. Casualty relay is automatic; Chronicle manual relay spends only its existing 45-second relay charge.
- **War Tokens (WT)** remain the existing device-local cosmetic reward. They never increase combat power and are not cryptocurrency, blockchain tokens, purchasable assets, or an account ledger.

This vocabulary exposes a strategic resource that already exists in the simulation. It does not add a second economy, minting loop, token sale, backend, or balance surface.

## Options considered

1. **Real AI-brand war.** Fast recognition, but it creates trademark, endorsement, store-review, and long-term dependency risk. Rejected.
2. **Original orbital command war.** Keeps the proven battle, adds a specific setting, and preserves full product ownership. **Selected.**
3. **Full starship-game rebuild.** Strongest literal space fantasy, but it would require new movement, combat, balance, art, and QA and would misrepresent the current token-swarm game. Rejected for this release.

## World and factions

The battlefield is **Orbit 00**, the final functioning relay layer around a silent world. Four autonomous cores wake on the same network and each deploys a 1,000-token inference supply. A continuous command signal can jump between live tokens, so the player controls a core-wide intelligence rather than a single hero.

The factions retain their established colors and glyphs. Their protocol names communicate personality only; all four remain mechanically symmetric.

| Core | Protocol | Identity | Gameplay promise |
|---|---|---|---|
| AMETHYST | ARCHIVE | Persists context when the token war erases it | Equal 1,000-token supply and rules |
| COBALT | BASTION | Spends compute slowly so the signal outlives its host | Equal 1,000-token supply and rules |
| VOLT | SURGE | Burns tokens quickly to cross the gap first | Equal 1,000-token supply and rules |
| PRISM | MIRROR | Reuses enemy patterns to stretch its token budget | Equal 1,000-token supply and rules |

No copy may imply faction-exclusive powers unless those powers are implemented and balanced in a later, separately approved feature.

## Lobby experience

The lobby has one job: let the player understand the conflict, choose a command core, and deploy.

1. The header reads `TOKENFRONT` with the localized product subtitle **Orbital Signal War**.
2. The product line reads `FOUR AI CORES. 4,000 LIVE TOKENS. ONE LAST RELAY.`
3. The four existing faction cards show the core name, protocol label, and 1,000-token live supply.
4. The selected-core panel shows its localized identity line plus a shared symmetric-rules line: 1,000 AI tokens, balanced compute levels, continuous command relay.
5. The primary action becomes **Deploy to Orbit**.

The established tactical-console palette, typography, beveled panels, and accessibility behavior remain. The aesthetic risk is concentrated in the broken-orbit mission strip and revised Blender key art; extra stars, gradients, and decorative sci-fi chrome are avoided.

## Visual asset direction

The Blender source scene remains canonical. Its four colored swarms and relay tape are preserved, while the arena is reframed as an orbital plotting table:

- add a central Last Relay beacon;
- add two or three broken concentric orbit arcs and faction-colored signal nodes;
- add a restrained planetary limb or void falloff outside the plotting surface;
- retain the top-down tactical view so the art still promises the actual game;
- render the existing 1440×900 key-art output through the repository's Blender MCP helper and keep the current asset fallback behavior.

The runtime token atlas and faction silhouettes do not change.

## Battle and result presentation

Battle mechanics, controls, camera, HUD density, performance budgets, and mobile control sizes remain unchanged. The existing survivor counts become the explicit live-token supply:

- the battlefield backdrop receives faint orbital arcs and a central relay mark, kept below units and interaction layers;
- the command rail announces each core's live token supply while keeping the same integer counts;
- victory copy says that the winning core secures the Last Relay;
- command handoff remains the defining signal-relay sequence.

No capture objective, ship physics, projectile system, or faction ability is added.

## Localization and metadata

English remains the source language. Korean, Japanese, and Simplified Chinese ship in the same change.

| Locale | App title | Lobby line | Primary action |
|---|---|---|---|
| EN | Tokenfront: Orbital Signal War | FOUR AI CORES. 4,000 LIVE TOKENS. ONE LAST RELAY. | DEPLOY TO ORBIT |
| KO | Tokenfront: 궤도 신호전 | 네 AI 코어. 4,000개의 활성 토큰. 단 하나의 최후 릴레이. | 궤도 투입 |
| JA | Tokenfront: 軌道信号戦 | 4つのAIコア。4,000のライブトークン。最後のリレーは1つ。 | 軌道へ展開 |
| ZH | Tokenfront：轨道信号战 | 四个AI核心，4,000个活跃代币，最后一座中继站。 | 部署至轨道 |

App title, web title/description, PWA manifest, Android launcher labels, package description, README, and current audit headings use the new title. The canonical Cloudflare Pages target becomes `tokenfront-orbital-war`; the previous `tokenfront-ai-arena` deployment is not deleted.

## Code boundaries and data flow

- `Faction` becomes domain-neutral internally: `amethyst`, `cobalt`, `volt`, and `prism`. This removes third-party names from debug logs and future replay payloads.
- `FactionVisual` continues to own glyph, color, atlas order, and stable display name.
- A localized faction-profile mapping owns protocol and identity copy. It does not own combat statistics.
- The lobby consumes the selected faction, its visual profile, and localization values; deploy continues to pass the same enum into the unchanged simulation.
- ARB files remain the source of localized UI copy; generated localization Dart files are regenerated, never hand-maintained.
- Existing local preferences and economy state do not serialize faction identifiers, so the neutral enum migration requires no user-data migration. Debug combat-log schema moves from version 1 to version 2 because exported faction identifiers change.

## Failure behavior

- Missing Blender key art continues to fall back to the existing dark tactical backdrop.
- A missing localization key fails at generation/build time rather than silently falling back to a wrong language.
- Orbital decoration is non-interactive and wrapped to avoid intercepting pointers or semantics.
- Narrow and short screens may reduce decorative detail, but faction selection and deploy remain available.

## Test and verification design

Implementation follows red-green-refactor:

1. Add a failing domain test requiring neutral `Faction` identifiers and debug-log schema 2.
2. Add failing localization/widget tests for the new title, mission line, faction protocols, CTA, and absence of real AI-brand names across all four locales.
3. Add a failing responsive widget test proving the revised lobby has no overflow and retains all actions on 320×568 and landscape mobile surfaces.
4. Implement the minimum domain, localization, lobby, metadata, and visual changes needed to pass.
5. Run localization generation, formatter, focused tests, the complete Flutter test suite, static analysis, and release web build.
6. Inspect desktop and mobile browser screenshots, including keyboard focus and reduced-motion behavior.
7. Deploy the verified release build to the new Cloudflare Pages project and confirm HTTP 200 plus local/deployed artifact hashes.

## Out of scope

- Third-party AI trademarks, logos, voices, or character likenesses
- Cryptocurrency, blockchain, token sales, wallets, or speculative economy
- Online multiplayer or cloud AI inference
- New faction abilities or asymmetric balance
- New capture-point rules or starship physics
- Store submission, live advertising credentials, or purchases

## Acceptance criteria

- A first-time player can describe the premise as “four fictional AI cores burning a fixed supply of 4,000 simulated AI tokens for the last orbital relay” from the lobby alone.
- The HUD's faction counts and result survivor counts remain the single source of truth for live-token supply; no duplicate economy state exists.
- No user-visible surface or newly exported debug payload contains Claude, Gemini, ChatGPT, Grok, Codex, or OpenAI.
- All four locales express the same premise and preserve a usable narrow-screen layout.
- Existing combat behavior and the enlarged mobile controls remain regression-green.
- The production web build uses the new title and is reachable from the new Cloudflare Pages URL.

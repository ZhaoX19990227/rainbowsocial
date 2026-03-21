# XiongHou Flirty Action Motion Guidance

## Character Direction

- `Aru`:
  proactive, mischievous, chestnut wolf-cut hair, warm bomber silhouette, sharper smirk, slightly forward center of gravity.
- `Noel`:
  shy, reactive, ash-blue soft layered hair, knit-cardigan silhouette, softer smile line, shoulders naturally tucked in.

## Scene Beats

| Action | Keyframe Style | Loop Note | Best Format |
| --- | --- | --- | --- |
| Poke the butt | Wind-up, fast poke, double bounce recoil | Short three-beat loop with elastic recoil | `Rive` for body motion + `sprite sheet` for impact burst |
| Tug the sleeve | Reach, tiny hold, soft pull-back | Keep fabric sway and shoulder tremble alive | `Rive` + small `sprite sheet` for cloth deformation |
| Pat the head | Palm drop, compress, release, linger | Gentle hold matters more than impact | `Rive` + optional `Lottie` sparkles |
| Hook the finger | Near-touch, miss, second approach, hook, breathe | Hold on the linked fingers with micro sway | `Rive` |
| Lean closer | Slow body push, eye contact hover, retreat | Long hover loop, minimal repositioning | `Rive` + optional atmosphere `Lottie` |
| Sneak a glance | Quick side look, micro eye-contact, flustered retreat | Irregular timing sells realism | `Rive` + tiny `sprite sheet` for glance streak |
| Brush the shoulder | Parallel drift, soft brush, delayed turn-back | The turn-back is the payoff beat | `Rive` + `APNG` or `sprite sheet` for shoulder trail |
| Naughty smile | Lift eyes, one-sided smile, slow blink | Long idle with short expression burst | `Rive`, fallback `APNG` |

## Flutter Delivery Recommendations

- Use `Rive` for the two character rigs and any scene where pose readability matters.
- Use `sprite sheet` for tiny impact accents, poke bursts, and quick directional streaks.
- Use `Lottie` only for lightweight atmosphere layers such as dust, sparkles, and soft breathing halos.
- Use `APNG` only as a fallback when a scene is mostly illustration-driven and the team needs quick asset export over runtime control.
- Use `GIF` only for previews in docs or production planning, not for in-app playback.
- Keep the picker, message card, and overlay chrome as static Flutter UI with gradients, blur, and custom paint.

## Practical Flutter Stack

- Primary runtime scene format: `Rive`
- Secondary accent format: `sprite sheet`
- Atmosphere layer: `Lottie`
- Static UI: native Flutter widgets and `CustomPainter`

This combination keeps memory predictable, supports responsive layout, and preserves the premium, cinematic feel without turning the feature into a heavy video player.

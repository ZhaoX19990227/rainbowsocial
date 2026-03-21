# XiongHou Flirty Action Production Guide

## Finalized Chibi Pair

### Bear Boy

- Role: proactive, mischievous, warm and grounded, always the one who creates the first spark.
- Face and silhouette: rounder face, light beard or soft stubble, broad shoulders, soft “bear” energy, still chibi-cute.
- Styling: modern Chengdu city-boy feeling, white T-shirt, black shorts, sneakers, restrained palette.
- Expression system: crooked grin, relaxed confidence, teasing half-lidded eyes, readable smirk, softened warm smile.

### Monkey Boy

- Role: shy, reactive, agile, emotionally readable, the one whose reactions make the scene land.
- Face and silhouette: slimmer jawline, cleaner face, lighter frame, quicker posture changes, “monkey” energy without feeling childish.
- Styling: same white T-shirt, black shorts, sneakers, slightly leaner proportion and sharper responsiveness.
- Expression system: startled blink, flustered eyes, shy smile, breath-caught pause, caught-looking glance.

### Pair Contrast

- Bear Boy drives motion; Monkey Boy confirms emotion.
- Bear Boy’s poses start from intent; Monkey Boy’s poses start from reaction.
- Bear Boy reads broad and steady; Monkey Boy reads inward, agile, and more reactive.
- Together they form a recognizable XiongHou signature pair instead of generic “two cute boys”.

## Performance Rules

- Anticipation must be readable before contact.
- Impact must be short and specific, never mushy.
- Reaction must continue after impact so the emotion has somewhere to land.
- Hair, sleeves, shoulders, and gaze should always lag a fraction behind the main body motion.
- The best loop point is usually after the emotional payoff, not at the literal end of a move.

## Priority Scene Refinements

### Poke the Butt

- Anticipation: Bear Boy shifts weight forward with a crooked grin and tiny shoulder dip before the finger extends.
- Impact moment: the poke itself should be fast and tiny; the comedy comes from Monkey Boy’s delayed, exaggerated bounce.
- Body reaction: Monkey Boy’s hips pop first, then shoulders, then head. The bounce should happen in two diminishing hits.
- Face reaction: Monkey Boy flashes from neutral to shocked to embarrassed in under half a second.
- Detail: add a hair flick and a tiny impact burst where the poke lands.
- Loop rhythm: hold the mischievous wind-up briefly, hit fast, let the bounce overshoot twice, then settle into embarrassed recovery.
- At-a-glance read: playful attack followed by dramatic reactive recoil.

### Tug the Sleeve

- Anticipation: Monkey Boy should look away first, then reach, making the reach feel brave rather than casual.
- Impact moment: the moment is not the pull itself; it is the sleeve tension becoming visible.
- Body reaction: Monkey Boy leans back slightly after the tug, as if unsure whether to keep holding on.
- Face reaction: eyes down first, then a quick upward check to see whether Bear Boy noticed.
- Detail: cloth tension lines, tiny cuff stretch, and a soft shoulder tremble.
- Loop rhythm: reach, touch, tiny pull, hold, almost release, keep holding.
- At-a-glance read: sticky softness and emotional hesitation.

### Hook the Finger

- Anticipation: both hands must hesitate before contact so the intimacy reads instantly.
- Impact moment: first approach misses on purpose, second approach lands and hooks.
- Body reaction: once linked, both bodies become quieter; only fingers and breathing keep moving.
- Face reaction: Bear Boy knows exactly what happened, Monkey Boy realizes it half a beat later.
- Detail: subtle eye-contact line, micro sway in the locked fingers, almost no extra flourish.
- Loop rhythm: approach, pause, second approach, hook, hold.
- At-a-glance read: private, intimate, memorable.

### Lean Closer

- Anticipation: Bear Boy lowers the shoulder line and enters Monkey Boy’s space before the actual forward move finishes.
- Impact moment: the real impact is eye contact at the nearest point, not the translation itself.
- Body reaction: Monkey Boy’s body retreats a fraction while the eyes stay locked too long.
- Face reaction: Monkey Boy should look breath-caught, not simply surprised.
- Detail: slight hair drift, breath halo, tiny pause before retreat.
- Loop rhythm: slow approach, suspended hover, controlled release.
- At-a-glance read: tension from proximity, not physical contact.

## Picker Direction

- The picker should read like a hidden mood drawer.
- Each card needs a hero still that feels poster-like, not just a thumbnail.
- Mood tag comes first as the hook, action name second, preview copy third.
- Group panels should have their own tint personality:
  tease uses warm apricot tension,
  closer uses intimate amber-wine,
  cute uses soft blue-lilac calm,
  stir uses cooler blue-steel afterglow.
- The CTA feeling should come from contrast and staging, not from explicit buttons.

## Fullscreen Stage Direction

- Keep the stage centered and sparse.
- The duo is always the brightest object in the frame.
- Atmosphere should behave like soft floating dust, not obvious particles.
- Copy should never compete with the acting; title plus one emotional line is enough.
- The XiongHou duo should feel like a signature micro-scene, almost like a collectible interaction clip.

## Flutter Asset System

| Action | Static Cover Frame | Mini Preview | Fullscreen Main Animation | Cover Format | Preview Format | Main Format | Effects Format |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Poke the butt | Bear Boy side-smirk with finger nearly landing; Monkey Boy still unsuspecting | 1.2s wind-up, poke, double bounce | 2.5s full performance with exaggerated recoil and embarrassed recovery | `png` or `webp` | `Rive` | `Rive` | `sprite sheet` |
| Tug the sleeve | Monkey Boy lightly pinching Bear Boy’s sleeve while looking down | 1.4s reach, cloth tension, small pull | 2.8s with fabric stretch, shoulder tremble, hesitant hold | `png` or `webp` | `Rive` | `Rive` | `sprite sheet` |
| Pat the head | Palm resting at the top of Monkey Boy’s head, expression softening | 1.3s drop, pat, linger | 2.4s with hair compression and slow comfort reaction | `png` or `webp` | `Rive` | `Rive` | `Lottie` |
| Hook the finger | Fingers almost touching, eye contact already present | 1.5s first miss, second hook, hold | 3.0s with hesitation, contact, breathing hold | `png` or `webp` | `Rive` | `Rive` | `Lottie` |
| Lean closer | Two faces suspended at the closest distance | 1.4s slow approach and hover | 2.8s with eye-lock pause and gentle retreat | `png` or `webp` | `Rive` | `Rive` | `Lottie` |
| Sneak a glance | Monkey Boy looking sideways before being caught | 1.1s glance, caught, retreat | 2.2s with expression correction and tiny panic | `png` or `webp` | `Rive` | `Rive` | `sprite sheet` |
| Brush the shoulder | Shoulder contact just finished; both turning back | 1.4s cross and delayed look-back | 2.6s with light trail and held after-feel | `png` or `webp` | `Rive` | `Rive` | `APNG` |
| Naughty smile | Bear Boy’s smile lifting; Monkey Boy already flushing | 1.1s look-up, smirk, blink | 2.2s with held gaze and reaction timing | `png` or `webp` | `Rive` | `Rive` | `APNG` |

## Format Guidance

- `Rive`: default for all character animation. Best choice for pose clarity, eye direction, finger motion, and responsive scaling in Flutter.
- `Lottie`: use only for soft atmosphere layers like sparkle dust, breath halos, and subtle emotional glows.
- `sprite sheet`: use for tiny high-speed accents like poke bursts, cloth tension streaks, glance streaks, and brief impact marks.
- `APNG`: use only for painterly or trail-like effects where vector motion is unnecessary.
- `GIF`: never ship as the in-app playback format. Use only for reviews, documentation, or QA sharing.

## Practical Delivery Stack

- Static UI chrome: native Flutter widgets plus `CustomPainter`.
- Character rigs: `Rive`.
- Mini previews inside picker/message card: `Rive`, with simplified state machines.
- Fullscreen hero scenes: `Rive` primary animation plus optional `Lottie` atmosphere overlay.
- Fast effect overlays: `sprite sheet`, with `APNG` only for a few painterly trails if needed.

This is the most practical stack for Flutter mobile because it preserves the premium cinematic feel, stays scalable across screen sizes, and avoids turning the feature into a heavy video-based subsystem.

# After Dark "Flying Toasters" — Research Notes

Research compiled to drive a faithful recreation. Sources listed at the bottom.

## Origin & history

- **Publisher:** Berkeley Systems, as a module of the **After Dark** screensaver suite.
- **Debut:** Flying Toasters shipped with After Dark for the Macintosh (the franchise's
  flagship module). It became the icon of the whole product and spawned merchandise
  ("The 51st Flying Toaster Squadron — On a mission to save your screen!").
- **Designer:** Engineer **Jack Eastman** said he imagined wings on a kitchen toaster
  during a late‑night coding session.
- **The Jefferson Airplane connection:** the winged toasters strongly resemble the cover
  of Jefferson Airplane's 1973 album *Thirty Seconds Over Winterland*. The band sued in
  1994; the case was dismissed because the cover art had not been registered as a
  trademark before After Dark shipped.
- Later variants: **Flying Toasters Pro** (added music — Wagner + an anthem with optional
  karaoke lyrics), **Flying Toasters!**, and a 10th‑anniversary **Toaster 2K** with
  futuristic/mecha designs.

## Visual design (from the original sprite art)

The original sprites are **64×64 px**. The toaster sheet is **256×64** = **4 frames** of
wing animation laid horizontally. Toast is a single **64×64** sprite (a few darkness
variants existed).

**Toaster** — a 1940s‑style **chrome two‑slot toaster** seen in 3/4 view, nose pointed
toward the lower‑left (its direction of travel), with a **white feathered bird wing** on
the near side that flaps. Reading the reference palette:

- Chrome highlight `#E8E8E8`, mid chrome `#A8A8A8`, chrome shadow `#5A5A5A`
- Olive/grey body base `#6E6E58`, darker base shadow `#454536`
- Two slots on the top face render as **dark reddish‑brown** strips `#7A2E1E` → `#A84B2A`
- Wing: white `#FFFFFF`, feather shadow `#B7B7C2`, dark outline `#303030`
- Everything is keylined in near‑black `#1A1A1A`

**Toast** — a golden slice in the same 3/4 view:

- Top crumb surface `#E8C57A`, toasted center `#C8923C`, lower‑left highlight `#F0D9A0`
- Crust edges (front/side) `#A85E22`, deep crust `#6E3A12`

**Background** — solid **black**.

## Motion & cadence

- **Direction:** everything flies **from the top‑right toward the bottom‑left**, on a
  roughly **45° diagonal** (CSS reconstruction uses `translate(-1600px, 1600px)`).
- **Parallax speed tiers:** three base speeds — the field is traversed in about
  **10 s (fast) / 16 s (mid) / 24 s (common/slow)**. Slower = visually farther away.
  Closer/faster toasters are also drawn larger → a depth/parallax effect (the original
  used several discrete sizes).
- **Wing flap:** the 4 frames are stepped (not interpolated): `steps(4)` over ~**0.2 s**
  per sweep, played **alternating** (1‑2‑3‑4‑3‑2‑1…), so a full up→down→up flap is
  ~**0.4 s** (~2.5 flaps/sec). Each toaster's flap **phase and direction are randomized**
  so they beat out of sync.
- **Toast** flies on the same speed tiers but **does not flap**.
- **Density / ratio:** a full‑screen reference shows ≈ **37 toasters : 12 toast ≈ 3 : 1**.

## Options in the original

- The Flying Toasters module exposed a **toast "darkness" slider** (how toasted the bread
  looks). After Dark modules generally also offered density/number and speed‑style
  controls. Flying Toasters Pro added music selection.

### Options implemented in this recreation (ScreenSaver configure sheet)

- **Number of toasters** (density)
- **Toast amount** (ratio of toast to toasters)
- **Speed** (overall multiplier over the 10/16/24 s tiers)
- **Toast darkness** (faithful to the original slider)
- **Wing flap** style: authentic 4‑step vs. smooth
- Background is black (classic); optional faint stars off by default.

## Implementation decisions (faithful + Retina‑crisp)

- The original was 64‑px pixel art. For **Retina crispness** the toaster and toast are
  **redrawn as clean vector art in Core Graphics**, matched to the reference palette and
  the 4 wing positions, then cached to high‑resolution bitmaps and blitted per sprite.
- Cadence numbers above are reproduced directly: 45° travel, 10/16/24 s tiers scaled to
  the screen so timing is resolution‑independent, 4‑step ~0.4 s flap with randomized
  phase, 3:1 toaster:toast ratio, depth‑correlated size+speed, black background.

## Sources

- After Dark (software) — Wikipedia: https://en.wikipedia.org/wiki/After_Dark_(software)
- Bryan Braun, "How I rebuilt Flying Toasters using only CSS animations":
  https://www.bryanbraun.com/2014/03/15/how-i-rebuilt-flying-toasters-using-only-css-animations/
- Bryan Braun, After Dark in CSS (live + sprite sheet):
  https://www.bryanbraun.com/after-dark-css/all/flying-toasters.html
- Screensavers Planet — After Dark: Flying Toasters:
  https://www.screensaversplanet.com/screensavers/after-dark-flying-toasters-1153/
- The Register, "Return of the classic screensaver Flying Toasters" (2023):
  https://www.theregister.com/2023/04/14/return_flying_toasters/

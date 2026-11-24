# trade-astro: one-page demo template for trades

One Astro template for **painter, joiner/carpenter, landscaper/gardener, roofer and garage** demos.
All client content lives in ONE data file: `clients/<NN-slug>/data/client.json` (+ its photos in `data/img/`).
Languages: `"lang": "en"` or `"fr"` (UI labels switch automatically).

## New demo in 4 steps
1. **Data**: create `/workspace/prospection-intl/clients/<NN-slug>/data/client.json` (copy one of the existing
   ones, e.g. `clients/10-olympian-landscaping/data/client.json` or `clients/22-garage-du-stand/data/client.json`)
   and put their real photos in `data/img/`. Only facts from their site / public listings. If a fact is not
   confirmed, leave it out. No photo of theirs? Use `"hero": "type"` (textured hero + rating card, no photos).
2. **Build + QA**: `tools/new-demo.sh ../../clients/<NN-slug> <demo-number>`
   (copies the template into `clients/<NN-slug>/site-astro`, builds for `/site-demo-<number>/`,
   fails if dist contains placeholder/confirm/lorem/unsplash/todo, then screenshots 390/1440 px,
   axe-core and Lighthouse mobile into `site-astro/qa/`).
3. **Review** `site-astro/qa/home-390.png`, `home-1440.png`, `axe.txt`, `lighthouse.txt`.
4. **Deploy** (only with Thabiau's OK): `tools/new-demo.sh ../../clients/<NN-slug> <demo-number> --deploy`
   creates the public repo `tibononoX/site-demo-<number>`, pushes, enables Pages (GitHub Actions),
   waits for the run and checks HTTP 200 + noindex. It stops if `gh` is not logged in and refuses
   to touch an existing repo unless you pass `--update` to `tools/deploy-demo.sh`.

## client.json fields
| field | notes |
|---|---|
| `lang` | `en` / `fr` |
| `name`, `initial` | business name; favicon letter |
| `trade` | `painter` `joiner` `landscaper` `roofer` `garage` (sets the icon) |
| `tradeLabel` | short line under the name (title tag, footer) |
| `theme.mode` | `light` / `dark` |
| `theme.accent` | ONE brand colour (hex). Accessible text/button variants are derived automatically |
| `theme.display` | `serif` (Fraunces) / `sans` (Inter) for headings |
| `theme.hero` | `split` (text + photo) / `type` (no photo: texture + rating/contact card) |
| `hero` | `eyebrow`, `title`, `titleEm` (italic accent part), `lead`, `image`, `alt` |
| `rating` | `{score: "4.8", count: 18, source: "Google"}` exactly as on Google, or omit |
| `intro` | optional: `title`, `paragraphs[]`, `facts[]`, optional `image`/`alt` |
| `services` | `title`, `lead?`, `items[{title, text, bullets?}]` (3, 4 or 6 items lay out best) |
| `band` | optional wide photo `{image, alt}` |
| `gallery` | optional `title`, `lead?`, `items[{image, alt, caption?}]` (3 or 6 photos; the first is featured) |
| `steps` | exactly 3 `{title, text}` |
| `contact` | `title`, `lead`, `phones[{label, display, tel}]` (tel in E.164), `email`, `address[]`, `hours?[]` |
| `footer.note` | optional (e.g. legal name) |

## Built in
Mobile-first, sticky header with click-to-call, mobile call/email bar, `<meta name="robots" content="noindex, nofollow">`
+ `robots.txt` `Disallow: /`, AVIF/WebP responsive images, preloaded self-hosted fonts, scroll reveal only when
`prefers-reduced-motion` allows it, WCAG AA contrast computed from the accent.
The wood/grain texture (`src/assets/texture.jpg`) is generated procedurally (no licence or credit needed).

## Files
- `src/pages/index.astro`: the page; `src/styles/global.css`: design; `src/lib/client.ts`: data loading, colours, EN/FR labels; `src/lib/icons.ts`: icons
- `tools/make-site.sh`, `tools/qa.sh` (+ `shots_axe.py`), `tools/deploy-demo.sh`, `tools/new-demo.sh`
- `.github/workflows/deploy.yml`: Astro build + Pages deploy (base path = repo name)

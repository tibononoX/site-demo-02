"""Screenshots at 390 and 1440 px + axe-core + horizontal overflow check. usage: shots_axe.py URL OUTDIR"""
import asyncio, sys, json, glob
from playwright.async_api import async_playwright
URL, OUT = sys.argv[1], sys.argv[2]
AXE = (glob.glob('/home/box/.local/lib/node_modules/lighthouse/node_modules/axe-core/axe.min.js') + glob.glob('/usr/**/axe-core/axe.min.js', recursive=True))[0]
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        lines = []
        for w in (390, 1440):
            for rm in ('no-preference', 'reduce'):
                pg = await b.new_page(viewport={'width': w, 'height': 900}, reduced_motion=rm)
                r = await pg.goto(URL)
                await pg.evaluate("document.querySelectorAll('img[loading=lazy]').forEach(i=>i.loading='eager')")
                await pg.evaluate('(async()=>{for(let y=0;y<document.body.scrollHeight;y+=500){scrollTo(0,y);await new Promise(r=>setTimeout(r,80))}scrollTo(0,0)})()')
                await pg.wait_for_load_state('networkidle')
                await pg.evaluate('Promise.all([...document.images].map(i=>i.decode().catch(()=>0)))')
                await pg.wait_for_timeout(1200)
                sw = await pg.evaluate('document.documentElement.scrollWidth')
                await pg.add_script_tag(path=AXE)
                res = await pg.evaluate("axe.run(document,{runOnly:['wcag2a','wcag2aa','wcag21a','wcag21aa','best-practice']})")
                v = res['violations']
                lines.append(f"{w}px motion={rm}: HTTP {r.status}, scrollWidth {sw} {'OK' if sw <= w else 'OVERFLOW'}, axe {len(v)} violations, {len(res['passes'])} passes")
                for x in v: lines.append(f"   - {x['id']}: {x['help']} -> {[n['target'] for n in x['nodes']][:4]}")
                if rm == 'no-preference':
                    await pg.add_style_tag(content='.mbar{position:absolute!important}')
                    H = await pg.evaluate('document.documentElement.scrollHeight')
                    await pg.set_viewport_size({'width': w, 'height': H}); await pg.wait_for_timeout(600)
                    await pg.screenshot(path=f'{OUT}/home-{w}.png')
                    await pg.set_viewport_size({'width': w, 'height': 900 if w > 500 else 844}); await pg.evaluate('scrollTo(0,0)'); await pg.wait_for_timeout(300)
                    await pg.screenshot(path=f'{OUT}/fold-{w}.png')
                await pg.close()
        await b.close()
        open(f'{OUT}/axe.txt', 'w').write('\n'.join(lines) + '\n'); print('\n'.join(lines))
asyncio.run(main())

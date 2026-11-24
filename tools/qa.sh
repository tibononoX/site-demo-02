#!/usr/bin/env bash
# Local QA of a built client site: serves dist under /site-demo-NN/, then screenshots (390/1440),
# axe-core, overflow check and Lighthouse mobile. Results in <site>/qa/.
# usage: tools/qa.sh <site-astro dir> <NN> [port]
set -euo pipefail
TPL="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$(cd "$1" && pwd)"; NN="$2"; PORT="${3:-48$NN}"
ROOT=$(mktemp -d); ln -s "$SITE/dist" "$ROOT/site-demo-$NN"
mkdir -p "$SITE/qa"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT" >/dev/null 2>&1 & SRV=$!
trap 'kill $SRV 2>/dev/null; rm -rf "$ROOT"' EXIT
sleep 1
URL="http://127.0.0.1:$PORT/site-demo-$NN/"
python3 "$TPL/tools/shots_axe.py" "$URL" "$SITE/qa"
lighthouse "$URL" --quiet --chrome-flags="--headless=new --no-sandbox" --form-factor=mobile \
  --only-categories=performance,accessibility,best-practices,seo --output=json --output=html \
  --output-path="$SITE/qa/lighthouse-mobile" >/dev/null 2>&1 || true
python3 - "$SITE/qa/lighthouse-mobile.report.json" <<'P' | tee "$SITE/qa/lighthouse.txt"
import json,sys
r=json.load(open(sys.argv[1]))
print(' '.join(f"{k}={round(v['score']*100) if v['score'] is not None else 'NA'}" for k,v in r['categories'].items()))
for k in ('largest-contentful-paint','cumulative-layout-shift','total-blocking-time'): print(k, r['audits'][k]['displayValue'])
P

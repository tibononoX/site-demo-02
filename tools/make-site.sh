#!/usr/bin/env bash
# Create/refresh a client site from the template + that client's data folder, then build it.
# usage: tools/make-site.sh <client-dir> <NN>
#   <client-dir> contains data/client.json and data/img/*  (e.g. ../../clients/02-garden-guide)
#   NN = demo number -> repo site-demo-NN, URL https://tibononox.github.io/site-demo-NN/
set -euo pipefail
TPL="$(cd "$(dirname "$0")/.." && pwd)"
CL="$(cd "$1" && pwd)"; NN="$2"
SITE="$CL/site-astro"
[ -f "$CL/data/client.json" ] || { echo "missing $CL/data/client.json"; exit 1; }
mkdir -p "$SITE"
# copy template (code only) over the site, then replace its data folder with the client's
rm -rf "$SITE/src" "$SITE/public"
tar -C "$TPL" --exclude=./node_modules --exclude=./dist --exclude=./.astro --exclude=./.git --exclude=./qa \
  --exclude=./src/data --exclude=./clients-example -cf - . | tar -C "$SITE" -xf -
mkdir -p "$SITE/src/data"
cp -a "$CL/data/." "$SITE/src/data/"
cd "$SITE"
[ -d node_modules ] || { if [ -d "$TPL/node_modules" ]; then cp -a "$TPL/node_modules" .; else npm ci --no-audit --no-fund; fi; }
SITE_URL=https://tibononox.github.io BASE_PATH=/site-demo-$NN/ npx astro build
# hygiene: no internal labels may ship
if grep -riIl -E 'placeholder|confirm|lorem|unsplash|todo' dist; then echo "FORBIDDEN WORD FOUND IN dist"; exit 2; fi
echo "built $SITE/dist for /site-demo-$NN/"

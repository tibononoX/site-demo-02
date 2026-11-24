#!/usr/bin/env bash
# Create the public repo tibononoX/site-demo-NN, push the built client site, enable GitHub Pages
# (build type: GitHub Actions), wait for the deploy, then check HTTP 200 + noindex.
# usage: tools/deploy-demo.sh <site-astro dir> <NN> [--update]
#   --update : the repo already exists and is one of OUR demo repos; just push a new commit.
# Never touches any other repo. Never starts a gh login.
set -euo pipefail
SITE="$(cd "$1" && pwd)"; NN="$2"; MODE="${3:-}"
OWNER=tibononoX; REPO="site-demo-$NN"; URL="https://tibononox.github.io/$REPO/"
gh auth status >/dev/null 2>&1 || { echo "gh is NOT authenticated: stop (do not log in from here)"; exit 3; }
[[ "$NN" =~ ^[0-9]{2}$ ]] || { echo "NN must be two digits"; exit 1; }
cd "$SITE"
grep -q 'noindex' dist/index.html && grep -q 'Disallow: /' public/robots.txt || { echo "noindex/robots missing: abort"; exit 1; }
if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  [ "$MODE" = "--update" ] || { echo "$OWNER/$REPO already exists: rerun with --update if it is our demo repo"; exit 4; }
else
  gh repo create "$OWNER/$REPO" --public --description "Design preview (noindex)" >/dev/null
fi
[ -d .git ] || { git init -q -b main; git remote add origin "https://github.com/$OWNER/$REPO.git"; }
git add -A && (git diff --cached --quiet || git commit -qm "Demo site $REPO")
git push -q -u origin main
# Pages via Actions (idempotent)
gh api -X POST "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 || gh api -X PUT "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 || true
sleep 5
RUN=$(gh run list -R "$OWNER/$REPO" -L 1 --json databaseId,status,conclusion -q '.[0].databaseId' || true)
if [ -z "$RUN" ]; then gh workflow run deploy.yml -R "$OWNER/$REPO"; sleep 8; RUN=$(gh run list -R "$OWNER/$REPO" -L 1 --json databaseId -q '.[0].databaseId'); fi
gh run watch "$RUN" -R "$OWNER/$REPO" --exit-status >/dev/null 2>&1 || {
  echo "first run failed (often: Pages enabled after the push) -> rerunning"; gh run rerun "$RUN" -R "$OWNER/$REPO" >/dev/null; sleep 8
  gh run watch "$RUN" -R "$OWNER/$REPO" --exit-status >/dev/null; }
for i in $(seq 1 20); do
  code=$(curl -s -o /tmp/$REPO.html -w '%{http_code}' "$URL"); [ "$code" = 200 ] && break; sleep 6; done
rob=$(curl -s "${URL}robots.txt" | tr '\n' ' ')
echo "$URL HTTP $code | meta: $(grep -o '<meta name="robots"[^>]*>' /tmp/$REPO.html) | robots.txt: $rob"
[ "$code" = 200 ] && grep -q 'noindex' /tmp/$REPO.html

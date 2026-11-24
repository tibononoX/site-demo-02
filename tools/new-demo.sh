#!/usr/bin/env bash
# One command per new demo: data folder -> site -> QA -> (optional) deploy.
# usage: tools/new-demo.sh <client-dir> <NN> [--deploy]
set -euo pipefail
T="$(cd "$(dirname "$0")" && pwd)"
"$T/make-site.sh" "$1" "$2"
"$T/qa.sh" "$1/site-astro" "$2"
if [ "${3:-}" = "--deploy" ]; then "$T/deploy-demo.sh" "$1/site-astro" "$2"; else echo "QA done. Review $1/site-astro/qa/ then rerun with --deploy."; fi

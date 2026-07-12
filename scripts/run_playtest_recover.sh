#!/usr/bin/env bash
exec "$(cd "$(dirname "$0")" && pwd)/run_playtest.sh" recover "$@"

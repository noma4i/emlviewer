#!/bin/bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
(cd "$ROOT" && /usr/bin/swift Scripts/appstore/compose.swift)

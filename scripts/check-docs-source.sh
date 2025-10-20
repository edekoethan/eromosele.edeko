#!/usr/bin/env bash
if [ -d docs ]; then
  echo "WARNING: docs/ exists — GitHub Pages may be serving it instead of the Actions artifact"
fi

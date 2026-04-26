#!/usr/bin/env bash
# Open CopyQ history menu; fallback to toggle window if menu fails.

copyq menu >/dev/null 2>&1 || copyq toggle

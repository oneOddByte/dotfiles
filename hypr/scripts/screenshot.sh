#!/usr/bin/env bash
# Region screenshot -> swappy editor. Single key workflow.

grim -g "$(slurp)" - | swappy -f -

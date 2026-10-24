#!/bin/sh
# Fail when a display setting or an extracted metadata field never reaches the popup,
# so a user who turns a setting on always sees its data.
cd "$(dirname "$0")/../FinderHover" || exit 1
view=UI/Windows/HoverContentView.swift
missing=0

for setting in $(grep -oE '@Published var show[A-Za-z0-9]+' Settings/AppSettings.swift | sed 's/@Published var //' | sort -u); do
    grep -q "settings\.$setting\b" "$view" || { echo "setting not rendered: $setting"; missing=1; }
done

# Byte counts and dates may be rendered through the model's formatted* helpers.
for model in Core/Models/*.swift; do
    awk '/^struct /{s=$2} /^ *let [a-zA-Z]+:/{sub(":","",$2); print s" "$2}' "$model"
done | while read -r type field; do
    capitalized="$(printf '%s' "$field" | cut -c1 | tr a-z A-Z)$(printf '%s' "$field" | cut -c2-)"
    grep -qE "\.$field\b|\.formatted$capitalized\b" "$view" || { echo "field not rendered: $type.$field"; exit 1; }
done || missing=1

[ "$missing" -eq 0 ] && echo "PASS: every display setting and metadata field is rendered."
exit "$missing"

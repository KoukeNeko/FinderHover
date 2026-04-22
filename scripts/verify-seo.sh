#!/usr/bin/env bash
# verify-seo.sh — Static checks on the built website/ directory.
#
# Runs without any network or browser. Exits non-zero on any failure.
#
# Checks:
#   1. Every page (6) × every language (3) exists and contains:
#      canonical, 3 hreflang + x-default, og:title/description/url/image,
#      twitter:card, robots meta, and the expected <html lang=".."> attr.
#   2. The canonical/og:url values point at the page's own URL
#      (catches lang-substitution bugs).
#   3. sitemap.xml exists, is well-formed XML, and lists all 18 URLs.
#   4. robots.txt exists and references the sitemap.
#   5. og-image.png exists and is exactly 1200×630.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$REPO_ROOT/website"
SITE_ORIGIN="https://finderhover.app.koukeneko.cafe"

PAGES=(index download docs formats changelog license)
LANGS=(zh-Hant en ja)

pass_count=0
fail_count=0
fail_messages=()

record_pass() {
    pass_count=$((pass_count + 1))
}

record_fail() {
    fail_count=$((fail_count + 1))
    fail_messages+=("$1")
    printf '  \033[31mFAIL\033[0m %s\n' "$1"
}

expect_contains() {
    local file="$1" needle="$2" label="$3"
    if grep -q -F -- "$needle" "$file"; then
        record_pass
    else
        record_fail "$label :: missing in $file :: $needle"
    fi
}

page_url() {
    local lang="$1" page="$2"
    local prefix=""
    [[ "$lang" != "zh-Hant" ]] && prefix="/$lang"
    if [[ "$page" == "index" ]]; then
        echo "${SITE_ORIGIN}${prefix}/"
    else
        echo "${SITE_ORIGIN}${prefix}/${page}.html"
    fi
}

page_file() {
    local lang="$1" page="$2"
    if [[ "$lang" == "zh-Hant" ]]; then
        echo "$SITE_DIR/${page}.html"
    else
        echo "$SITE_DIR/${lang}/${page}.html"
    fi
}

check_page() {
    local lang="$1" page="$2"
    local file
    file="$(page_file "$lang" "$page")"

    if [[ ! -f "$file" ]]; then
        record_fail "page missing :: $file"
        return
    fi

    local self_url
    self_url="$(page_url "$lang" "$page")"

    expect_contains "$file" "<html lang=\"$lang\"" "html-lang[$lang/$page]"
    expect_contains "$file" "rel=\"canonical\" href=\"$self_url\"" "canonical[$lang/$page]"
    expect_contains "$file" "hreflang=\"zh-Hant\"" "hreflang-zh-Hant[$lang/$page]"
    expect_contains "$file" "hreflang=\"en\"" "hreflang-en[$lang/$page]"
    expect_contains "$file" "hreflang=\"ja\"" "hreflang-ja[$lang/$page]"
    expect_contains "$file" "hreflang=\"x-default\"" "hreflang-x-default[$lang/$page]"
    expect_contains "$file" 'name="robots"' "meta-robots[$lang/$page]"
    expect_contains "$file" 'property="og:type"' "og-type[$lang/$page]"
    expect_contains "$file" 'property="og:title"' "og-title[$lang/$page]"
    expect_contains "$file" 'property="og:description"' "og-description[$lang/$page]"
    expect_contains "$file" "property=\"og:url\" content=\"$self_url\"" "og-url[$lang/$page]"
    expect_contains "$file" "/assets/og-image.png" "og-image[$lang/$page]"
    expect_contains "$file" 'name="twitter:card" content="summary_large_image"' "twitter-card[$lang/$page]"
}

echo "==> Checking per-page SEO tags"
for lang in "${LANGS[@]}"; do
    for page in "${PAGES[@]}"; do
        check_page "$lang" "$page"
    done
done

echo "==> Checking sitemap.xml"
SITEMAP="$SITE_DIR/sitemap.xml"
if [[ ! -f "$SITEMAP" ]]; then
    record_fail "sitemap.xml missing"
else
    if xmllint --noout "$SITEMAP" 2>/dev/null; then
        record_pass
    else
        record_fail "sitemap.xml is not well-formed XML"
    fi
    for lang in "${LANGS[@]}"; do
        for page in "${PAGES[@]}"; do
            url="$(page_url "$lang" "$page")"
            expect_contains "$SITEMAP" "<loc>$url</loc>" "sitemap-loc[$lang/$page]"
        done
    done
fi

echo "==> Checking robots.txt"
ROBOTS="$SITE_DIR/robots.txt"
if [[ ! -f "$ROBOTS" ]]; then
    record_fail "robots.txt missing"
else
    expect_contains "$ROBOTS" "Sitemap: $SITE_ORIGIN/sitemap.xml" "robots-sitemap"
fi

echo "==> Checking OG image dimensions"
OG_IMAGE="$SITE_DIR/assets/og-image.png"
if [[ ! -f "$OG_IMAGE" ]]; then
    record_fail "og-image.png missing"
else
    dim=$(sips -g pixelWidth -g pixelHeight "$OG_IMAGE" 2>/dev/null |
        awk '/pixel(Width|Height)/ {print $2}' | paste -sd'x' -)
    if [[ "$dim" == "1200x630" ]]; then
        record_pass
    else
        record_fail "og-image.png is $dim, expected 1200x630"
    fi
fi

echo
echo "==============================="
echo "Passed: $pass_count"
echo "Failed: $fail_count"
echo "==============================="

if [[ $fail_count -gt 0 ]]; then
    echo
    echo "Failures:"
    for msg in "${fail_messages[@]}"; do
        echo "  - $msg"
    done
    exit 1
fi

echo "All SEO checks passed."

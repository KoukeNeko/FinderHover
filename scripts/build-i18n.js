#!/usr/bin/env node
/**
 * build-i18n.js — Generate /en/ and /ja/ localized copies of the website.
 *
 * Single source of truth: `website/` root (zh-Hant). Every other language
 * tree is produced from those files by rewriting titles, meta descriptions,
 * canonical URLs, hreflang self-reference, Open Graph tags, Twitter Card
 * tags, and the <html lang> attribute.
 *
 * Also writes sitemap.xml + robots.txt that cover all three language trees.
 *
 * Usage: node scripts/build-i18n.js
 */

const fs = require('node:fs');
const path = require('node:path');

const REPO_ROOT = path.resolve(__dirname, '..');
const WEBSITE_DIR = path.join(REPO_ROOT, 'website');
const LOCALES_DIR = path.join(WEBSITE_DIR, 'locales');

const SITE_ORIGIN = 'https://finderhover.app.koukeneko.cafe';

const PAGES = ['index', 'download', 'docs', 'formats', 'changelog', 'license'];
const SOURCE_LANG = 'zh-Hant';
const TARGET_LANGS = ['en', 'ja'];

const OG_LOCALES = {
    'zh-Hant': 'zh_TW',
    'en': 'en_US',
    'ja': 'ja_JP',
};

/**
 * Build the public URL for a given page + language, using the conventions
 * the SEO tags in the source HTML rely on (index → root slash).
 */
function pageUrl(lang, page) {
    const prefix = lang === SOURCE_LANG ? '' : `/${lang}`;
    if (page === 'index') return `${SITE_ORIGIN}${prefix}/`;
    return `${SITE_ORIGIN}${prefix}/${page}.html`;
}

function loadLocale(lang) {
    const filePath = path.join(LOCALES_DIR, `${lang}.json`);
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

/**
 * Resolve the localized {title, description} pair for a page, falling back
 * to the top-level meta entry when no page-specific override exists.
 */
function resolvePageMeta(locale, page) {
    const rootMeta = locale.meta || {};
    const pageMeta = (rootMeta.pages && rootMeta.pages[page]) || {};
    return {
        title: pageMeta.title || rootMeta.title,
        description: pageMeta.description || rootMeta.description,
    };
}

/**
 * Replace the inner value of an HTML attribute on a tag matched by a
 * targeting attribute. Deliberately conservative: we only rewrite the single
 * attribute value, never the surrounding markup.
 */
function replaceTagAttr(html, tagName, matchAttr, matchValue, setAttr, newValue) {
    const escapedMatchValue = matchValue.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const pattern = new RegExp(
        `(<${tagName}[^>]*\\s${matchAttr}="${escapedMatchValue}"[^>]*\\s${setAttr}=")[^"]*(")`,
        'i',
    );
    if (!pattern.test(html)) {
        throw new Error(
            `Could not locate <${tagName} ${matchAttr}="${matchValue}"> with attribute ${setAttr}`,
        );
    }
    return html.replace(pattern, `$1${escapeAttr(newValue)}$2`);
}

function escapeAttr(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

/**
 * Replace <title>...</title>. There's exactly one per document.
 */
function replaceTitle(html, newTitle) {
    const pattern = /<title>[^<]*<\/title>/i;
    if (!pattern.test(html)) throw new Error('Missing <title>');
    return html.replace(pattern, `<title>${escapeHtmlText(newTitle)}</title>`);
}

function escapeHtmlText(value) {
    return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/**
 * Rewrite a single source HTML into a target language's SEO metadata.
 * Only head-level tags are touched — body content stays identical so the
 * i18n runtime layer can localize the rest at load time.
 */
function localizeHtml(sourceHtml, lang, page, locale) {
    const { title, description } = resolvePageMeta(locale, page);
    const canonical = pageUrl(lang, page);
    const ogLocale = OG_LOCALES[lang];
    const ogLocaleAlternates = Object.values(OG_LOCALES).filter((v) => v !== ogLocale);

    let html = sourceHtml;

    html = html.replace(/<html lang="[^"]*"/i, `<html lang="${lang}"`);
    html = replaceTitle(html, title);
    html = replaceTagAttr(html, 'meta', 'name', 'description', 'content', description);
    html = replaceTagAttr(html, 'link', 'rel', 'canonical', 'href', canonical);

    html = replaceTagAttr(html, 'meta', 'property', 'og:title', 'content', title);
    html = replaceTagAttr(html, 'meta', 'property', 'og:description', 'content', description);
    html = replaceTagAttr(html, 'meta', 'property', 'og:url', 'content', canonical);
    html = replaceTagAttr(html, 'meta', 'property', 'og:locale', 'content', ogLocale);

    html = replaceAllOgLocaleAlternates(html, ogLocaleAlternates);

    html = replaceTagAttr(html, 'meta', 'name', 'twitter:title', 'content', title);
    html = replaceTagAttr(html, 'meta', 'name', 'twitter:description', 'content', description);

    return html;
}

/**
 * Rewrite the two `og:locale:alternate` meta tags so they exclude the
 * current language and cover the other two. Order-independent.
 */
function replaceAllOgLocaleAlternates(html, newAlternates) {
    const pattern = /<meta property="og:locale:alternate" content="[^"]*" ?\/?>/gi;
    const matches = html.match(pattern) || [];
    if (matches.length !== newAlternates.length) {
        throw new Error(
            `Expected ${newAlternates.length} og:locale:alternate tags, found ${matches.length}`,
        );
    }
    let index = 0;
    return html.replace(pattern, () => {
        const value = newAlternates[index++];
        return `<meta property="og:locale:alternate" content="${value}" />`;
    });
}

function buildLanguage(lang) {
    const locale = loadLocale(lang);
    const outDir = path.join(WEBSITE_DIR, lang);
    fs.rmSync(outDir, { recursive: true, force: true });
    fs.mkdirSync(outDir, { recursive: true });

    for (const page of PAGES) {
        const sourcePath = path.join(WEBSITE_DIR, `${page}.html`);
        const sourceHtml = fs.readFileSync(sourcePath, 'utf8');
        const localized = localizeHtml(sourceHtml, lang, page, locale);
        fs.writeFileSync(path.join(outDir, `${page}.html`), localized);
    }
}

/**
 * Build an XML sitemap describing every page across every language, with
 * xhtml:link alternates so Google treats them as equivalent translations.
 */
function buildSitemap() {
    const lines = [];
    lines.push('<?xml version="1.0" encoding="UTF-8"?>');
    lines.push(
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">',
    );

    const allLangs = [SOURCE_LANG, ...TARGET_LANGS];
    for (const lang of allLangs) {
        for (const page of PAGES) {
            const url = pageUrl(lang, page);
            lines.push('  <url>');
            lines.push(`    <loc>${url}</loc>`);
            for (const altLang of allLangs) {
                lines.push(
                    `    <xhtml:link rel="alternate" hreflang="${altLang}" href="${pageUrl(altLang, page)}" />`,
                );
            }
            lines.push(
                `    <xhtml:link rel="alternate" hreflang="x-default" href="${pageUrl('en', page)}" />`,
            );
            lines.push('  </url>');
        }
    }

    lines.push('</urlset>');
    lines.push('');

    fs.writeFileSync(path.join(WEBSITE_DIR, 'sitemap.xml'), lines.join('\n'));
}

function buildRobots() {
    const content = [
        'User-agent: *',
        'Allow: /',
        '',
        `Sitemap: ${SITE_ORIGIN}/sitemap.xml`,
        '',
    ].join('\n');
    fs.writeFileSync(path.join(WEBSITE_DIR, 'robots.txt'), content);
}

function main() {
    for (const lang of TARGET_LANGS) {
        console.log(`Building /${lang}/ ...`);
        buildLanguage(lang);
    }
    console.log('Writing sitemap.xml ...');
    buildSitemap();
    console.log('Writing robots.txt ...');
    buildRobots();
    console.log('Done.');
}

main();

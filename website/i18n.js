/**
 * i18n - Internationalization module for FinderHover website
 * Supports: zh-Hant (root), en (/en/), ja (/ja/)
 *
 * Language is encoded in the URL path:
 *   /            → zh-Hant
 *   /en/...      → en
 *   /ja/...      → ja
 */

const SUPPORTED_LANGS = ['zh-Hant', 'en', 'ja'];
const DEFAULT_LANG = 'zh-Hant';
const LANG_STORAGE_KEY = 'finderhover-lang';

/**
 * Parse a locale-authored HTML fragment into DOM nodes.
 * Locale strings contain markup like <br> for intentional line breaks;
 * we use DOMParser (which doesn't execute scripts) instead of an innerHTML
 * assignment to avoid handing raw strings to the HTML parser via a setter.
 */
function parseHtmlFragment(html) {
    const doc = new DOMParser().parseFromString(`<div id="root">${html}</div>`, 'text/html');
    const root = doc.getElementById('root');
    return root ? Array.from(root.childNodes) : [];
}

function replaceWithHtml(el, html) {
    const nodes = parseHtmlFragment(html);
    el.replaceChildren(...nodes);
}

const i18n = {
    supportedLangs: SUPPORTED_LANGS,
    defaultLang: DEFAULT_LANG,
    currentLang: null,
    translations: {},

    async init() {
        this.currentLang = this.detectLanguage();
        await this.loadTranslation(this.currentLang);
        this.applyTranslations();
        this.updateLangSwitcher();
        document.documentElement.lang = this.currentLang;
    },

    /**
     * Detect user's preferred language.
     * Path prefix wins. When at the zh-Hant root we only redirect if the
     * visitor has explicitly chosen a different language on a prior visit
     * (stored via the language switcher). Browser-language-only redirects
     * are deliberately avoided because they confuse crawlers — Googlebot
     * would hit "/" and be bounced to "/en/", contradicting our canonical.
     */
    detectLanguage() {
        const pathLang = this.detectLanguageFromPath();
        if (pathLang) return pathLang;

        const saved = localStorage.getItem(LANG_STORAGE_KEY);
        if (saved && saved !== DEFAULT_LANG && SUPPORTED_LANGS.includes(saved)) {
            this.redirectToLang(saved);
        }
        return DEFAULT_LANG;
    },

    detectLanguageFromPath() {
        const segments = window.location.pathname.split('/').filter(Boolean);
        const firstSegment = segments[0];
        if (firstSegment && SUPPORTED_LANGS.includes(firstSegment) && firstSegment !== DEFAULT_LANG) {
            return firstSegment;
        }
        return null;
    },

    redirectToLang(targetLang) {
        const targetPath = this.rewritePathForLang(window.location.pathname, targetLang);
        window.location.replace(targetPath + window.location.search + window.location.hash);
    },

    /**
     * Rewrite a pathname so it points at the given language tree.
     *   ("/docs.html", "en")      → "/en/docs.html"
     *   ("/en/docs.html", "ja")   → "/ja/docs.html"
     *   ("/ja/docs.html", "zh-Hant") → "/docs.html"
     */
    rewritePathForLang(pathname, targetLang) {
        const segments = pathname.split('/').filter(Boolean);
        if (segments[0] && SUPPORTED_LANGS.includes(segments[0]) && segments[0] !== DEFAULT_LANG) {
            segments.shift();
        }
        const prefix = targetLang === DEFAULT_LANG ? '' : `/${targetLang}`;
        const tail = segments.length === 0 ? '/' : `/${segments.join('/')}`;
        return prefix + tail;
    },

    async loadTranslation(lang) {
        try {
            const response = await fetch(`/locales/${lang}.json`);
            if (!response.ok) throw new Error(`Failed to load translation: ${lang}`);
            this.translations = await response.json();
        } catch (error) {
            console.error('i18n load error:', error);
            if (lang !== DEFAULT_LANG) {
                await this.loadTranslation(DEFAULT_LANG);
            }
        }
    },

    t(keyPath) {
        const keys = keyPath.split('.');
        let value = this.translations;
        for (const key of keys) {
            if (value && typeof value === 'object' && key in value) {
                value = value[key];
            } else {
                return keyPath;
            }
        }
        return value;
    },

    /**
     * Infer the page slug from the current URL so we can pick per-page meta.
     *   "/"                 → "index"
     *   "/en/"              → "index"
     *   "/download.html"    → "download"
     *   "/ja/docs.html"     → "docs"
     */
    getPageSlug() {
        const segments = window.location.pathname.split('/').filter(Boolean);
        if (segments[0] && SUPPORTED_LANGS.includes(segments[0]) && segments[0] !== DEFAULT_LANG) {
            segments.shift();
        }
        const file = segments[segments.length - 1];
        if (!file || !file.endsWith('.html')) return 'index';
        return file.replace(/\.html$/, '');
    },

    getPageMeta() {
        const slug = this.getPageSlug();
        const rootMeta = this.translations.meta || {};
        const pageMeta = (rootMeta.pages && rootMeta.pages[slug]) || {};
        return {
            title: pageMeta.title || rootMeta.title,
            description: pageMeta.description || rootMeta.description,
        };
    },

    applyTranslations() {
        this.applyMetaTranslations();
        this.applyElementTranslations();
        this.syncMarqueeContent();
    },

    applyMetaTranslations() {
        const { title, description } = this.getPageMeta();
        if (title) document.title = title;

        const metaDesc = document.querySelector('meta[name="description"]');
        if (metaDesc && description) metaDesc.setAttribute('content', description);

        if (title) this.setMetaAttr('meta[property="og:title"]', 'content', title);
        if (description) this.setMetaAttr('meta[property="og:description"]', 'content', description);
        if (title) this.setMetaAttr('meta[name="twitter:title"]', 'content', title);
        if (description) this.setMetaAttr('meta[name="twitter:description"]', 'content', description);
    },

    setMetaAttr(selector, attr, value) {
        const el = document.querySelector(selector);
        if (el) el.setAttribute(attr, value);
    },

    applyElementTranslations() {
        document.querySelectorAll('[data-i18n]').forEach((el) => {
            const key = el.getAttribute('data-i18n');
            const value = this.t(key);
            if (value !== key) replaceWithHtml(el, value);
        });

        document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
            const key = el.getAttribute('data-i18n-placeholder');
            const value = this.t(key);
            if (value !== key) el.placeholder = value;
        });

        document.querySelectorAll('[data-i18n-title]').forEach((el) => {
            const key = el.getAttribute('data-i18n-title');
            const value = this.t(key);
            if (value !== key) el.title = value;
        });
    },

    /**
     * Duplicate the first marquee-content node across every sibling so the
     * CSS-based infinite scroll always renders identical frames.
     */
    syncMarqueeContent() {
        document.querySelectorAll('.marquee-row').forEach((row) => {
            const contents = row.querySelectorAll('.marquee-content');
            if (contents.length <= 1) return;
            const source = contents[0];
            for (let i = 1; i < contents.length; i++) {
                const clones = Array.from(source.childNodes).map((node) => node.cloneNode(true));
                contents[i].replaceChildren(...clones);
            }
        });
    },

    updateLangSwitcher() {
        const switcher = document.querySelector('.lang-switcher');
        if (!switcher) return;

        const shortNames = { 'zh-Hant': '繁', 'ja': '日', 'en': 'EN' };
        const fullNames = { 'zh-Hant': '繁體中文', 'ja': '日本語', 'en': 'English' };

        const current = switcher.querySelector('.lang-current');
        if (current) {
            const desktopSpan = current.querySelector('.lang-text-desktop');
            const mobileSpan = current.querySelector('.lang-text-mobile');

            if (desktopSpan && mobileSpan) {
                desktopSpan.textContent = shortNames[this.currentLang];
                mobileSpan.textContent = fullNames[this.currentLang];
            } else {
                current.textContent = shortNames[this.currentLang];
            }
        }

        switcher.querySelectorAll('.lang-option').forEach((opt) => {
            const lang = opt.getAttribute('data-lang');
            opt.classList.toggle('active', lang === this.currentLang);
        });
    },

    /**
     * Switch to a different language by navigating to that language's URL.
     * A full navigation (rather than SPA-style swap) keeps the URL, canonical
     * tags, and hreflang metadata consistent for the reader and search engines.
     */
    switchTo(lang) {
        if (!SUPPORTED_LANGS.includes(lang)) return;
        if (lang === this.currentLang) return;
        localStorage.setItem(LANG_STORAGE_KEY, lang);
        const targetPath = this.rewritePathForLang(window.location.pathname, lang);
        window.location.href = targetPath + window.location.hash;
    },
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => i18n.init());
} else {
    i18n.init();
}

window.i18n = i18n;

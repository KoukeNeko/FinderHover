/**
 * i18n - Internationalization module for FinderHover website
 * Supports: zh-Hant, ja, en
 */

const i18n = {
    supportedLangs: ['zh-Hant', 'ja', 'en'],
    defaultLang: 'zh-Hant',
    currentLang: null,
    translations: {},

    /**
     * Initialize i18n system
     */
    async init() {
        this.currentLang = this.detectLanguage();
        await this.loadTranslation(this.currentLang);
        this.applyTranslations();
        this.updateLangSwitcher();
        document.documentElement.lang = this.currentLang;
    },

    /**
     * Detect user's preferred language
     */
    detectLanguage() {
        // Check URL param first
        const urlParams = new URLSearchParams(window.location.search);
        const urlLang = urlParams.get('lang');
        if (urlLang && this.supportedLangs.includes(urlLang)) {
            localStorage.setItem('finderhover-lang', urlLang);
            return urlLang;
        }

        // Check localStorage
        const savedLang = localStorage.getItem('finderhover-lang');
        if (savedLang && this.supportedLangs.includes(savedLang)) {
            return savedLang;
        }

        // Check browser language
        const browserLang = navigator.language;
        if (browserLang.startsWith('zh')) {
            return 'zh-Hant';
        } else if (browserLang.startsWith('ja')) {
            return 'ja';
        } else if (browserLang.startsWith('en')) {
            return 'en';
        }

        return this.defaultLang;
    },

    /**
     * Load translation file
     */
    async loadTranslation(lang) {
        try {
            // Use relative path to work with any hosting location
            const response = await fetch(`locales/${lang}.json`);
            if (!response.ok) throw new Error('Failed to load translation');
            this.translations = await response.json();
        } catch (error) {
            console.error('i18n load error:', error);
            // Fallback to default
            if (lang !== this.defaultLang) {
                await this.loadTranslation(this.defaultLang);
            }
        }
    },

    /**
     * Get translation by key path (e.g., "hero.headline")
     */
    t(keyPath) {
        const keys = keyPath.split('.');
        let value = this.translations;
        for (const key of keys) {
            if (value && typeof value === 'object' && key in value) {
                value = value[key];
            } else {
                return keyPath; // Return key if not found
            }
        }
        return value;
    },

    /**
     * Apply translations to all elements with data-i18n attribute
     */
    applyTranslations() {
        // Update document title
        if (this.translations.meta?.title) {
            document.title = this.translations.meta.title;
        }

        // Update meta description
        const metaDesc = document.querySelector('meta[name="description"]');
        if (metaDesc && this.translations.meta?.description) {
            metaDesc.content = this.translations.meta.description;
        }

        // Apply to elements with data-i18n
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            const value = this.t(key);
            if (value !== key) {
                el.innerHTML = value;
            }
        });

        // Apply to elements with data-i18n-placeholder
        document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
            const key = el.getAttribute('data-i18n-placeholder');
            const value = this.t(key);
            if (value !== key) {
                el.placeholder = value;
            }
        });

        // Apply to elements with data-i18n-title
        document.querySelectorAll('[data-i18n-title]').forEach(el => {
            const key = el.getAttribute('data-i18n-title');
            const value = this.t(key);
            if (value !== key) {
                el.title = value;
            }
        });

        // Sync marquee duplicate content
        this.syncMarqueeContent();
    },

    /**
     * Sync marquee content - copy first marquee-content to all duplicates
     */
    syncMarqueeContent() {
        document.querySelectorAll('.marquee-row').forEach(row => {
            const contents = row.querySelectorAll('.marquee-content');
            if (contents.length > 1) {
                const firstContent = contents[0];
                for (let i = 1; i < contents.length; i++) {
                    contents[i].innerHTML = firstContent.innerHTML;
                }
            }
        });
    },

    /**
     * Update language switcher UI
     */
    updateLangSwitcher() {
        const switcher = document.querySelector('.lang-switcher');
        if (!switcher) return;

        const langNames = {
            'zh-Hant': '繁',
            'ja': '日',
            'en': 'EN'
        };

        const langFullNames = {
            'zh-Hant': '繁體中文',
            'ja': '日本語',
            'en': 'English'
        };

        // Update current language display
        const current = switcher.querySelector('.lang-current');
        if (current) {
            const desktopSpan = current.querySelector('.lang-text-desktop');
            const mobileSpan = current.querySelector('.lang-text-mobile');

            if (desktopSpan && mobileSpan) {
                desktopSpan.textContent = langNames[this.currentLang];
                mobileSpan.textContent = langFullNames[this.currentLang];
            } else {
                current.textContent = langNames[this.currentLang];
            }
        }

        // Update active state
        switcher.querySelectorAll('.lang-option').forEach(opt => {
            const lang = opt.getAttribute('data-lang');
            opt.classList.toggle('active', lang === this.currentLang);
        });
    },

    /**
     * Switch to a different language
     */
    async switchTo(lang) {
        if (!this.supportedLangs.includes(lang)) return;
        if (lang === this.currentLang) return;

        localStorage.setItem('finderhover-lang', lang);
        this.currentLang = lang;
        await this.loadTranslation(lang);
        this.applyTranslations();
        this.updateLangSwitcher();
        document.documentElement.lang = lang;

        // Update URL without reload
        const url = new URL(window.location);
        url.searchParams.set('lang', lang);
        window.history.replaceState({}, '', url);
    }
};

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => i18n.init());
} else {
    i18n.init();
}

// Export for use in other scripts
window.i18n = i18n;

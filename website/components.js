/**
 * FinderHover Website - Web Components
 * Reduces duplicate code between pages
 */

const LANG_PREFIXES = ['en', 'ja'];

/**
 * Extract the language prefix for the current URL, e.g. "/en" or "".
 * Used to build nav/footer links that stay within the current language tree.
 */
function getLangPrefix() {
    const first = window.location.pathname.split('/').filter(Boolean)[0];
    return first && LANG_PREFIXES.includes(first) ? `/${first}` : '';
}

// ============================================
// Site Navigation Component
// ============================================
class SiteNav extends HTMLElement {
    connectedCallback() {
        const isHome = this.getAttribute('home') !== null;
        const langPrefix = getLangPrefix();
        const homeHref = `${langPrefix}/`;
        const homeLink = isHome ? '#' : homeHref;
        const featuresLink = isHome ? '#features' : `${homeHref}#features`;

        // Get current language from i18n if available
        const langNames = { 'zh-Hant': '繁', 'ja': '日', 'en': 'EN' };
        const langFullNames = { 'zh-Hant': '繁體中文', 'ja': '日本語', 'en': 'English' };
        const currentLang = window.i18n?.currentLang || 'zh-Hant';
        const currentLangDisplay = langNames[currentLang] || '繁';
        const currentLangFull = langFullNames[currentLang] || '繁體中文';

        this.innerHTML = `
      <nav class="nav">
        <div class="nav-content">
          <a href="${homeLink}" class="nav-logo">
            <img src="/assets/icon-128.png" alt="FinderHover" />
            <span>FinderHover</span>
          </a>
          <button class="nav-menu-toggle" aria-label="Toggle menu">
            <svg class="menu-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="3" y1="6" x2="21" y2="6"/>
              <line x1="3" y1="12" x2="21" y2="12"/>
              <line x1="3" y1="18" x2="21" y2="18"/>
            </svg>
            <svg class="close-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
          <div class="nav-links">
            <a href="${featuresLink}" data-i18n="nav.features">功能</a>
            <a href="${langPrefix}/formats.html" data-i18n="nav.formats">格式</a>
            <a href="${langPrefix}/docs.html" data-i18n="nav.docs">說明</a>
            <a href="${langPrefix}/changelog.html" data-i18n="nav.changelog">更新日誌</a>
            <div class="lang-switcher">
              <button class="lang-current" aria-label="Change language">
                <span class="lang-text-desktop">${currentLangDisplay}</span>
                <span class="lang-text-mobile">${currentLangFull}</span>
              </button>
              <div class="lang-dropdown">
                <button class="lang-option${currentLang === 'zh-Hant' ? ' active' : ''}" data-lang="zh-Hant">繁體中文</button>
                <button class="lang-option${currentLang === 'ja' ? ' active' : ''}" data-lang="ja">日本語</button>
                <button class="lang-option${currentLang === 'en' ? ' active' : ''}" data-lang="en">English</button>
              </div>
            </div>
            <a href="${langPrefix}/download.html" class="nav-cta-mobile" data-i18n="nav.download">下載</a>
          </div>
          <a href="${langPrefix}/download.html" class="nav-cta" data-i18n="nav.download">下載</a>
        </div>
      </nav>
    `;

        // Setup language switcher
        this.setupLangSwitcher();

        // Setup mobile menu toggle
        this.setupMobileMenu();

        // Apply translations if i18n is ready
        if (window.i18n?.translations && Object.keys(window.i18n.translations).length > 0) {
            window.i18n.applyTranslations();
        }
    }

    setupLangSwitcher() {
        const switcher = this.querySelector('.lang-switcher');
        const current = this.querySelector('.lang-current');
        const dropdown = this.querySelector('.lang-dropdown');

        // Toggle dropdown
        current.addEventListener('click', (e) => {
            e.stopPropagation();
            switcher.classList.toggle('open');
        });

        // Close on outside click
        document.addEventListener('click', () => {
            switcher.classList.remove('open');
        });

        // Language selection
        this.querySelectorAll('.lang-option').forEach(opt => {
            opt.addEventListener('click', (e) => {
                e.stopPropagation();
                const lang = opt.getAttribute('data-lang');
                if (window.i18n) {
                    window.i18n.switchTo(lang);
                }
                switcher.classList.remove('open');
            });
        });
    }

    setupMobileMenu() {
        const toggle = this.querySelector('.nav-menu-toggle');
        const navLinks = this.querySelector('.nav-links');
        const nav = this.querySelector('.nav');

        toggle.addEventListener('click', () => {
            nav.classList.toggle('menu-open');
        });

        // Close menu when clicking a link
        navLinks.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                nav.classList.remove('menu-open');
            });
        });
    }
}

// ============================================
// Site Footer Component
// ============================================
class SiteFooter extends HTMLElement {
    connectedCallback() {
        const langPrefix = getLangPrefix();

        this.innerHTML = `
      <footer class="footer">
        <div class="footer-content">
          <div class="footer-links">
            <a href="https://github.com/KoukeNeko/FinderHover" data-i18n="footer.github">GitHub</a>
            <a href="${langPrefix}/changelog.html" data-i18n="footer.changelog">更新日誌</a>
            <a href="${langPrefix}/license.html" data-i18n="footer.license">授權條款</a>
          </div>
          <p class="footer-copyright" data-i18n="footer.copyright">
            © KoukeNeko · 依 MIT 授權條款釋出
          </p>
        </div>
      </footer>
    `;
    }
}

// ============================================
// Register All Components
// ============================================
customElements.define('site-nav', SiteNav);
customElements.define('site-footer', SiteFooter);

// ============================================
// Shared controls (home and download pages)
// ============================================

/**
 * Segmented control: buttons inside `group` with a `.seg-pill` that slides to the
 * selected one. Calls onSelect(button) on click and arrow keys.
 */
function setupSegmented(group, onSelect) {
    const pill = group.querySelector('.seg-pill');
    const buttons = [...group.querySelectorAll('button')];
    const movePill = (btn, animate) => {
        pill.style.transition = animate ? '' : 'none';
        pill.style.width = `${btn.offsetWidth}px`;
        pill.style.transform = `translateX(${btn.offsetLeft - 4}px)`;
    };
    const select = (btn, animate = true) => {
        buttons.forEach((b) => b.setAttribute('aria-checked', String(b === btn)));
        movePill(btn, animate);
        onSelect(btn);
    };
    buttons.forEach((b) => b.addEventListener('click', () => select(b)));
    group.addEventListener('keydown', (e) => {
        const i = buttons.findIndex((b) => b.getAttribute('aria-checked') === 'true');
        const step = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
        if (!step) return;
        const next = buttons[(i + step + buttons.length) % buttons.length];
        next.focus();
        select(next);
    });
    select(buttons[0], false);
    // Labels change width once fonts load or the window resizes; put the pill back without animating.
    const current = () => group.querySelector('[aria-checked="true"]');
    document.fonts?.ready.then(() => movePill(current(), false));
    addEventListener('resize', () => movePill(current(), false));
}

/** Buttons marked data-install copy the Homebrew command and say so. */
function setupInstallButtons() {
    const t = (key) => window.i18n.t(key);
    document.querySelectorAll('[data-install]').forEach((btn) => {
        const text = btn.querySelector('.btn-label');
        btn.addEventListener('click', () => {
            navigator.clipboard.writeText('brew install koukeneko/tap/finderhover').then(() => {
                text.textContent = t('home.copied');
                btn.classList.add('done');
                setTimeout(() => { text.textContent = t('home.copy'); btn.classList.remove('done'); }, 1600);
            }, () => {
                // Clipboard access denied: select the command so ⌘C still works.
                const range = document.createRange();
                // The command shows in a .cmd box beside the button, or in the terminal of an install scope.
                range.selectNodeContents(btn.closest('.cmd, [data-install-scope]').querySelector('code'));
                getSelection().removeAllRanges();
                getSelection().addRange(range);
            });
        });
    });
}

if (window.i18n?.ready) setupInstallButtons();
else document.addEventListener('i18n:ready', setupInstallButtons, { once: true });

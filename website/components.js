/**
 * FinderHover Website - Web Components
 * 減少頁面間的重複程式碼
 */

// ============================================
// Site Navigation Component
// ============================================
class SiteNav extends HTMLElement {
  connectedCallback() {
    const isHome = this.getAttribute('home') !== null;
    const homeLink = isHome ? '#' : 'index.html';
    const featuresLink = isHome ? '#features' : 'index.html#features';
    
    this.innerHTML = `
      <nav class="nav">
        <div class="nav-content">
          <a href="${homeLink}" class="nav-logo">
            <img src="assets/icon.png" alt="FinderHover" />
            <span>FinderHover</span>
          </a>
          <div class="nav-links">
            <a href="${featuresLink}">功能特色</a>
            <a href="formats.html">支援格式</a>
            <a href="docs.html">使用說明</a>
            <a href="https://github.com/KoukeNeko/FinderHover" target="_blank">GitHub</a>
          </div>
          <a href="download.html" class="nav-cta">下載</a>
        </div>
      </nav>
    `;
  }
}

// ============================================
// Site Footer Component
// ============================================
class SiteFooter extends HTMLElement {
  connectedCallback() {
    const year = new Date().getFullYear();
    
    this.innerHTML = `
      <footer class="footer">
        <div class="footer-content">
          <div class="footer-links">
            <a href="https://github.com/KoukeNeko/FinderHover">GitHub</a>
            <a href="https://github.com/KoukeNeko/FinderHover/issues">問題回報</a>
            <a href="license.html">授權條款</a>
            <a href="changelog.html">更新日誌</a>
          </div>
          <p class="footer-copyright">
            Copyright © ${year} KoukeNeko. 以 MIT 授權釋出。
          </p>
        </div>
      </footer>
    `;
  }
}

// ============================================
// Page Hero Component (for subpages)
// ============================================
class PageHero extends HTMLElement {
  connectedCallback() {
    const title = this.getAttribute('title') || '';
    const subtitle = this.getAttribute('subtitle') || '';
    
    this.innerHTML = `
      <section class="page-hero">
        <h1 class="page-headline">${title}</h1>
        <p class="page-subheadline">${subtitle}</p>
      </section>
    `;
  }
}

// ============================================
// Copy Button Component
// ============================================
class CopyButton extends HTMLElement {
  connectedCallback() {
    const command = this.getAttribute('command') || '';
    
    this.innerHTML = `
      <button class="copy-btn" aria-label="複製到剪貼簿">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
        </svg>
      </button>
    `;
    
    this.querySelector('button').addEventListener('click', () => this.copy(command));
  }
  
  copy(command) {
    const btn = this.querySelector('button');
    navigator.clipboard.writeText(command).then(() => {
      const originalHTML = btn.innerHTML;
      btn.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      `;
      btn.classList.add('copied');
      setTimeout(() => {
        btn.innerHTML = originalHTML;
        btn.classList.remove('copied');
      }, 2000);
    });
  }
}

// ============================================
// Download Card Component
// ============================================
class DownloadCard extends HTMLElement {
  connectedCallback() {
    const recommended = this.hasAttribute('recommended');
    const icon = this.getAttribute('icon') || 'terminal';
    const title = this.getAttribute('title') || '';
    const description = this.getAttribute('description') || '';
    
    const badgeHTML = recommended ? '<div class="download-badge">推薦</div>' : '';
    const cardClass = recommended ? 'download-card recommended' : 'download-card';
    
    const iconSVG = this.getIconSVG(icon);
    
    // Preserve inner content (steps, code blocks, etc.)
    const innerContent = this.innerHTML;
    
    this.innerHTML = `
      <div class="${cardClass}">
        ${badgeHTML}
        <div class="download-icon">${iconSVG}</div>
        <h2>${title}</h2>
        <p class="download-desc">${description}</p>
        ${innerContent}
      </div>
    `;
  }
  
  getIconSVG(icon) {
    const icons = {
      terminal: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
      </svg>`,
      download: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/>
        <line x1="12" y1="15" x2="12" y2="3"/>
      </svg>`,
      code: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
      </svg>`
    };
    return icons[icon] || icons.terminal;
  }
}

// ============================================
// Feature Card Component
// ============================================
class FeatureCard extends HTMLElement {
  connectedCallback() {
    const title = this.getAttribute('title') || '';
    const icon = this.getAttribute('icon') || '';
    const description = this.innerHTML;
    
    this.innerHTML = `
      <div class="feature-item">
        <div class="feature-icon">${icon}</div>
        <h3>${title}</h3>
        <p>${description}</p>
      </div>
    `;
  }
}

// ============================================
// Metadata Card Component
// ============================================
class MetadataCard extends HTMLElement {
  connectedCallback() {
    const title = this.getAttribute('title') || '';
    const icon = this.innerHTML.match(/<svg[\s\S]*?<\/svg>/)?.[0] || '';
    const description = this.getAttribute('description') || '';
    
    this.innerHTML = `
      <div class="metadata-card">
        <div class="metadata-icon">${icon}</div>
        <h3>${title}</h3>
        <p>${description}</p>
      </div>
    `;
  }
}

// ============================================
// Scroll Observer (for animations)
// ============================================
class ScrollObserver {
  static init() {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, observerOptions);

    document.querySelectorAll('.feature-item, .metadata-card, .gallery-item').forEach((el) => {
      observer.observe(el);
    });
  }
}

// ============================================
// Register All Components
// ============================================
customElements.define('site-nav', SiteNav);
customElements.define('site-footer', SiteFooter);
customElements.define('page-hero', PageHero);
customElements.define('copy-button', CopyButton);
customElements.define('download-card', DownloadCard);
customElements.define('feature-card', FeatureCard);
customElements.define('metadata-card', MetadataCard);

// Initialize scroll observer when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  ScrollObserver.init();
});

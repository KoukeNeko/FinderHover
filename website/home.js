/**
 * Home page demo: a Finder list whose rows show the FinderHover popup on hover,
 * focus or tap, plus the popup breakdown, the ⌥ copy demo and the appearance switcher.
 * Strings come from locales (home.*, demo.*); figures are language-neutral.
 */

const t = (key) => window.i18n.t(key);
const label = (key) => t(`demo.label.${key}`);

// File type colors, matching HoverContentView v2.
const COLORS = {
  photo: '#FFD60A', video: '#7D7AFF', pdf: '#FF453A', code: '#64D2FF',
  git: '#FF9F0A', zip: '#AC8E68', folder: '#3B82F6', md: '#46B89A',
};

const COMMON = {
  dates: [['created', '2026/9/3 14:02'], ['modified', '2026/9/3 14:02'], ['opened', () => `2026/10/24 14:41 · ${t('demo.value.times')}`]],
};

const FILES = {
  photo: {
    name: 'DSC03757.ARW', size: '21.6 MB', uti: 'com.sony.arw-raw-image', path: '~ › Pictures › 2026 › 新潟',
    title: 'SONY ILCE-7C', subtitle: '28-70mm F2.8 DG DN | Contemporary 021',
    specs: [['28mm', 'focal'], ['ƒ/4.0', 'aperture'], ['1/15', 'shutter'], ['ISO 500', 'iso']],
    fields: [['taken', '2026/9/2 21:33'], ['location', '37.70°N, 138.83°E'], ['profile', 'Display P3'], ['depth', '14-bit']],
  },
  video: {
    name: '新潟花火.mov', size: '1.24 GB', uti: 'com.apple.quicktime-movie', path: '~ › Movies',
    hero: '12:48', heroLabel: 'duration', trailing: 'HLG',
    specs: [['3840×2160', 'resolution'], ['59.94 fps', 'fps'], ['HEVC', 'codec'], ['48.2 Mbps', 'bitrate']],
    fields: [['primaries', 'BT.2020'], ['tracks', () => t('demo.value.tracks')]],
  },
  pdf: {
    name: 'attention-is-all-you-need.pdf', size: '2.2 MB', uti: 'com.adobe.pdf', path: '~ › Documents › Papers',
    title: 'Attention Is All You Need', subtitle: 'Ashish Vaswani, Noam Shazeer, Niki Parmar, et al.',
    specs: [['15', 'pages'], ['Letter', 'paper'], ['1.5', 'version'], [() => t('demo.value.no'), 'encrypted']],
    fields: [['producer', 'pdfTeX-1.40.25'], ['keywords', 'transformer, attention']],
  },
  code: {
    name: 'HoverContentView.swift', size: '72 KB', uti: 'public.swift-source', path: '~ › Developer › FinderHover',
    hero: '1,504', heroLabel: 'lines', trailing: 'Swift · UTF-8', bar: [0.86, 0.04],
    specs: [['1,290', 'code'], ['64', 'comments'], ['150', 'blank']],
    fields: [],
  },
  git: {
    name: 'FinderHover', size: () => t('demo.value.items'), uti: 'public.folder', path: '~ › Developer',
    title: 'beta', subtitle: () => t('demo.value.clean'),
    specs: [['424', 'commits'], ['15', 'branches'], ['45', 'tags']],
    fields: [['lastCommit', 'feat(settings): use a unified toolbar']],
  },
  booking: {
    name: '住宿確認.pdf', size: '188 KB', uti: 'com.adobe.pdf', path: '~ › Documents',
    title: 'Booking Confirmation', subtitle: 'Hotel Okura Niigata',
    specs: [['2', 'pages'], ['A4', 'paper'], ['1.7', 'version'], [() => t('demo.value.no'), 'encrypted']],
    fields: [['producer', 'Skia/PDF m128']],
  },
  zip: {
    name: '備份.zip', size: '8.2 GB', uti: 'public.zip-archive', path: '~ › Backups',
    hero: '1,284', heroLabel: 'files', trailing: 'ZIP',
    specs: [['1,284', 'files'], ['11.6 GB', 'unpacked'], ['71%', 'ratio']],
    fields: [['encrypted', () => t('demo.value.no')]],
  },
};

// Finder rows; plain rows get the generic popup (header, dates, file, footer).
const ROWS = [
  { name: '2026 新潟', type: 'folder', size: '—', uti: 'public.folder', path: '~ › Pictures' },
  { key: 'photo', type: 'photo' },
  { key: 'video', type: 'video' },
  { key: 'pdf', type: 'pdf' },
  { key: 'code', type: 'code' },
  { key: 'git', type: 'git' },
  { key: 'zip', type: 'zip' },
  { name: '行程.md', type: 'md', size: '4 KB', uti: 'net.daringfireball.markdown', path: '~ › Documents' },
  { key: 'booking', type: 'pdf' },
];

const val = (v) => (typeof v === 'function' ? v() : v);
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function fileFor(row) {
  return row.key ? { ...FILES[row.key], type: row.type, key: row.key } : { ...row };
}

/** A copyable value; the copy button only shows while the popup is locked (⌥ held). */
function value(text) {
  const s = esc(val(text));
  return `<span class="v">${s}<button class="pop-copy" type="button" data-copy="${s}" aria-label="${s}" tabindex="-1">
    <svg viewBox="0 0 16 16" aria-hidden="true"><rect x="5" y="5" width="8.5" height="8.5" rx="1.8"/><path d="M3 10.5V3.8C3 3.3 3.3 3 3.8 3h6.7"/></svg></button></span>`;
}

/** The v2 popup, split into its five parts (data-part) so the breakdown can pull them apart. */
function popupHTML(file) {
  const color = COLORS[file.type];
  const kind = file.key ? t(`demo.kind.${file.key === 'booking' ? 'pdf' : file.key}`) : t(`demo.type.${file.type}`);
  const size = val(file.size);
  const head = `
    <div class="pop-part" data-part="header">
      <div class="pop-head">
        <span class="pop-icon" style="--c:${color}"></span>
        <div><strong>${value(file.name)}</strong><span>${esc(kind)} · ${esc(size)}</span></div>
      </div>
    </div>`;

  let type = '';
  if (file.specs) {
    const title = file.title
      ? `<div class="pop-title"><strong>${value(file.title)}</strong><span>${esc(val(file.subtitle))}</span></div>` : '';
    const hero = file.hero
      ? `<div class="pop-hero"><strong style="color:${color}">${value(file.hero)}</strong><span class="u">${esc(label(file.heroLabel))}</span><span class="tr">${esc(file.trailing || '')}</span></div>` : '';
    const bar = file.bar
      ? `<div class="pop-seg"><i style="width:${file.bar[0] * 100}%;background:${color}"></i><i style="width:${file.bar[1] * 100}%"></i></div>` : '';
    // Photos and PDFs color their spec figures; video, code, Git and archives keep a single hero.
    const tinted = file.type === 'photo' || file.type === 'pdf';
    const specs = `<div class="pop-specs">${file.specs.map(([v, l], i) =>
      `<div><strong${tinted && (file.type === 'photo' || i === 0) ? ` style="color:${color}"` : ''}>${value(v)}</strong><span>${esc(label(l))}</span></div>`).join('')}</div>`;
    const fields = file.fields.length
      ? `<div class="pop-fields">${file.fields.map(([l, v]) => `<div><span>${esc(label(l))}</span>${value(v)}</div>`).join('')}</div>` : '';
    type = `<div class="pop-part" data-part="type">${title}${hero}${bar}${specs}${fields}</div>`;
  }

  const dates = `<div class="pop-part" data-part="dates"><div class="pop-fields">${COMMON.dates.map(([l, v]) =>
    `<div${l === 'opened' ? ' class="wide"' : ''}><span>${esc(label(l))}</span>${value(v)}</div>`).join('')}</div></div>`;
  const fileSection = `<div class="pop-part" data-part="file"><div class="pop-fields">
      <div><span>${esc(label('allocated'))}</span>${value(size)}</div>
      <div><span>${esc(label('uti'))}</span>${value(file.uti)}</div></div></div>`;
  const footer = `<div class="pop-part" data-part="footer">
      <div class="pop-path">${value(file.path)}</div>
      <div class="pop-volume"><span>Macintosh HD · APFS</span><span>${esc(t('demo.value.free'))}</span></div>
      <div class="pop-usage"><i></i></div>
      <div class="pop-note">${esc(label('notes'))}</div></div>`;
  return head + type + dates + fileSection + footer;
}

// ---------------------------------------------------------------------------
// Hero: Finder list
// ---------------------------------------------------------------------------

const HOVER_DELAY = 400;
const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

function setupFinder() {
  const list = document.getElementById('finder-rows');
  const pop = document.getElementById('finder-pop');
  const ring = document.getElementById('finder-ring');
  const cursor = document.getElementById('finder-cursor');
  if (!list) return;

  list.innerHTML = ROWS.map((row, i) => {
    const file = fileFor(row);
    return `<button class="row" type="button" data-index="${i}">
      <span class="n"><b style="background:${COLORS[row.type]}"></b>${esc(file.name)}</span>
      <span class="s">${esc(val(file.size))}</span>
      <span class="k">${esc(t(`demo.type.${row.type}`))}</span>
    </button>`;
  }).join('');

  let timer = 0;
  let current = -1;

  function place(rowEl, x) {
    const box = list.getBoundingClientRect();
    const r = rowEl.getBoundingClientRect();
    const popW = pop.offsetWidth, popH = pop.offsetHeight;
    // Popup sits 16 px right of and below the pointer (the app's default offsets).
    let left = Math.min(Math.max(x + 16, 12), box.width - popW - 12);
    let top = r.bottom - box.top + 6;
    if (top + popH > box.height - 8) top = Math.max(8, r.top - box.top - popH - 6);
    pop.style.left = `${left}px`;
    pop.style.top = `${top}px`;
  }

  function show(index, rowEl, x) {
    current = index;
    pop.innerHTML = popupHTML(fileFor(ROWS[index]));
    pop.hidden = false;
    place(rowEl, x);
    pop.classList.remove('in');
    void pop.offsetWidth;
    pop.classList.add('in');
  }

  function hide() {
    clearTimeout(timer);
    current = -1;
    pop.hidden = true;
    ring.classList.remove('on');
    list.querySelectorAll('.row.hover').forEach((r) => r.classList.remove('hover'));
  }

  function arm(rowEl, x, y) {
    const index = Number(rowEl.dataset.index);
    if (index === current) return;
    hide();
    rowEl.classList.add('hover');
    const box = list.getBoundingClientRect();
    ring.style.left = `${x - 15}px`;
    ring.style.top = `${y - box.top - 15}px`;
    ring.classList.remove('on');
    void ring.offsetWidth;
    ring.classList.add('on');
    timer = setTimeout(() => { ring.classList.remove('on'); show(index, rowEl, x); }, HOVER_DELAY);
  }

  const canHover = matchMedia('(hover: hover)').matches;
  let userTookOver = false;
  const takeOver = () => {
    if (userTookOver) return;
    userTookOver = true;
    cursor.classList.add('off');
  };

  if (canHover) {
    list.addEventListener('pointermove', (e) => {
      const rowEl = e.target.closest('.row');
      if (!rowEl) return;
      takeOver();
      arm(rowEl, e.clientX - list.getBoundingClientRect().left, e.clientY);
    });
    list.addEventListener('pointerleave', () => { if (userTookOver) hide(); });
  } else {
    list.addEventListener('click', (e) => {
      const rowEl = e.target.closest('.row');
      if (!rowEl) return;
      takeOver();
      const r = rowEl.getBoundingClientRect();
      if (Number(rowEl.dataset.index) === current) return hide();
      arm(rowEl, r.width * 0.35, r.top + r.height / 2);
    });
    document.addEventListener('click', (e) => { if (!e.target.closest('#finder')) hide(); });
  }
  list.addEventListener('focusin', (e) => {
    const rowEl = e.target.closest('.row');
    if (!rowEl) return;
    takeOver();
    const r = rowEl.getBoundingClientRect();
    arm(rowEl, Math.min(320, r.width * 0.4), r.top + r.height / 2);
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') hide(); });

  // Intro: the pointer slides onto the video row and rests there. Touch screens skip it,
  // since an open popup would cover the list before anyone has tapped.
  if (!canHover) return;
  const target = list.querySelector('[data-index="2"]');
  const startIntro = () => {
    if (userTookOver) return;
    const box = list.getBoundingClientRect();
    const r = target.getBoundingClientRect();
    const x = Math.min(360, r.width * 0.42), y = r.top + r.height / 2;
    cursor.classList.remove('off');
    cursor.style.transform = `translate(${x - 3}px, ${y - box.top - 3}px)`;
    setTimeout(() => { if (!userTookOver) arm(target, x, y); }, prefersReducedMotion ? 0 : 700);
  };
  if (prefersReducedMotion) {
    startIntro();
  } else {
    cursor.classList.remove('off');
    cursor.style.transform = `translate(${list.clientWidth * 0.7}px, ${list.clientHeight * 0.85}px)`;
    setTimeout(startIntro, 900);
  }
}

// ---------------------------------------------------------------------------
// Popup breakdown, file types, ⌥ copy, appearance
// ---------------------------------------------------------------------------

function setupAnatomy() {
  const pop = document.getElementById('anatomy-pop');
  if (!pop) return;
  pop.innerHTML = popupHTML(fileFor(ROWS[1]));
  // Each part carries its own label so it travels with the part.
  pop.querySelectorAll('.pop-part').forEach((part) => {
    const [name, desc] = t(`home.anatomy.${part.dataset.part}`);
    part.insertAdjacentHTML('beforeend', `<div class="part-label"><strong>${esc(name)}</strong><span>${esc(desc)}</span></div>`);
  });
}

const TYPE_EXT = {
  photo: '.jpg .heic .arw .dng .cr3', video: '.mov .mp4 .mkv .webm', pdf: '.pdf',
  code: '.swift .ts .py .rs .go', git: '.git', zip: '.zip .7z .tar.gz .dmg',
};
const TYPE_KEYS = ['git', 'video', 'pdf', 'code', 'photo', 'zip'];

function setupTypes() {
  const tags = document.getElementById('type-tags');
  const pop = document.getElementById('type-pop');
  const ext = document.getElementById('type-ext');
  if (!tags) return;
  const figure = (f) => f.hero ? [f.hero, label(f.heroLabel)] : [val(f.specs[0][0]), label(f.specs[0][1])];
  tags.innerHTML = TYPE_KEYS.map((key) => {
    const [num, unit] = figure(FILES[key]);
    return `<button class="type-tag" type="button" role="tab" data-key="${key}" style="--c:${COLORS[key]}">
      <span class="type-name"><i></i>${esc(t(`demo.type.${key}`))}</span>
      <span class="type-fig"><strong>${esc(num)}</strong> ${esc(unit)}</span>
    </button>`;
  }).join('');
  const buttons = [...tags.querySelectorAll('.type-tag')];
  const select = (btn) => {
    const key = btn.dataset.key;
    buttons.forEach((b) => b.setAttribute('aria-selected', String(b === btn)));
    pop.innerHTML = popupHTML({ ...FILES[key], type: key, key });
    pop.classList.remove('in');
    void pop.offsetWidth;
    pop.classList.add('in');
    ext.textContent = TYPE_EXT[key];
  };
  buttons.forEach((b) => b.addEventListener('click', () => select(b)));
  tags.addEventListener('keydown', (e) => {
    const i = buttons.findIndex((b) => b.getAttribute('aria-selected') === 'true');
    const step = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
    if (!step) return;
    const next = buttons[(i + step + buttons.length) % buttons.length];
    next.focus();
    select(next);
  });
  select(buttons[0]);
}

function setupCopyDemo() {
  const pop = document.getElementById('copy-pop');
  const key = document.getElementById('copy-key');
  const toast = document.getElementById('copy-toast');
  if (!pop) return;
  pop.innerHTML = popupHTML(fileFor(ROWS[4]));
  const setLocked = (on) => {
    pop.classList.toggle('locked', on);
    key.setAttribute('aria-pressed', String(on));
    pop.querySelectorAll('.pop-copy').forEach((b) => (b.tabIndex = on ? 0 : -1));
  };
  // The on-screen key toggles so touch and keyboard users can reach the buttons too.
  key.addEventListener('click', () => setLocked(key.getAttribute('aria-pressed') !== 'true'));
  window.addEventListener('keydown', (e) => { if (e.key === 'Alt') setLocked(true); });
  window.addEventListener('keyup', (e) => { if (e.key === 'Alt') setLocked(false); });
  window.addEventListener('blur', () => setLocked(false));

  let toastTimer = 0;
  const announce = (btn) => {
    toast.textContent = t('home.copyDemo.copiedValue').replace('%s', btn.dataset.copy);
    toast.classList.add('on');
    btn.closest('.v').classList.remove('flash');
    void btn.offsetWidth;
    btn.closest('.v').classList.add('flash');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('on'), 1600);
  };
  pop.addEventListener('click', (e) => {
    const btn = e.target.closest('.pop-copy');
    if (!btn || !pop.classList.contains('locked')) return;
    navigator.clipboard.writeText(btn.dataset.copy).then(() => announce(btn), () => {});
  });

  // Played once on first view: hold ⌥, "copy" the line count, let go. Nothing is written
  // to the clipboard, since the visitor did not ask for it.
  let played = false;
  new IntersectionObserver((entries, obs) => {
    if (played || !entries[0].isIntersecting) return;
    played = true;
    obs.disconnect();
    setTimeout(() => setLocked(true), 300);
    setTimeout(() => announce(pop.querySelector('.pop-hero .pop-copy')), 1300);
    setTimeout(() => { if (key.dataset.user !== '1') setLocked(false); }, 3600);
  }, { threshold: 0.6 }).observe(pop);
  key.addEventListener('click', () => (key.dataset.user = '1'), { capture: true });
}

function setupLook() {
  const stage = document.getElementById('look-stage');
  const group = document.getElementById('look-modes');
  if (!stage) return;
  const pop = stage.querySelector('.pop');
  const win = stage.querySelector('.win-tip');
  pop.innerHTML = popupHTML(fileFor(ROWS[1]));
  const f = FILES.photo;
  win.innerHTML = [
    [t('home.finder.name'), f.name], [t('home.finder.kind'), t('demo.kind.photo')],
    [t('home.finder.size'), f.size], [label('modified'), '2026/9/3 14:02'], [label('taken'), '2026/9/2 21:33'],
  ].map(([l, v]) => `<div><span>${esc(l)}:</span> ${esc(v)}</div>`).join('');

  const pill = group.querySelector('.seg-pill');
  const buttons = [...group.querySelectorAll('button')];
  const movePill = (btn, animate) => {
    pill.style.transition = animate ? '' : 'none';
    pill.style.width = `${btn.offsetWidth}px`;
    pill.style.transform = `translateX(${btn.offsetLeft - 4}px)`;
  };
  const select = (btn, animate = true) => {
    buttons.forEach((b) => b.setAttribute('aria-checked', String(b === btn)));
    const mode = btn.dataset.mode;
    stage.dataset.mode = mode;
    pop.className = `pop ${mode === 'windows' ? '' : mode}`;
    movePill(btn, animate);
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
  // Labels change width once fonts load; put the pill back without animating.
  document.fonts?.ready.then(() => movePill(group.querySelector('[aria-checked="true"]'), false));
  addEventListener('resize', () => movePill(group.querySelector('[aria-checked="true"]'), false));
}

// ---------------------------------------------------------------------------
// Install buttons
// ---------------------------------------------------------------------------

function setupInstall() {
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
        range.selectNodeContents(btn.closest('.cmd').querySelector('code'));
        getSelection().removeAllRanges();
        getSelection().addRange(range);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Motion (GSAP)
// ---------------------------------------------------------------------------

function setupMotion() {
  if (!window.gsap || !window.ScrollTrigger) return;
  gsap.registerPlugin(ScrollTrigger);
  const mm = gsap.matchMedia();

  mm.add('(prefers-reduced-motion: no-preference)', () => {
    // Entry: the window rises, then the headline and install action follow.
    gsap.from('#finder', { y: 40, opacity: 0, duration: 0.7, ease: 'expo.out' });
    gsap.from('.toolbar-copy > *, .toolbar-actions', { y: 16, opacity: 0, duration: 0.6, ease: 'expo.out', stagger: 0.06, delay: 0.15 });

    // Section entries play once.
    gsap.utils.toArray('.reveal').forEach((el) => {
      gsap.from(el.children, {
        y: 24, opacity: 0, duration: 0.6, ease: 'expo.out', stagger: 0.06,
        scrollTrigger: { trigger: el, start: 'top 80%', once: true },
      });
    });
    gsap.from('.type-tag', {
      y: -18, opacity: 0, duration: 0.5, ease: 'back.out(1.6)', stagger: 0.06,
      scrollTrigger: { trigger: '#type-tags', start: 'top 85%', once: true },
    });
  });

  // Breakdown: pin the popup and pull its five parts apart; scrolling back reassembles it.
  mm.add('(prefers-reduced-motion: no-preference) and (min-width: 900px)', () => {
    const parts = gsap.utils.toArray('#anatomy-pop .pop-part');
    const mid = (parts.length - 1) / 2;
    const tl = gsap.timeline({
      scrollTrigger: { trigger: '.anatomy', start: 'top top', end: '+=160%', scrub: 0.6, pin: '.anatomy-stage' },
    });
    tl.to(parts, { y: (i) => (i - mid) * 40, ease: 'back.out(1.3)', duration: 0.8, stagger: 0.05 }, 0)
      .to('#anatomy-pop', { scale: 0.88, ease: 'power2.inOut', duration: 1 }, 0)
      .to('#anatomy-pop', { '--sep': 1, duration: 0.4 }, 0.3)
      .to('#anatomy-pop .part-label', { opacity: 1, x: 0, stagger: 0.08, duration: 0.4 }, 0.55)
      .to({}, { duration: 0.5 });
    return () => tl.kill();
  });
}

function init() {
  // Chromium is the only engine that applies SVG filters to backdrop-filter.
  if (window.chrome) document.documentElement.classList.add('refract');
  setupFinder();
  setupAnatomy();
  setupTypes();
  setupCopyDemo();
  setupLook();
  setupInstall();
  setupMotion();
}

if (window.i18n?.ready) init();
else document.addEventListener('i18n:ready', init, { once: true });

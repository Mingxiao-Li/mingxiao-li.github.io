(function () {
  'use strict';

  const root = document.documentElement;
  root.classList.remove('no-js');
  root.classList.add('js');

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const revealItems = document.querySelectorAll('[data-reveal]');

  if ('IntersectionObserver' in window && !reducedMotion) {
    const revealObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -7% 0px' });

    revealItems.forEach((item) => revealObserver.observe(item));
  } else {
    revealItems.forEach((item) => item.classList.add('is-visible'));
  }

  const progress = document.querySelector('.scroll-progress span');
  const header = document.querySelector('.site-header');
  const darkSections = Array.from(document.querySelectorAll('.contact'));
  let scrollFrame = null;

  function updateScrollUI() {
    const scrollable = Math.max(document.documentElement.scrollHeight - window.innerHeight, 1);
    progress.style.width = `${Math.min((window.scrollY / scrollable) * 100, 100)}%`;
    header.classList.toggle('is-compact', window.scrollY > 36);
    const isDark = darkSections.some((section) => {
      const rect = section.getBoundingClientRect();
      return rect.top <= 42 && rect.bottom > 42;
    });
    header.dataset.theme = isDark ? 'dark' : 'light';
    scrollFrame = null;
  }

  function requestScrollUI() {
    if (scrollFrame !== null) return;
    scrollFrame = window.requestAnimationFrame(updateScrollUI);
  }

  window.addEventListener('scroll', requestScrollUI, { passive: true });
  window.addEventListener('resize', requestScrollUI);
  updateScrollUI();

  const menuButton = document.querySelector('.menu-toggle');
  const menu = document.querySelector('.site-menu');

  function setMenu(open) {
    menuButton.setAttribute('aria-expanded', String(open));
    menu.classList.toggle('is-open', open);
    header.classList.toggle('is-menu-open', open);
    document.body.style.overflow = open ? 'hidden' : '';
  }

  menuButton.addEventListener('click', () => {
    setMenu(menuButton.getAttribute('aria-expanded') !== 'true');
  });

  menu.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => setMenu(false)));
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') setMenu(false);
  });

  const timeNode = document.querySelector('#local-time');
  const timeFormatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Shanghai',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });

  function updateTime() {
    timeNode.textContent = timeFormatter.format(new Date());
  }

  updateTime();
  window.setInterval(updateTime, 30000);

  const isLocalPreview = window.location.protocol === 'file:' || ['localhost', '127.0.0.1'].includes(window.location.hostname);
  if (!isLocalPreview) {
    const counterScript = document.createElement('script');
    counterScript.async = true;
    counterScript.src = 'https://busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js';
    document.body.appendChild(counterScript);
  }
}());

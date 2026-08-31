(() => {
  const titleField = document.querySelector('[data-editor-title]');
  const tagsField = document.querySelector('[data-editor-tags]');
  const bodyField = document.querySelector('[data-editor-body]');
  const preview = document.querySelector('[data-editor-preview]');
  const status = document.querySelector('[data-editor-status]');
  const fileInput = document.querySelector('[data-editor-file-input]');
  const imageInput = document.querySelector('[data-editor-image-input]');
  if (!titleField || !tagsField || !bodyField || !preview) return;

  const STORAGE_KEY = 'mingxiao-li-technique-note-draft-v1';
  const fallbackBody = '## The question\n\nWhat problem are you trying to solve, and why does it matter?\n\n## The intuition\n\nExplain the key idea in plain language before introducing the details.\n\n## The implementation\n\nAdd equations, pseudocode, experiments, or links that make the idea reproducible.\n\n## Takeaways\n\n- One idea worth remembering.\n- One practical detail worth reusing.';

  const escapeHtml = (value) => String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

  const escapeAttribute = (value) => escapeHtml(value).replace(/`/g, '&#096;');

  const inlineMarkdown = (value) => {
    let html = escapeHtml(value);
    const codeSpans = [];
    const mathSpans = [];
    html = html.replace(/`([^`]+)`/g, (_, code) => {
      codeSpans.push(`<code>${code}</code>`);
      return `\u0000${codeSpans.length - 1}\u0000`;
    });
    html = html.replace(/\$\$([^$]+)\$\$/g, (_, formula) => {
      mathSpans.push(`\\(${formula}\\)`);
      return `\u0001${mathSpans.length - 1}\u0001`;
    });
    html = html.replace(/\$([^$\n]+)\$/g, (_, formula) => {
      mathSpans.push(`\\(${formula}\\)`);
      return `\u0001${mathSpans.length - 1}\u0001`;
    });
    html = html.replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (_, alt, url) => {
      const safeUrl = /^(https?:|\/|#|data:image\/)/i.test(url) ? url : '#';
      return `<img src="${escapeAttribute(safeUrl)}" alt="${alt}" loading="lazy">`;
    });
    html = html.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, label, url) => {
      const safeUrl = /^(https?:|mailto:|\/|#)/i.test(url) ? url : '#';
      return `<a href="${escapeAttribute(safeUrl)}" target="_blank" rel="noreferrer">${label}</a>`;
    });
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/__([^_]+)__/g, '<strong>$1</strong>');
    html = html.replace(/(^|[^*])\*([^*]+)\*/g, '$1<em>$2</em>');
    html = html.replace(/(^|[^_])_([^_]+)_/g, '$1<em>$2</em>');
    html = html.replace(/\u0001(\d+)\u0001/g, (_, index) => mathSpans[Number(index)]);
    return html.replace(/\u0000(\d+)\u0000/g, (_, index) => codeSpans[Number(index)]);
  };

  const renderMarkdown = (source) => {
    const lines = String(source || '').replace(/\r\n?/g, '\n').split('\n');
    const output = [];
    let paragraph = [];
    let index = 0;

    const flushParagraph = () => {
      if (!paragraph.length) return;
      output.push(`<p>${inlineMarkdown(paragraph.join(' '))}</p>`);
      paragraph = [];
    };

    while (index < lines.length) {
      const line = lines[index];
      if (line.trim() === '$$') {
        flushParagraph();
        const formula = [];
        index += 1;
        while (index < lines.length && lines[index].trim() !== '$$') {
          formula.push(lines[index]);
          index += 1;
        }
        output.push(`<div class="math-block">\\[${escapeHtml(formula.join('\n'))}\\]</div>`);
        index += 1;
        continue;
      }
      const fence = line.match(/^\s*```\s*([\w-]*)\s*$/);
      if (fence) {
        flushParagraph();
        const language = fence[1] ? ` class="language-${escapeAttribute(fence[1])}"` : '';
        const code = [];
        index += 1;
        while (index < lines.length && !/^\s*```\s*$/.test(lines[index])) {
          code.push(lines[index]);
          index += 1;
        }
        output.push(`<pre><code${language}>${escapeHtml(code.join('\n'))}</code></pre>`);
        index += 1;
        continue;
      }

      const heading = line.match(/^\s*(#{1,6})\s+(.+?)\s*#*\s*$/);
      if (heading) {
        flushParagraph();
        const level = heading[1].length;
        output.push(`<h${level}>${inlineMarkdown(heading[2])}</h${level}>`);
        index += 1;
        continue;
      }

      if (/^\s*(---+|\*\s*\*\s*\*|___+)\s*$/.test(line)) {
        flushParagraph();
        output.push('<hr>');
        index += 1;
        continue;
      }

      if (/^\s*[-*+]\s+/.test(line)) {
        flushParagraph();
        const items = [];
        while (index < lines.length && /^\s*[-*+]\s+/.test(lines[index])) {
          items.push(lines[index].replace(/^\s*[-*+]\s+/, ''));
          index += 1;
        }
        output.push(`<ul>${items.map((item) => `<li>${inlineMarkdown(item)}</li>`).join('')}</ul>`);
        continue;
      }

      if (/^\s*\d+[.)]\s+/.test(line)) {
        flushParagraph();
        const items = [];
        while (index < lines.length && /^\s*\d+[.)]\s+/.test(lines[index])) {
          items.push(lines[index].replace(/^\s*\d+[.)]\s+/, ''));
          index += 1;
        }
        output.push(`<ol>${items.map((item) => `<li>${inlineMarkdown(item)}</li>`).join('')}</ol>`);
        continue;
      }

      if (/^\s*>\s?/.test(line)) {
        flushParagraph();
        const quote = [];
        while (index < lines.length && /^\s*>\s?/.test(lines[index])) {
          quote.push(lines[index].replace(/^\s*>\s?/, ''));
          index += 1;
        }
        output.push(`<blockquote>${inlineMarkdown(quote.join(' '))}</blockquote>`);
        continue;
      }

      if (!line.trim()) {
        flushParagraph();
      } else {
        paragraph.push(line.trim());
      }
      index += 1;
    }
    flushParagraph();
    return output.join('\n');
  };

  const now = () => new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  const setStatus = (message) => { if (status) status.textContent = message; };
  const saveDraft = () => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ title: titleField.value, tags: tagsField.value, body: bodyField.value }));
      setStatus(`Saved locally · ${now()}`);
    } catch (error) {
      setStatus('Draft is open · browser storage is unavailable');
    }
  };

  const updatePreview = () => {
    const title = titleField.value.trim();
    const body = bodyField.value.trim();
    preview.innerHTML = title || body
      ? `${title ? `<h2 class="markdown-preview__title">${escapeHtml(title)}</h2>` : ''}${body ? renderMarkdown(body) : '<p class="markdown-preview__empty">Start writing to see the preview.</p>'}`
      : '<p class="markdown-preview__empty">Your rendered note will appear here.</p>';
    if (window.MathJax && typeof window.MathJax.typesetPromise === 'function') {
      window.MathJax.typesetPromise([preview]).catch(() => {});
    }
  };

  const loadDraft = () => {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
      if (saved) {
        titleField.value = saved.title || '';
        tagsField.value = saved.tags || '';
        bodyField.value = saved.body || '';
        setStatus(`Restored local draft · ${now()}`);
        return;
      }
    } catch (error) {
      // Ignore malformed local state and start with a clean draft.
    }
    bodyField.value = fallbackBody;
  };

  const slugify = (value) => value.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '').replace(/[\s-]+/g, '-').replace(/^-|-$/g, '').slice(0, 60) || 'technique-note';
  const today = () => new Date().toISOString().slice(0, 10);
  const yamlQuote = (value) => `"${String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, ' ')}"`;
  const excerptFromBody = () => {
    const text = bodyField.value.replace(/^\s*#+\s+/gm, '').replace(/[>*_`~-]/g, '').replace(/\s+/g, ' ').trim();
    return text.length > 160 ? `${text.slice(0, 157)}...` : text;
  };
  const toMarkdownFile = () => {
    const title = titleField.value.trim() || 'Untitled technique note';
    const tags = tagsField.value.split(',').map((tag) => tag.trim()).filter(Boolean);
    const tagLines = tags.length ? tags.map((tag) => `  - ${yamlQuote(tag)}`).join('\n') : '  - "technique"';
    const body = bodyField.value.trim() || fallbackBody;
    return `---\nlayout: post\ntitle: ${yamlQuote(title)}\ndate: ${today()}\nexcerpt: ${yamlQuote(excerptFromBody())}\ntags:\n${tagLines}\npublished: true\n---\n\n${body}\n`;
  };

  const download = () => {
    const title = titleField.value.trim() || 'technique-note';
    const blob = new Blob([toMarkdownFile()], { type: 'text/markdown;charset=utf-8' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `${today()}-${slugify(title)}.md`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(link.href);
    setStatus('Markdown file downloaded');
  };

  const copy = async () => {
    const markdown = toMarkdownFile();
    try {
      await navigator.clipboard.writeText(markdown);
      setStatus('Markdown copied with front matter');
    } catch (error) {
      const helper = document.createElement('textarea');
      helper.value = markdown;
      helper.style.position = 'fixed';
      helper.style.opacity = '0';
      document.body.appendChild(helper);
      helper.select();
      document.execCommand('copy');
      helper.remove();
      setStatus('Markdown copied with front matter');
    }
  };

  const insertAtCursor = (value) => {
    const start = bodyField.selectionStart ?? bodyField.value.length;
    const end = bodyField.selectionEnd ?? start;
    bodyField.value = `${bodyField.value.slice(0, start)}${value}${bodyField.value.slice(end)}`;
    bodyField.focus();
    const cursor = start + value.length;
    bodyField.setSelectionRange(cursor, cursor);
  };

  const insertImageFile = (file) => {
    if (!file || !file.type.startsWith('image/')) {
      setStatus('Please choose an image file');
      return;
    }
    const reader = new FileReader();
    reader.addEventListener('load', () => {
      const alt = file.name.replace(/\.[^.]+$/, '').replace(/[-_]+/g, ' ').trim() || 'Figure';
      insertAtCursor(`![${alt}](${reader.result})`);
      updatePreview();
      saveDraft();
      setStatus(`${file.name} inserted · embedded in this draft`);
    });
    reader.readAsDataURL(file);
  };

  const importMarkdown = (text) => {
    const match = text.match(/^---\s*\n([\s\S]*?)\n---\s*\n?([\s\S]*)$/);
    const frontMatter = match ? match[1] : '';
    const body = match ? match[2] : text;
    const title = frontMatter.match(/^title:\s*["']?(.+?)["']?\s*$/m);
    const tags = [...frontMatter.matchAll(/^\s*-\s*["']?(.+?)["']?\s*$/gm)].map((item) => item[1].trim());
    titleField.value = title ? title[1].replace(/["']$/g, '') : '';
    tagsField.value = tags.join(', ');
    bodyField.value = body.trim();
    updatePreview();
    saveDraft();
    setStatus('Markdown imported · edits are saved locally');
  };

  document.querySelectorAll('[data-editor-action]').forEach((button) => {
    button.addEventListener('click', () => {
      const action = button.dataset.editorAction;
      if (action === 'download') download();
      if (action === 'copy') copy();
      if (action === 'import') fileInput.click();
      if (action === 'image' && imageInput) imageInput.click();
      if (action === 'clear' && window.confirm('Clear this local draft?')) {
        titleField.value = '';
        tagsField.value = '';
        bodyField.value = '';
        localStorage.removeItem(STORAGE_KEY);
        updatePreview();
        setStatus('Draft cleared');
      }
    });
  });

  [titleField, tagsField, bodyField].forEach((field) => field.addEventListener('input', () => {
    updatePreview();
    saveDraft();
  }));
  fileInput.addEventListener('change', () => {
    const file = fileInput.files && fileInput.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.addEventListener('load', () => importMarkdown(String(reader.result || '')));
    reader.readAsText(file);
    fileInput.value = '';
  });
  if (imageInput) {
    imageInput.addEventListener('change', () => {
      const file = imageInput.files && imageInput.files[0];
      insertImageFile(file);
      imageInput.value = '';
    });
  }
  bodyField.addEventListener('paste', (event) => {
    const file = event.clipboardData && [...event.clipboardData.files].find((item) => item.type.startsWith('image/'));
    if (file) {
      event.preventDefault();
      insertImageFile(file);
    }
  });
  bodyField.addEventListener('dragover', (event) => event.preventDefault());
  bodyField.addEventListener('drop', (event) => {
    const file = event.dataTransfer && [...event.dataTransfer.files].find((item) => item.type.startsWith('image/'));
    if (file) {
      event.preventDefault();
      insertImageFile(file);
    }
  });

  loadDraft();
  updatePreview();
  let mathAttempts = 0;
  const typesetWhenReady = () => {
    if (window.MathJax && typeof window.MathJax.typesetPromise === 'function') {
      updatePreview();
    } else if (mathAttempts < 20) {
      mathAttempts += 1;
      window.setTimeout(typesetWhenReady, 250);
    }
  };
  typesetWhenReady();
})();

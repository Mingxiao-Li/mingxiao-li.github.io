# Mingxiao Li · Personal site

Minimal personal homepage and technical-notes blog for Mingxiao Li.

## Structure

- `index.html` — the homepage
- `_posts/` — published technique notes
- `_drafts/technique-note-template.md` — starter template for a new note
- `_layouts/` — the archive and post layouts
- `assets/css/` and `assets/js/` — homepage/blog styles and behavior
- `images/` — the portrait, favicon, and social preview image
- `personal_cv_industry.pdf` — the current CV

## Local preview

```bash
bundle install
bundle exec jekyll serve
```

Then open <http://localhost:4000/>.

The local `/year-archive/` fallback includes a small in-browser writing desk: Markdown editor, live preview, LaTeX formulas (`$...$` / `$$...$$`), image Markdown, local image paste/drag-and-drop, local autosave, `.md` import, and Markdown export with Jekyll front matter. The fallback is excluded from the GitHub Pages build. Online visitors see only the Jekyll archive and posts with `published: true`.

The editor does not upload files by itself; after editing, download the file, place it in `_posts/`, and push the change to GitHub Pages.

To publish a note, copy the draft template into `_posts/`, give it a date-based filename, set `published: true`, and replace the placeholder text.

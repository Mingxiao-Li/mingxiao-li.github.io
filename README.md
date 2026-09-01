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
- `MingxiaoStudio/` — the private macOS writing and publishing app

## Local preview

```bash
bundle install
bundle exec jekyll serve
```

Then open <http://localhost:4000/>.

The homepage Notes section and public `/year-archive/` page are read-only: visitors see only Jekyll posts with `published: true`, including each note's date, tags, excerpt, and reading link. Drafts and editing tools are kept out of the website; writing remains private to Mingxiao Studio.

For private editing, build and open the macOS app:

```bash
cd MingxiaoStudio
zsh build-app.sh
open "dist/Mingxiao Studio.app"
```

Mingxiao Studio stages all visible homepage content (metadata, portrait, research, education, publications, notes, service, contact, and footer) and offers a live local homepage preview before anything is pushed. It writes Markdown with live preview (headings, code, formulas, links, and images), keeps drafts in `_drafts/` (with private folders and multiple saved files), publishes notes into `_posts/`, and can commit and push the public files to GitHub.

Manual publishing remains possible: place a dated Markdown file in `_posts/` with `published: true`, then push the change to GitHub Pages.

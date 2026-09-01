# Mingxiao Studio

Mingxiao Studio is a private macOS workspace for maintaining the personal site in the parent repository.

## Build and launch

From this directory:

```bash
swift run
```

To create a clickable app bundle:

```bash
zsh build-app.sh
open "dist/Mingxiao Studio.app"
```

To install it, drag `dist/Mingxiao Studio.app` into the Mac `Applications` folder in Finder. The app is self-contained; the website repository can remain on the Desktop. If macOS shows an “unidentified developer” warning for this locally built app, right-click it, choose **Open**, and confirm once.

On first launch, choose the website repository folder (the folder containing `index.html` and `_config.yml`). The selected path is stored locally in macOS preferences.

## What it can do

- Edit all homepage content from Profile: metadata, portrait, introduction, research, education, publications, notes callout, service, contact, and footer.
- Choose a replacement portrait; Studio copies it into `images/`, shows it in the live preview, and includes that file only when you confirm the profile publish.
- Review homepage copy changes in a live in-app preview before saving or pushing them.
- Open a full local homepage preview at any time; it is generated under `.studio/preview/` and never replaces the website source.
- Click the preview navigation to jump between homepage sections; external links open in the system browser.
- Keep Markdown drafts in `_drafts/`, which are deliberately excluded from publish commits; create private subfolders from the Notes sidebar and choose the folder before saving.
- Use the visible pencil and × controls beside each draft file or folder to rename or delete it; Studio limits deletion to managed `_drafts/`/`_posts/` paths and asks for confirmation first.
- Write with a split source/preview editor.
- Insert H1–H3 headings, emphasis, code fences, blockquotes, lists, formulas, links, and local images.
- Copy selected images into `images/notes/` and insert a public-root Markdown path.
- Save a local draft, publish it into `_posts/`, and push the selected public files to GitHub with one guarded action.
- Move an existing published note back to `_drafts/` when it should no longer be public.

Profile edits are staged in `.studio/profile.json`; the website's `index.html` is only updated after the GitHub push confirmation. Drafts are grouped in the left Notes sidebar. **New folder** creates a private archive folder and **New file** creates a real Markdown file in the selected folder. After saving, every draft remains selectable there, so several notes can be open across one session without losing work.

The publish action uses the repository's existing `origin` remote and local Git credentials. If GitHub asks for authentication on the first push, complete that prompt once and reuse the same action afterwards.

The public website never includes the editor. Only files in `_posts/` with `published: true` appear in the public notes archive.

import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SiteStore: ObservableObject {
    @Published var siteURL: URL?
    @Published var profile = SiteProfile.defaults
    @Published private(set) var notes: [NoteDocument] = []
    @Published var selectedSection: StudioSection = .dashboard
    @Published var selectedNoteID: UUID?
    @Published var selectedDraftFolder = ""
    @Published var editorTitle = ""
    @Published var editorTags = ""
    @Published var editorDate = SiteStore.currentDate()
    @Published var editorBody = ""
    @Published var statusMessage = "Choose your website folder to begin."
    @Published var isBusy = false

    private let fileManager = FileManager.default
    private let sitePathKey = "MingxiaoStudio.sitePath"

    init() {
        restoreSite()
    }

    var draftCount: Int { notes.filter { !$0.published }.count }
    var publishedCount: Int { notes.filter(\.published).count }
    var selectedNote: NoteDocument? { notes.first { $0.id == selectedNoteID } }

    /// Folders under `_drafts/` are deliberately kept out of the public site.
    /// They are discovered on demand so the sidebar stays in sync with Finder.
    var draftFolders: [String] {
        guard let siteURL else { return [] }
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true)
        guard let enumerator = fileManager.enumerator(at: drafts, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return [] }
        return enumerator.compactMap { item -> String? in
            guard let url = item as? URL,
                  (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
            let relative = url.path.replacingOccurrences(of: drafts.path + "/", with: "")
            return relative.isEmpty ? nil : relative
        }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func restoreSite() {
        guard let path = UserDefaults.standard.string(forKey: sitePathKey) else { return }
        let url = URL(fileURLWithPath: path, isDirectory: true)
        guard isSiteRoot(url) else { return }
        siteURL = url
        loadSite()
    }

    func chooseSite() {
        let panel = NSOpenPanel()
        panel.title = "Choose your personal website folder"
        panel.message = "Select the folder that contains index.html and _config.yml."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard isSiteRoot(url) else {
            statusMessage = "That folder does not look like the website repository."
            return
        }
        siteURL = url
        UserDefaults.standard.set(url.path, forKey: sitePathKey)
        loadSite()
        statusMessage = "Connected to \(url.lastPathComponent)."
    }

    func loadSite() {
        guard let siteURL else { return }
        profile = loadProfile() ?? .defaults
        notes = scanNotes(in: siteURL)
        if let selectedNoteID, notes.contains(where: { $0.id == selectedNoteID }) {
            selectNote(selectedNoteID)
        }
    }

    func selectNote(_ id: UUID?) {
        selectedNoteID = id
        guard let id, let note = notes.first(where: { $0.id == id }) else {
            selectedDraftFolder = ""
            editorTitle = ""
            editorTags = ""
            editorDate = Self.currentDate()
            editorBody = Self.starterBody
            return
        }
        editorTitle = note.title
        editorTags = note.tags.joined(separator: ", ")
        editorDate = note.date
        editorBody = note.body
        selectedDraftFolder = Self.folderPath(for: note.fileURL, under: siteURL)
    }

    func newNote() {
        selectedNoteID = nil
        editorTitle = ""
        editorTags = "AI for Science, technique"
        editorDate = Self.currentDate()
        editorBody = Self.starterBody
        selectedSection = .notes
        statusMessage = "New private draft. Save it when you are ready."
    }

    /// Creates a real Markdown file immediately, then leaves it selected for continued editing.
    func createDraftFile() {
        guard siteURL != nil else {
            statusMessage = "Choose the website folder first."
            return
        }
        let alert = NSAlert()
        alert.messageText = "Create a Markdown file"
        alert.informativeText = "The file will be created in the selected private draft folder."
        let field = NSTextField(string: "")
        field.placeholderString = "Note title"
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Create file")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            statusMessage = "Enter a title for the Markdown file."
            return
        }
        selectedNoteID = nil
        editorTitle = title
        editorTags = "AI for Science, technique"
        editorDate = Self.currentDate()
        editorBody = Self.starterBody
        selectedSection = .notes
        _ = saveDraft()
    }

    func createDraftFolder() {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return
        }
        let alert = NSAlert()
        alert.messageText = "Create a draft folder"
        alert.informativeText = "Use a short name such as experiments or reading-notes. This folder stays private."
        let field = NSTextField(string: "")
        field.placeholderString = "Folder name"
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Create folder")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let raw = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = raw.split(separator: "/").map(String.init).filter { $0 != "." && $0 != ".." }
        guard !components.isEmpty else {
            statusMessage = "Enter a valid folder name."
            return
        }
        let folder = components.map(Self.safeFolderComponent).filter { !$0.isEmpty }.joined(separator: "/")
        guard !folder.isEmpty else {
            statusMessage = "Enter a valid folder name."
            return
        }
        do {
            let folderURL = siteURL.appendingPathComponent("_drafts", isDirectory: true).appendingPathComponent(folder, isDirectory: true)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            selectedDraftFolder = folder
            statusMessage = "Draft folder created · \(folder)"
        } catch {
            statusMessage = "Could not create folder: \(error.localizedDescription)"
        }
    }

    func deleteNote(_ id: UUID) {
        guard let siteURL, let note = notes.first(where: { $0.id == id }), let fileURL = note.fileURL else {
            statusMessage = "Select a note file first."
            return
        }
        guard isManagedNoteURL(fileURL, siteURL: siteURL) else {
            statusMessage = "This file is outside the managed notes folders."
            return
        }
        let kind = note.published ? "published note" : "private draft"
        guard confirmDestructiveAction(title: "Delete \(kind)?", message: "\(fileURL.lastPathComponent) will be removed from the local repository. This cannot be undone from Studio.") else { return }
        do {
            try fileManager.removeItem(at: fileURL)
            if selectedNoteID == id { selectNote(nil) }
            notes = scanNotes(in: siteURL)
            statusMessage = note.published ? "Published note deleted locally. Push the deletion if you want it removed online." : "Draft deleted."
        } catch {
            statusMessage = "Could not delete note: \(error.localizedDescription)"
        }
    }

    func deleteDraftFolder(_ folder: String) {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return
        }
        let relative = Self.safeFolderPath(folder)
        guard !relative.isEmpty else {
            statusMessage = "The root Drafts folder cannot be deleted."
            return
        }
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true)
        let folderURL = drafts.appendingPathComponent(relative, isDirectory: true).standardizedFileURL
        let draftsRoot = drafts.standardizedFileURL.path + "/"
        guard folderURL.path.hasPrefix(draftsRoot), fileManager.fileExists(atPath: folderURL.path) else {
            statusMessage = "That draft folder could not be found."
            return
        }
        guard confirmDestructiveAction(title: "Delete folder \(relative)?", message: "Everything inside this private draft folder will be removed locally.") else { return }
        do {
            try fileManager.removeItem(at: folderURL)
            if selectedDraftFolder == relative || selectedDraftFolder.hasPrefix(relative + "/") {
                selectedDraftFolder = ""
                if let selectedNote, let fileURL = selectedNote.fileURL, fileURL.path.hasPrefix(folderURL.path + "/") {
                    selectNote(nil)
                }
            }
            notes = scanNotes(in: siteURL)
            statusMessage = "Draft folder deleted · \(relative)"
        } catch {
            statusMessage = "Could not delete folder: \(error.localizedDescription)"
        }
    }

    func renameNote(_ id: UUID) {
        guard let siteURL, let note = notes.first(where: { $0.id == id }), let source = note.fileURL else {
            statusMessage = "Select a note file first."
            return
        }
        guard isManagedNoteURL(source, siteURL: siteURL) else {
            statusMessage = "This file is outside the managed notes folders."
            return
        }
        let alert = NSAlert()
        alert.messageText = "Rename note"
        alert.informativeText = "The Markdown title and filename will be updated together."
        let field = NSTextField(string: note.title)
        field.frame = NSRect(x: 0, y: 0, width: 300, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            statusMessage = "Enter a title for the note."
            return
        }
        let filename = note.published ? "\(note.date)-\(Self.slugify(title)).md" : "\(Self.slugify(title)).md"
        let destination = source.deletingLastPathComponent().appendingPathComponent(filename)
        guard destination.standardizedFileURL == source.standardizedFileURL || !fileManager.fileExists(atPath: destination.path) else {
            statusMessage = "A note with that filename already exists in this folder."
            return
        }
        do {
            let sourceText = try String(contentsOf: source, encoding: .utf8)
            let updatedText = replaceFrontMatterTitle(in: sourceText, title: title)
            try updatedText.write(to: destination, atomically: true, encoding: .utf8)
            if destination.standardizedFileURL != source.standardizedFileURL {
                try fileManager.removeItem(at: source)
            }
            reloadAndSelect(destination)
            statusMessage = "Note renamed · \(destination.lastPathComponent)"
        } catch {
            statusMessage = "Could not rename note: \(error.localizedDescription)"
        }
    }

    func renameDraftFolder(_ folder: String) {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return
        }
        let relative = Self.safeFolderPath(folder)
        guard !relative.isEmpty else {
            statusMessage = "The root Drafts folder cannot be renamed."
            return
        }
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true)
        let source = drafts.appendingPathComponent(relative, isDirectory: true).standardizedFileURL
        let draftsRoot = drafts.standardizedFileURL.path + "/"
        guard source.path.hasPrefix(draftsRoot), fileManager.fileExists(atPath: source.path) else {
            statusMessage = "That draft folder could not be found."
            return
        }
        let alert = NSAlert()
        alert.messageText = "Rename folder"
        alert.informativeText = "All Markdown files inside the folder will stay in place."
        let field = NSTextField(string: source.lastPathComponent)
        field.frame = NSRect(x: 0, y: 0, width: 300, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let newName = Self.safeFolderComponent(field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !newName.isEmpty else {
            statusMessage = "Enter a valid folder name."
            return
        }
        let parent = source.deletingLastPathComponent()
        let destination = parent.appendingPathComponent(newName, isDirectory: true)
        guard destination.standardizedFileURL == source.standardizedFileURL || !fileManager.fileExists(atPath: destination.path) else {
            statusMessage = "A folder with that name already exists here."
            return
        }
        let parentRelative = URL(fileURLWithPath: relative).deletingLastPathComponent().path
        let newRelative = parentRelative == "." ? newName : "\(parentRelative)/\(newName)"
        let oldPrefix = source.path + "/"
        var selectedReplacement: URL?
        if let selectedURL = selectedNote?.fileURL, selectedURL.path.hasPrefix(oldPrefix) {
            selectedReplacement = URL(fileURLWithPath: destination.path + "/" + String(selectedURL.path.dropFirst(oldPrefix.count)))
        }
        do {
            try fileManager.moveItem(at: source, to: destination)
            if selectedDraftFolder == relative || selectedDraftFolder.hasPrefix(relative + "/") {
                selectedDraftFolder = newRelative + String(selectedDraftFolder.dropFirst(relative.count))
            }
            notes = scanNotes(in: siteURL)
            if let selectedReplacement { reloadAndSelect(selectedReplacement) }
            statusMessage = "Draft folder renamed · \(newRelative)"
        } catch {
            statusMessage = "Could not rename folder: \(error.localizedDescription)"
        }
    }

    private func replaceFrontMatterTitle(in source: String, title: String) -> String {
        var lines = source.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
              let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---" }) else { return source }
        if let titleIndex = lines[1..<end].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("title:") }) {
            let indentation = String(lines[titleIndex].prefix { $0 == " " || $0 == "\t" })
            lines[titleIndex] = "\(indentation)title: \(Self.yamlQuote(title))"
        }
        return lines.joined(separator: "\n")
    }

    private func confirmDestructiveAction(title: String, message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func isManagedNoteURL(_ url: URL, siteURL: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true).standardizedFileURL.path + "/"
        let posts = siteURL.appendingPathComponent("_posts", isDirectory: true).standardizedFileURL.path + "/"
        return path.hasPrefix(drafts) || path.hasPrefix(posts)
    }

    @discardableResult
    func saveProfile() -> Bool {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return false
        }
        do {
            let studio = siteURL.appendingPathComponent(".studio", isDirectory: true)
            try fileManager.createDirectory(at: studio, withIntermediateDirectories: true)
            let profileURL = studio.appendingPathComponent("profile.json")
            let data = try JSONEncoder.pretty.encode(profile)
            try data.write(to: profileURL, options: .atomic)
            statusMessage = "Profile staged locally. Preview it before publishing."
            return true
        } catch {
            statusMessage = "Could not save profile: \(error.localizedDescription)"
            return false
        }
    }

    func discardProfileChanges() {
        profile = loadProfile() ?? .defaults
        statusMessage = "Profile changes discarded."
    }

    func openHomepagePreview() {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return
        }
        guard saveProfile() else { return }
        do {
            let studio = siteURL.appendingPathComponent(".studio", isDirectory: true)
            let previewRoot = studio.appendingPathComponent("preview", isDirectory: true)
            if fileManager.fileExists(atPath: previewRoot.path) {
                try fileManager.removeItem(at: previewRoot)
            }
            try fileManager.createDirectory(at: previewRoot, withIntermediateDirectories: true)
            for directory in ["assets", "images", "year-archive"] {
                let source = siteURL.appendingPathComponent(directory, isDirectory: true)
                let destination = previewRoot.appendingPathComponent(directory, isDirectory: true)
                if fileManager.fileExists(atPath: source.path) {
                    try fileManager.copyItem(at: source, to: destination)
                }
            }
            for filename in ["index.html", "personal_cv_industry.pdf"] {
                let source = siteURL.appendingPathComponent(filename)
                if fileManager.fileExists(atPath: source.path) {
                    try fileManager.copyItem(at: source, to: previewRoot.appendingPathComponent(filename))
                }
            }
            let previewIndex = previewRoot.appendingPathComponent("index.html")
            try updatePage(in: previewRoot, profile: profile)
            NSWorkspace.shared.open(previewIndex)
            statusMessage = "Opened local homepage preview. Nothing has been pushed."
        } catch {
            statusMessage = "Could not prepare homepage preview: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func saveDraft() -> Bool {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return false
        }
        let title = editorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            statusMessage = "Add a title before saving this note."
            return false
        }
        do {
            let targetURL = draftURL(for: siteURL, title: title)
            try fileManager.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try markdownFile(published: false)
                .write(to: targetURL, atomically: true, encoding: .utf8)
            reloadAndSelect(targetURL)
            statusMessage = "Draft saved locally · \(targetURL.lastPathComponent)"
            return true
        } catch {
            statusMessage = "Could not save draft: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func publishCurrentLocally() -> Bool {
        guard let siteURL else {
            statusMessage = "Choose the website folder first."
            return false
        }
        let title = editorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            statusMessage = "Add a title before publishing this note."
            return false
        }
        do {
            let posts = siteURL.appendingPathComponent("_posts", isDirectory: true)
            try fileManager.createDirectory(at: posts, withIntermediateDirectories: true)
            let targetURL = posts.appendingPathComponent("\(editorDate)-\(Self.slugify(title)).md")
            try markdownFile(published: true).write(to: targetURL, atomically: true, encoding: .utf8)
            if let source = selectedNote?.fileURL,
               (source.path.contains("/_drafts/") || source.path.contains("/_posts/")),
               source.standardizedFileURL != targetURL.standardizedFileURL {
                try? fileManager.removeItem(at: source)
            }
            reloadAndSelect(targetURL)
            statusMessage = "Published locally. Review once, then push to GitHub."
            return true
        } catch {
            statusMessage = "Could not publish note: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func unpublishCurrent() -> Bool {
        guard let siteURL, let source = selectedNote?.fileURL, selectedNote?.published == true else {
            statusMessage = "Select a published note first."
            return false
        }
        do {
            let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true)
            try fileManager.createDirectory(at: drafts, withIntermediateDirectories: true)
            let target = drafts.appendingPathComponent(source.lastPathComponent)
            if fileManager.fileExists(atPath: target.path) { try fileManager.removeItem(at: target) }
            try fileManager.moveItem(at: source, to: target)
            reloadAndSelect(target)
            statusMessage = "Moved back to private drafts."
            return true
        } catch {
            statusMessage = "Could not move note to drafts: \(error.localizedDescription)"
            return false
        }
    }

    func publishToGitHub() {
        guard publishCurrentLocally() else { return }
        pushSiteChanges(message: "Publish note: \(editorTitle)")
    }

    func pushProfileToGitHub() {
        guard saveProfile() else { return }
        guard confirmPush() else { return }
        guard let siteURL else { return }
        do {
            try updatePage(in: siteURL, profile: profile)
        } catch {
            statusMessage = "Could not prepare profile update: \(error.localizedDescription)"
            return
        }
        pushSiteChanges(message: "Update profile", confirmed: true, extraPaths: [Self.safeRelativePath(profile.photoPath, fallback: "images/mingxiao-li.png")])
    }

    func pushSiteChanges(message: String, confirmed: Bool = false, extraPaths: [String] = []) {
        guard let siteURL, !isBusy else { return }
        guard confirmed || confirmPush() else { return }

        isBusy = true
        statusMessage = "Publishing…"
        let paths = (["index.html", "_posts", "images/notes"] + extraPaths).filter {
            fileManager.fileExists(atPath: siteURL.appendingPathComponent($0).path)
        }
        guard !paths.isEmpty else {
            isBusy = false
            statusMessage = "No publishable site files found."
            return
        }
        let add = runGit(["add"] + paths, in: siteURL)
        guard add.status == 0 else {
            isBusy = false
            statusMessage = "Git add failed: \(add.output.trimmingCharacters(in: .whitespacesAndNewlines))"
            return
        }
        let commit = runGit(["commit", "-m", message], in: siteURL)
        if commit.status != 0 && !commit.output.localizedCaseInsensitiveContains("nothing to commit") {
            isBusy = false
            statusMessage = "Commit failed: \(commit.output.trimmingCharacters(in: .whitespacesAndNewlines))"
            return
        }
        let branchResult = runGit(["branch", "--show-current"], in: siteURL)
        let branch = branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "master"
            : branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let push = runGit(["push", "origin", branch], in: siteURL)
        isBusy = false
        if push.status == 0 {
            statusMessage = "Published to GitHub · \(branch)."
        } else {
            statusMessage = "Push failed: \(push.output.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }

    private func confirmPush() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Push changes to GitHub?"
        alert.informativeText = "This will commit the selected site files and push them to origin. Private drafts in _drafts are not included."
        alert.addButton(withTitle: "Push to GitHub")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func chooseImageMarkdown() -> String? {
        guard let siteURL else {
            statusMessage = "Choose the website folder before importing an image."
            return nil
        }
        let panel = NSOpenPanel()
        panel.title = "Insert an image into this note"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let source = panel.url else { return nil }
        do {
            let imageDirectory = siteURL.appendingPathComponent("images/notes", isDirectory: true)
            try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            let filename = Self.safeFilename(source.lastPathComponent)
            var destination = imageDirectory.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: destination.path) {
                let stem = destination.deletingPathExtension().lastPathComponent
                let ext = destination.pathExtension
                destination = imageDirectory.appendingPathComponent("\(stem)-\(Int(Date().timeIntervalSince1970)).\(ext)")
            }
            try fileManager.copyItem(at: source, to: destination)
            statusMessage = "Image copied into images/notes."
            return "![\(source.deletingPathExtension().lastPathComponent)](/images/notes/\(destination.lastPathComponent))"
        } catch {
            statusMessage = "Could not import image: \(error.localizedDescription)"
            return nil
        }
    }

    func chooseProfilePhoto() {
        guard let siteURL else {
            statusMessage = "Choose the website folder before changing the profile photo."
            return
        }
        let panel = NSOpenPanel()
        panel.title = "Choose a profile photo"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let source = panel.url else { return }
        do {
            let images = siteURL.appendingPathComponent("images", isDirectory: true)
            try fileManager.createDirectory(at: images, withIntermediateDirectories: true)
            let ext = source.pathExtension.lowercased().isEmpty ? "png" : source.pathExtension.lowercased()
            let destination = images.appendingPathComponent("profile-photo.\(ext)")
            if fileManager.fileExists(atPath: destination.path) { try fileManager.removeItem(at: destination) }
            try fileManager.copyItem(at: source, to: destination)
            profile.photoPath = "images/\(destination.lastPathComponent)"
            statusMessage = "Profile photo staged locally. Preview it before publishing."
        } catch {
            statusMessage = "Could not import profile photo: \(error.localizedDescription)"
        }
    }

    func openSiteFolder() {
        guard let siteURL else { return }
        NSWorkspace.shared.open(siteURL)
    }

    private func isSiteRoot(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: url.appendingPathComponent("index.html").path)
            && fileManager.fileExists(atPath: url.appendingPathComponent("_config.yml").path)
    }

    private func loadProfile() -> SiteProfile? {
        guard let siteURL else { return nil }
        let url = siteURL.appendingPathComponent(".studio/profile.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SiteProfile.self, from: data)
    }

    private func updatePage(in siteURL: URL, profile: SiteProfile) throws {
        let indexURL = siteURL.appendingPathComponent("index.html")
        var html = try String(contentsOf: indexURL, encoding: .utf8)
        guard html.contains("id=\"top\""), html.contains("id=\"research\""), html.contains("id=\"publications\"") else {
            throw StudioError.pageSectionsMissing
        }

        html = replaceTag("title", in: html, with: profile.pageTitle)
        html = replaceMeta(prefix: "<meta name=\"description\" content=\"", in: html, with: profile.metaDescription)
        html = replaceMeta(prefix: "<meta property=\"og:title\" content=\"", in: html, with: profile.pageTitle)
        html = replaceMeta(prefix: "<meta property=\"og:description\" content=\"", in: html, with: profile.metaDescription)
        html = replaceMeta(prefix: "<meta name=\"twitter:title\" content=\"", in: html, with: profile.pageTitle)
        html = replaceMeta(prefix: "<meta name=\"twitter:description\" content=\"", in: html, with: profile.metaDescription)

        html = replaceSection(id: "top", in: html, with: profileSectionHTML(profile))
        html = replaceSection(id: "research", in: html, with: researchSectionHTML(profile))
        html = replaceSection(id: "education", in: html, with: educationSectionHTML(profile))
        html = replaceSection(id: "publications", in: html, with: publicationsSectionHTML(profile))
        html = replaceSection(id: "notes", in: html, with: notesSectionHTML(profile))
        html = replaceSection(id: "service", in: html, with: serviceSectionHTML(profile))
        html = replaceSection(id: "contact", in: html, with: contactSectionHTML(profile))
        html = replaceFooter(in: html, with: footerHTML(profile))
        try html.write(to: indexURL, atomically: true, encoding: .utf8)
    }

    private func profileSectionHTML(_ profile: SiteProfile) -> String {
        let esc = Self.htmlEscape
        let mentor = "Prof. Marie-Francine Moens"
        let mentorLink = "<a href=\"https://people.cs.kuleuven.be/~sien.moens/\" target=\"_blank\" rel=\"noreferrer\">\(mentor)</a>"
        let previousWork = esc(profile.previousWork).replacingOccurrences(of: esc(mentor), with: mentorLink)
        let photoPath = Self.safeRelativePath(profile.photoPath, fallback: "images/mingxiao-li.png")
        return """
        <section class="profile" id="top" aria-labelledby="profile-title">
          <div class="profile__copy">
            <p class="eyebrow">\(esc(profile.eyebrow))</p>
            <h1 id="profile-title">\(esc(profile.name))</h1>
            <p class="profile__lead">\(esc(profile.lead))</p>
            <p>\(esc(profile.currentFocus))</p>
            <p>\(previousWork)</p>
            <p class="profile__links">
              <a href="mailto:\(esc(profile.email))">Email</a>
              <a href="\(esc(profile.github))" target="_blank" rel="noreferrer">GitHub</a>
              <a href="\(esc(profile.scholar))" target="_blank" rel="noreferrer">Google Scholar</a>
              <a href="\(esc(profile.zhihu))" target="_blank" rel="noreferrer">Zhihu</a>
            </p>
          </div>
          <figure class="profile__photo">
            <img src="\(esc(photoPath))" alt="\(esc(profile.photoAlt))" width="630" height="784">
            <figcaption>\(esc(profile.photoCaption))</figcaption>
          </figure>
        </section>
        """
    }

    private func researchSectionHTML(_ profile: SiteProfile) -> String {
        let rows = delimitedLines(profile.researchItems).map { columns in
            let title = columns.first ?? "Research"
            let description = columns.dropFirst().joined(separator: " | ")
            return "<li><strong>\(Self.htmlEscape(title))</strong><span>\(Self.htmlEscape(description))</span></li>"
        }.joined(separator: "\n          ")
        return """
        <section class="content-section" id="research" aria-labelledby="research-title">
          <h2 id="research-title">\(Self.htmlEscape(profile.researchHeading))</h2>
          <p>\(Self.htmlEscape(profile.researchIntro))</p>
          <ul class="focus-list">
            \(rows)
          </ul>
        </section>
        """
    }

    private func educationSectionHTML(_ profile: SiteProfile) -> String {
        let rows = delimitedLines(profile.educationItems).map { columns in
            let period = columns.first ?? ""
            let degree = columns.count > 1 ? columns[1] : ""
            let institution = columns.count > 2 ? columns[2] : ""
            return "<div class=\"education-row\"><span>\(Self.htmlEscape(period))</span><p><strong>\(Self.htmlEscape(degree))</strong><br>\(Self.htmlEscape(institution))</p></div>"
        }.joined(separator: "\n          ")
        return """
        <section class="content-section" id="education" aria-labelledby="education-title">
          <h2 id="education-title">\(Self.htmlEscape(profile.educationHeading))</h2>
          <div class="education-list">
            \(rows)
          </div>
        </section>
        """
    }

    private func publicationsSectionHTML(_ profile: SiteProfile) -> String {
        let rows = delimitedLines(profile.publicationItems).map { columns in
            let venue = columns.first ?? ""
            let title = columns.count > 1 ? columns[1] : ""
            let url = columns.count > 2 ? Self.safeURL(columns[2]) : nil
            let link = url.map { " <a href=\"\(Self.htmlEscape($0))\" target=\"_blank\" rel=\"noreferrer\">[Paper]</a>" } ?? ""
            return "<li><span>\(Self.htmlEscape(venue))</span><p><strong>\(Self.htmlEscape(title))</strong>\(link)</p></li>"
        }.joined(separator: "\n          ")
        return """
        <section class="content-section" id="publications" aria-labelledby="publications-title">
          <div class="section-heading">
            <h2 id="publications-title">\(Self.htmlEscape(profile.publicationsHeading))</h2>
            <a href="\(Self.htmlEscape(profile.scholar))" target="_blank" rel="noreferrer">Full list on Google Scholar ↗</a>
          </div>
          <ol class="publication-list">
            \(rows)
          </ol>
        </section>
        """
    }

    private func notesSectionHTML(_ profile: SiteProfile) -> String {
        return """
        <section class="content-section notes-section" id="notes" aria-labelledby="notes-title">
          <div class="section-heading">
            <h2 id="notes-title">\(Self.htmlEscape(profile.notesHeading))</h2>
            <a href="year-archive/">View all notes ↗</a>
          </div>
          <p>\(Self.htmlEscape(profile.notesIntro))</p>
          {% assign published_notes = site.posts | where: "published", true %}
          {% if published_notes.size > 0 %}
            <div class="home-notes-list">
              {% for post in published_notes %}
                <article class="home-note">
                  <div class="home-note__meta">
                    <time datetime="{{ post.date | date: '%Y-%m-%d' }}">{{ post.date | date: "%b %Y" }}</time>
                    {% for tag in post.tags limit: 2 %}<span>{{ tag }}</span>{% endfor %}
                  </div>
                  <div class="home-note__body">
                    <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
                    <p>{{ post.excerpt | strip_html | strip_newlines | truncate: 180 }}</p>
                  </div>
                  <a class="home-note__link" href="{{ post.url | relative_url }}">Read note ↗</a>
                </article>
              {% endfor %}
            </div>
          {% else %}
            <p class="home-notes-empty">No published notes yet. New technical notes will appear here after they are published.</p>
          {% endif %}
        </section>
        """
    }

    private func serviceSectionHTML(_ profile: SiteProfile) -> String {
        let academic = profile.serviceAcademic.components(separatedBy: "\n\n")
        let primary = Self.multilineHTML(academic.first ?? profile.serviceAcademic)
        let muted = academic.dropFirst().map(Self.multilineHTML).joined(separator: "<br><br>")
        let awards = Self.multilineHTML(profile.serviceAwards)
        return """
        <section class="content-section" id="service" aria-labelledby="service-title">
          <h2 id="service-title">\(Self.htmlEscape(profile.serviceHeading))</h2>
          <div class="service-grid">
            <div>
              <h3>Academic service</h3>
              <p>\(primary)</p>
              <p class="muted">\(muted)</p>
            </div>
            <div>
              <h3>Awards</h3>
              <p>\(awards)</p>
            </div>
          </div>
        </section>
        """
    }

    private func contactSectionHTML(_ profile: SiteProfile) -> String {
        """
        <section class="content-section contact-section" id="contact" aria-labelledby="contact-title">
          <h2 id="contact-title">\(Self.htmlEscape(profile.contactHeading))</h2>
          <p>\(Self.htmlEscape(profile.contactIntro))</p>
          <a class="contact-email" href="mailto:\(Self.htmlEscape(profile.email))">\(Self.htmlEscape(profile.email))</a>
          <div class="visit-counter" aria-label="Site visit statistics">
            <div id="busuanzi_container_site_pv"><strong id="busuanzi_value_site_pv">—</strong><span>Page views</span></div>
            <div id="busuanzi_container_site_uv"><strong id="busuanzi_value_site_uv">—</strong><span>Visitors</span></div>
          </div>
        </section>
        """
    }

    private func footerHTML(_ profile: SiteProfile) -> String {
        """
        <footer class="site-footer">
          <div>
            <span>\(Self.htmlEscape(profile.footerCopyright))</span>
            <span>\(Self.htmlEscape(profile.footerLocation))</span>
          </div>
          <div>
            <span>\(Self.htmlEscape(profile.footerTimezone)) · <span id="local-time">--:--</span></span>
            <span>Last update · \(Self.htmlEscape(profile.footerLastUpdate))</span>
          </div>
        </footer>
        """
    }

    private func replaceSection(id: String, in html: String, with replacement: String) -> String {
        guard let idRange = html.range(of: "id=\"\(id)\""),
              let openingStart = html[..<idRange.lowerBound].lastIndex(of: "<"),
              let openingEnd = html.range(of: ">", range: idRange.upperBound..<html.endIndex),
              let closing = html.range(of: "</section>", range: openingEnd.upperBound..<html.endIndex) else { return html }
        var result = html
        result.replaceSubrange(openingStart..<closing.upperBound, with: replacement)
        return result
    }

    private func replaceFooter(in html: String, with replacement: String) -> String {
        guard let openingStart = html.range(of: "<footer"),
              let openingEnd = html.range(of: ">", range: openingStart.upperBound..<html.endIndex),
              let closing = html.range(of: "</footer>", range: openingEnd.upperBound..<html.endIndex) else { return html }
        var result = html
        result.replaceSubrange(openingStart.lowerBound..<closing.upperBound, with: replacement)
        return result
    }

    private func replaceTag(_ tag: String, in html: String, with value: String) -> String {
        guard let opening = html.range(of: "<\(tag)>"),
              let closing = html.range(of: "</\(tag)>", range: opening.upperBound..<html.endIndex) else { return html }
        var result = html
        result.replaceSubrange(opening.upperBound..<closing.lowerBound, with: Self.htmlEscape(value))
        return result
    }

    private func replaceMeta(prefix: String, in html: String, with value: String) -> String {
        guard let start = html.range(of: prefix),
              let end = html.range(of: "\"", range: start.upperBound..<html.endIndex) else { return html }
        var result = html
        result.replaceSubrange(start.upperBound..<end.lowerBound, with: Self.htmlEscape(value))
        return result
    }

    private func delimitedLines(_ value: String) -> [[String]] {
        value.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return trimmed.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        }
    }

    private static func multilineHTML(_ value: String) -> String {
        htmlEscape(value).replacingOccurrences(of: "\n", with: "<br>")
    }

    private static func safeURL(_ value: String) -> String? {
        let url = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard url.lowercased().hasPrefix("https://") || url.lowercased().hasPrefix("http://") else { return nil }
        return url
    }

    static func safeRelativePath(_ value: String, fallback: String) -> String {
        let path = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains(".."), !path.contains("\\") else { return fallback }
        return path
    }

    private func scanNotes(in siteURL: URL) -> [NoteDocument] {
        let directories = ["_drafts", "_posts"].map { siteURL.appendingPathComponent($0, isDirectory: true) }
        return directories.flatMap { directory -> [NoteDocument] in
            guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { return [] }
            return enumerator.compactMap { item -> NoteDocument? in
                guard let url = item as? URL,
                      url.pathExtension.lowercased() == "md",
                      url.lastPathComponent != "technique-note-template.md" else { return nil }
                return parseNote(url)
            }
        }.sorted { lhs, rhs in
            if lhs.published != rhs.published { return lhs.published && !rhs.published }
            return lhs.date > rhs.date
        }
    }

    private func parseNote(_ url: URL) -> NoteDocument? {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = source.components(separatedBy: .newlines)
        var front: [String: String] = [:]
        var tags: [String] = []
        var bodyStart = 0
        if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---",
           let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---" }) {
            bodyStart = end + 1
            var currentKey = ""
            for line in lines[1..<end] {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("-") && currentKey == "tags" {
                    tags.append(Self.unquote(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)))
                } else if let colon = trimmed.firstIndex(of: ":") {
                    currentKey = String(trimmed[..<colon]).lowercased()
                    front[currentKey] = Self.unquote(String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(in: .whitespaces))
                }
            }
        }
        let body = lines.dropFirst(bodyStart).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "-", with: " ").capitalized
        let title = front["title"]?.isEmpty == false ? front["title"]! : fallbackTitle
        let date = front["date"]?.isEmpty == false ? front["date"]! : String(url.deletingPathExtension().lastPathComponent.prefix(10))
        let published = front["published"]?.lowercased() != "false" && url.path.contains("/_posts/")
        return NoteDocument(title: title, tags: tags, body: body, date: date, published: published, fileURL: url)
    }

    private func draftURL(for siteURL: URL, title: String) -> URL {
        if let selectedURL = selectedNote?.fileURL, selectedURL.path.contains("/_drafts/") { return selectedURL }
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true)
        let folder = selectedDraftFolder.trimmingCharacters(in: .whitespacesAndNewlines)
        let directory = folder.isEmpty ? drafts : drafts.appendingPathComponent(folder, isDirectory: true)
        return directory.appendingPathComponent("\(Self.slugify(title)).md")
    }

    private static func folderPath(for url: URL?, under siteURL: URL?) -> String {
        guard let url, let siteURL else { return "" }
        let drafts = siteURL.appendingPathComponent("_drafts", isDirectory: true).standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(drafts) else { return "" }
        let relative = String(path.dropFirst(drafts.count))
        return URL(fileURLWithPath: relative).deletingLastPathComponent().path == "." ? "" : URL(fileURLWithPath: relative).deletingLastPathComponent().path
    }

    private func reloadAndSelect(_ url: URL) {
        notes = scanNotes(in: siteURL!)
        selectedNoteID = notes.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL })?.id
        selectNote(selectedNoteID)
    }

    private func markdownFile(published: Bool) -> String {
        let title = editorTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled technique note" : editorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = editorTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let tagLines = tags.isEmpty ? "  - \"technique\"" : tags.map { "  - \(Self.yamlQuote(String($0)))" }.joined(separator: "\n")
        let body = editorBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.starterBody : editorBody.trimmingCharacters(in: .whitespacesAndNewlines)
        return "---\nlayout: post\ntitle: \(Self.yamlQuote(title))\ndate: \(editorDate)\nexcerpt: \(Self.yamlQuote(Self.excerpt(from: body)))\ntags:\n\(tagLines)\npublished: \(published)\n---\n\n\(body)\n"
    }

    private func runGit(_ arguments: [String], in directory: URL) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        } catch {
            return (1, error.localizedDescription)
        }
    }

    static let starterBody = """
    ## The question

    What problem are you trying to solve, and why does it matter?

    ## The intuition

    Explain the key idea in plain language before introducing the details.

    ## The implementation

    Add equations, pseudocode, experiments, or links that make the idea reproducible.

    ```python
    # A small, reproducible experiment
    ```

    ## Takeaways

    - One idea worth remembering.
    - One practical detail worth reusing.
    """

    static func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    static func slugify(_ value: String) -> String {
        let allowed = value.lowercased().unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) { return Character(String(scalar)) }
            return "-"
        }
        let slug = String(allowed).split(separator: "-").joined(separator: "-").prefix(60).description
        return slug.isEmpty ? "note-\(Int(Date().timeIntervalSince1970))" : slug
    }

    static func safeFilename(_ value: String) -> String {
        let ext = URL(fileURLWithPath: value).pathExtension.lowercased()
        let stem = URL(fileURLWithPath: value).deletingPathExtension().lastPathComponent
        let clean = slugify(stem).isEmpty ? "figure" : slugify(stem)
        return ext.isEmpty ? clean : "\(clean).\(ext)"
    }

    static func safeFolderComponent(_ value: String) -> String {
        let clean = value.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_" { return Character(String(scalar)) }
            return "-"
        }
        return String(clean).trimmingCharacters(in: CharacterSet(charactersIn: "-_")).prefix(48).description
    }

    static func safeFolderPath(_ value: String) -> String {
        value.split(separator: "/")
            .map(String.init)
            .filter { $0 != "." && $0 != ".." }
            .map(safeFolderComponent)
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }

    static func htmlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#039;")
    }

    static func yamlQuote(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: " ") + "\""
    }

    static func excerpt(from body: String) -> String {
        let cleaned = body.replacingOccurrences(of: #"(?m)^\s*#+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "[*_`~>]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count > 160 ? String(cleaned.prefix(157)) + "..." : cleaned
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2, value.first == "\"", value.last == "\"" else { return value }
        return String(value.dropFirst().dropLast()).replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\\\", with: "\\")
    }
}

enum StudioError: LocalizedError {
    case profileMarkersMissing
    case pageSectionsMissing

    var errorDescription: String? {
        switch self {
        case .profileMarkersMissing: return "Profile markers are missing from index.html."
        case .pageSectionsMissing: return "The homepage sections could not be found in index.html."
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

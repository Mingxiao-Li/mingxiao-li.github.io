import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct RootView: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        Group {
            if store.siteURL == nil {
                SetupView()
            } else {
                StudioShell()
            }
        }
        .frame(minWidth: 980, minHeight: 660)
    }
}

struct SetupView: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color(red: 0.55, green: 0.2, blue: 0.16))
            Text("Mingxiao Studio")
                .font(.system(size: 30, weight: .semibold, design: .serif))
            Text("A private workspace for your homepage, research notes, and releases.")
                .foregroundStyle(.secondary)
            Button("Choose website folder") {
                store.chooseSite()
            }
            .buttonStyle(.borderedProminent)
            Text(store.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(60)
    }
}

struct StudioShell: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedSection) {
                Section("Studio") {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                        .tag(StudioSection.dashboard)
                    Label("Profile", systemImage: "person.crop.circle")
                        .tag(StudioSection.profile)
                    Label("Notes", systemImage: "note.text")
                        .tag(StudioSection.notes)
                }
            }
            .navigationTitle("Mingxiao Studio")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text(store.siteURL?.lastPathComponent ?? "No website selected")
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Button("Change folder") { store.chooseSite() }
                        .buttonStyle(.link)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }
        } detail: {
            switch store.selectedSection {
            case .dashboard:
                DashboardView()
            case .profile:
                ProfileView()
            case .notes:
                NotesView()
            }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeading(title: "Dashboard", subtitle: "A quiet control room for the public site.")
                HStack(spacing: 14) {
                    MetricCard(label: "Published notes", value: "\(store.publishedCount)", tint: .green)
                    MetricCard(label: "Private drafts", value: "\(store.draftCount)", tint: .orange)
                    MetricCard(label: "Site folder", value: store.siteURL?.lastPathComponent ?? "—", tint: .blue)
                }
                GroupBox("Quick actions") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            store.newNote()
                        } label: {
                            Label("Write a new technique note", systemImage: "square.and.pencil")
                        }
                        Button {
                            store.selectedSection = .profile
                        } label: {
                            Label("Update personal information", systemImage: "person.crop.circle")
                        }
                        Button {
                            store.openSiteFolder()
                        } label: {
                            Label("Open website folder in Finder", systemImage: "folder")
                        }
                        Button {
                            store.openHomepagePreview()
                        } label: {
                            Label("Open full homepage preview", systemImage: "safari")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                }
                Text(store.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PageHeading(title: "Profile", subtitle: "Edit on the left, then review the homepage preview before publishing.")
                Spacer()
                Button("Open full preview") { store.openHomepagePreview() }
                    .buttonStyle(.borderless)
                Button("Reload saved") { store.discardProfileChanges() }
                    .buttonStyle(.borderless)
                Button("Confirm & push to GitHub") { store.pushProfileToGitHub() }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isBusy)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            Divider()

            HSplitView {
                ScrollView {
                    Form {
                        Section("Identity") {
                            TextField("Name", text: $store.profile.name)
                            TextField("Eyebrow", text: $store.profile.eyebrow)
                            TextField("Email", text: $store.profile.email)
                        }
                        Section("Portrait") {
                            HStack(spacing: 10) {
                                TextField("Photo path", text: $store.profile.photoPath)
                                Button("Choose photo") { store.chooseProfilePhoto() }
                            }
                            TextField("Alt text", text: $store.profile.photoAlt)
                            TextField("Caption", text: $store.profile.photoCaption)
                        }
                        Section("Page metadata") {
                            TextField("Browser title", text: $store.profile.pageTitle, axis: .vertical)
                                .lineLimit(1...2)
                            LabeledContent("Description") {
                                TextEditor(text: $store.profile.metaDescription)
                                    .frame(minHeight: 64)
                            }
                        }
                        Section("Homepage introduction") {
                            TextField("Lead sentence", text: $store.profile.lead, axis: .vertical)
                                .lineLimit(2...4)
                            LabeledContent("Current focus") {
                                TextEditor(text: $store.profile.currentFocus)
                                    .frame(minHeight: 100)
                            }
                            LabeledContent("Previous work") {
                                TextEditor(text: $store.profile.previousWork)
                                    .frame(minHeight: 80)
                            }
                        }
                        Section("Research") {
                            TextField("Section heading", text: $store.profile.researchHeading)
                            LabeledContent("Intro") {
                                TextEditor(text: $store.profile.researchIntro)
                                    .frame(minHeight: 58)
                            }
                            LabeledContent("Cards · one per line: title | description") {
                                TextEditor(text: $store.profile.researchItems)
                                    .frame(minHeight: 105)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        Section("Education") {
                            TextField("Section heading", text: $store.profile.educationHeading)
                            LabeledContent("Rows · period | degree | institution") {
                                TextEditor(text: $store.profile.educationItems)
                                    .frame(minHeight: 125)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        Section("Publications") {
                            TextField("Section heading", text: $store.profile.publicationsHeading)
                            LabeledContent("Rows · venue | title | paper URL") {
                                TextEditor(text: $store.profile.publicationItems)
                                    .frame(minHeight: 160)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        Section("Notes, service & contact") {
                            TextField("Notes heading", text: $store.profile.notesHeading)
                            LabeledContent("Notes introduction") {
                                TextEditor(text: $store.profile.notesIntro)
                                    .frame(minHeight: 58)
                            }
                            Text("Published notes from the site’s _posts folder appear here automatically. Drafts stay private until you publish them from Notes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            TextField("Service heading", text: $store.profile.serviceHeading)
                            LabeledContent("Academic service · blank line separates muted text") {
                                TextEditor(text: $store.profile.serviceAcademic)
                                    .frame(minHeight: 100)
                            }
                            LabeledContent("Awards · one per line") {
                                TextEditor(text: $store.profile.serviceAwards)
                                    .frame(minHeight: 72)
                            }
                            TextField("Contact heading", text: $store.profile.contactHeading)
                            TextField("Contact introduction", text: $store.profile.contactIntro, axis: .vertical)
                                .lineLimit(2...3)
                        }
                        Section("Footer") {
                            TextField("Copyright", text: $store.profile.footerCopyright)
                            TextField("Location", text: $store.profile.footerLocation)
                            TextField("Timezone label", text: $store.profile.footerTimezone)
                            TextField("Last update", text: $store.profile.footerLastUpdate)
                        }
                        Section("Links") {
                            TextField("GitHub", text: $store.profile.github)
                            TextField("Google Scholar", text: $store.profile.scholar)
                            TextField("Zhihu", text: $store.profile.zhihu)
                        }
                    }
                    .formStyle(.grouped)
                    .padding(20)
                }
                .frame(minWidth: 430, idealWidth: 500, maxWidth: 580)

                ProfilePreviewView(profile: store.profile, siteRoot: store.siteURL?.path ?? "")
                    .frame(minWidth: 490)
            }

            Divider()
            HStack {
                Text(store.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Save locally") { store.saveProfile() }
                    .buttonStyle(.bordered)
            }
            .padding(12)
        }
    }
}

struct ProfilePreviewView: NSViewRepresentable {
    let profile: SiteProfile
    let siteRoot: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        let baseURL = siteRoot.isEmpty ? nil : URL(fileURLWithPath: siteRoot, isDirectory: true)
        webView.loadHTMLString(Self.previewHTML, baseURL: baseURL)
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
        context.coordinator.render(profile: profile, siteRoot: siteRoot)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var loaded = false
        var pending = ""
        private var cachedPhotoPath = ""
        private var cachedPhotoDataURL: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            if !pending.isEmpty { webView.evaluateJavaScript(pending) }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if url.scheme == "http" || url.scheme == "https" || url.scheme == "mailto" {
                if navigationAction.navigationType == .linkActivated {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func render(profile: SiteProfile, siteRoot: String) {
            guard let profileData = try? JSONEncoder().encode(profile),
                  let profileJSON = String(data: profileData, encoding: .utf8) else { return }
            let imageJSON: String
            if let imageDataURL = imageDataURL(siteRoot: siteRoot, photoPath: profile.photoPath),
               let imageData = try? JSONEncoder().encode(imageDataURL),
               let encodedImage = String(data: imageData, encoding: .utf8) {
                imageJSON = encodedImage
            } else {
                imageJSON = "null"
            }
            pending = "window.renderProfile({profile:\(profileJSON),imageURL:\(imageJSON)});"
            guard loaded, let webView else { return }
            webView.evaluateJavaScript(pending)
        }

        private func imageDataURL(siteRoot: String, photoPath: String) -> String? {
            guard !siteRoot.isEmpty else { return nil }
            let relative = SiteStore.safeRelativePath(photoPath, fallback: "images/mingxiao-li.png")
            let cacheKey = "\(siteRoot)|\(relative)"
            if cacheKey == cachedPhotoPath { return cachedPhotoDataURL }
            let fileURL = URL(fileURLWithPath: siteRoot, isDirectory: true).appendingPathComponent(relative)
            guard let data = try? Data(contentsOf: fileURL) else {
                cachedPhotoPath = cacheKey
                cachedPhotoDataURL = nil
                return nil
            }
            let mime = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "image/png"
            let result = "data:\(mime);base64,\(data.base64EncodedString())"
            cachedPhotoPath = cacheKey
            cachedPhotoDataURL = result
            return result
        }
    }

    static var previewHTML: String {
        guard let url = Bundle.module.url(forResource: "profile-preview", withExtension: "html"),
              let html = try? String(contentsOf: url, encoding: .utf8) else {
            return "<html><body><p>Homepage preview unavailable.</p></body></html>"
        }
        return html
    }
}

struct NotesView: View {
    @EnvironmentObject private var store: SiteStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PageHeading(title: "Notes", subtitle: "Private drafts stay local until you publish them. Use the pencil and × buttons to manage items.")
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            Divider()
            HSplitView {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Button {
                            store.createDraftFolder()
                        } label: {
                            Label("Folder", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.borderless)
                        Button {
                            store.createDraftFile()
                        } label: {
                            Label("File", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    Divider()
                    List(selection: $store.selectedNoteID) {
                        if !store.draftFolders.isEmpty {
                            Section("Draft folders") {
                                Button {
                                    store.selectedDraftFolder = ""
                                    store.newNote()
                                } label: {
                                    Label("Drafts (root)", systemImage: "folder")
                                }
                                ForEach(store.draftFolders, id: \.self) { folder in
                                    HStack(spacing: 6) {
                                        Button {
                                            store.selectedDraftFolder = folder
                                            store.newNote()
                                        } label: {
                                            Label(folder, systemImage: "folder")
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)
                                        Button {
                                            store.renameDraftFolder(folder)
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Rename folder")
                                        Button {
                                            store.deleteDraftFolder(folder)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Delete folder")
                                    }
                                }
                            }
                        }
                        let drafts = store.notes.filter { !$0.published }
                        let published = store.notes.filter(\.published)
                        Section("Drafts · \(drafts.count)") {
                            if drafts.isEmpty {
                                Text("No drafts yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(drafts) { note in
                                    HStack(spacing: 6) {
                                        NoteRow(note: note)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Button {
                                            store.renameNote(note.id)
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Rename file")
                                        Button {
                                            store.deleteNote(note.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Delete file")
                                    }
                                    .tag(note.id)
                                }
                            }
                        }
                        Section("Published · \(published.count)") {
                            ForEach(published) { note in
                                HStack(spacing: 6) {
                                    NoteRow(note: note)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Button {
                                        store.renameNote(note.id)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Rename file")
                                    Button {
                                        store.deleteNote(note.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Delete file")
                                }
                                .tag(note.id)
                            }
                        }
                    }
                    .onChange(of: store.selectedNoteID) { id in
                        store.selectNote(id)
                    }
                    .onDeleteCommand {
                        if let id = store.selectedNoteID {
                            store.deleteNote(id)
                        }
                    }
                }
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 330)
                NoteEditorView()
                    .frame(minWidth: 620)
            }
        }
    }
}

struct NoteRow: View {
    let note: NoteDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(2)
            HStack(spacing: 7) {
                Circle()
                    .fill(note.published ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(note.published ? "Published" : "Draft")
                Text(note.date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if let fileURL = note.fileURL,
               let marker = fileURL.path.range(of: "/_drafts/") {
                let folder = String(fileURL.path[fileURL.path.index(after: marker.upperBound)..<fileURL.path.endIndex])
                    .split(separator: "/").dropLast().joined(separator: "/")
                if !folder.isEmpty {
                    Label(folder, systemImage: "folder")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct NoteEditorView: View {
    @EnvironmentObject private var store: SiteStore
    @StateObject private var controller = EditorController()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ToolbarButton(title: "H1") { controller.insert("# ") }
                ToolbarButton(title: "H2") { controller.insert("## ") }
                ToolbarButton(title: "H3") { controller.insert("### ") }
                Divider().frame(height: 18)
                ToolbarButton(title: "Bold") { controller.insert("**text**", selectionOffset: 2, selectionLength: 4) }
                ToolbarButton(title: "Italic") { controller.insert("*text*", selectionOffset: 1, selectionLength: 4) }
                ToolbarButton(title: "Code") { controller.insert("`code`", selectionOffset: 1, selectionLength: 4) }
                ToolbarButton(title: "Quote") { controller.insert("> ") }
                ToolbarButton(title: "List") { controller.insert("- ") }
                ToolbarButton(title: "1.") { controller.insert("1. ") }
                Divider().frame(height: 18)
                ToolbarButton(title: "Formula") { controller.insert("$x^2$", selectionOffset: 1, selectionLength: 3) }
                ToolbarButton(title: "Link") { controller.insert("[link text](https://example.com)", selectionOffset: 1, selectionLength: 9) }
                Button {
                    if let markdown = store.chooseImageMarkdown() {
                        controller.insert(markdown)
                    }
                } label: {
                    Label("Image", systemImage: "photo")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.bar)
            Divider()

            HStack(spacing: 10) {
                TextField("Note title", text: $store.editorTitle)
                    .textFieldStyle(.roundedBorder)
                Picker("Folder", selection: $store.selectedDraftFolder) {
                    Text("Drafts").tag("")
                    ForEach(store.draftFolders, id: \.self) { folder in
                        Text(folder).tag(folder)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
                TextField("Tags, comma separated", text: $store.editorTags)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                TextField("Date (YYYY-MM-DD)", text: $store.editorDate)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 135)
            }
            .padding(14)
            Divider()

            HSplitView {
                MarkdownTextView(text: $store.editorBody, insertion: controller.insertion)
                    .background(Color(nsColor: .textBackgroundColor))
                MarkdownPreviewView(title: store.editorTitle, markdown: store.editorBody, siteRoot: store.siteURL?.path ?? "")
                    .background(Color(nsColor: .controlBackgroundColor))
            }

            Divider()
            HStack {
                Text(store.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if store.selectedNote?.published == true {
                    Button("Move to draft") { store.unpublishCurrent() }
                        .buttonStyle(.borderless)
                }
                Button("Save draft") { store.saveDraft() }
                    .buttonStyle(.bordered)
                Button("Publish to GitHub") { store.publishToGitHub() }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isBusy)
            }
            .padding(12)
        }
    }
}

struct ToolbarButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderless)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 4)
    }
}

struct PageHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 9))
    }
}

final class EditorController: ObservableObject {
    @Published var insertion: EditorInsertion?

    func insert(_ text: String, selectionOffset: Int = 0, selectionLength: Int = 0) {
        insertion = EditorInsertion(text: text, selectionOffset: selectionOffset, selectionLength: selectionLength)
    }
}

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let insertion: EditorInsertion?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        let textView = NSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .labelColor
        textView.string = text
        textView.delegate = context.coordinator
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        scroll.documentView = textView
        context.coordinator.textView = textView
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            textView.string = text
            context.coordinator.isUpdating = false
        }
        if let insertion, context.coordinator.lastInsertionID != insertion.id {
            let start = textView.selectedRange().location
            textView.insertText(insertion.text, replacementRange: textView.selectedRange())
            if insertion.selectionLength > 0 {
                textView.setSelectedRange(NSRange(location: start + insertion.selectionOffset, length: insertion.selectionLength))
            }
            context.coordinator.lastInsertionID = insertion.id
            text = textView.string
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView
        weak var textView: NSTextView?
        var lastInsertionID: UUID?
        var isUpdating = false

        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView else { return }
            parent.text = textView.string
        }
    }
}

struct MarkdownPreviewView: NSViewRepresentable {
    let title: String
    let markdown: String
    let siteRoot: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(Self.previewHTML, baseURL: nil)
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.webView = webView
        context.coordinator.render(title: title, markdown: markdown, siteRoot: siteRoot)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var loaded = false
        var pending = ""

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            if !pending.isEmpty { webView.evaluateJavaScript(pending) }
        }

        func render(title: String, markdown: String, siteRoot: String) {
            let payload: [String: String] = ["title": title, "markdown": markdown, "siteRoot": siteRoot]
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            pending = "window.renderPreview(\(json));"
            guard loaded, let webView else { return }
            webView.evaluateJavaScript(pending)
        }
    }

    static var previewHTML: String {
        if let url = Bundle.module.url(forResource: "editor-preview", withExtension: "html"),
           let html = try? String(contentsOf: url, encoding: .utf8) {
            return html
        }
        return "<html><body><p>Preview unavailable.</p></body></html>"
    }
}

import Foundation

struct SiteProfile: Codable, Equatable {
    var name: String
    var eyebrow: String
    var lead: String
    var currentFocus: String
    var previousWork: String
    var email: String
    var github: String
    var scholar: String
    var zhihu: String
    var photoPath: String
    var photoAlt: String
    var photoCaption: String
    var pageTitle: String
    var metaDescription: String
    var researchHeading: String
    var researchIntro: String
    var researchItems: String
    var educationHeading: String
    var educationItems: String
    var publicationsHeading: String
    var publicationItems: String
    var notesHeading: String
    var notesIntro: String
    var serviceHeading: String
    var serviceAcademic: String
    var serviceAwards: String
    var contactHeading: String
    var contactIntro: String
    var footerCopyright: String
    var footerLocation: String
    var footerTimezone: String
    var footerLastUpdate: String

    init(
        name: String,
        eyebrow: String,
        lead: String,
        currentFocus: String,
        previousWork: String,
        email: String,
        github: String,
        scholar: String,
        zhihu: String,
        photoPath: String = "images/mingxiao-li.png",
        photoAlt: String = "Portrait of Mingxiao Li",
        photoCaption: String = "Shanghai, China",
        pageTitle: String = "Mingxiao Li — AI for Science & Multimodal Generation",
        metaDescription: String = "Mingxiao Li is a Young Researcher at Shanghai AI Laboratory working on AI for Science discovery, scientific reasoning models, molecular generation, and visual generation models.",
        researchHeading: String = "Research",
        researchIntro: String = "I study how generative models can discover, represent, and reason about complex scientific and visual worlds.",
        researchItems: String = SiteProfile.defaultResearchItems,
        educationHeading: String = "Education",
        educationItems: String = SiteProfile.defaultEducationItems,
        publicationsHeading: String = "Selected publications",
        publicationItems: String = SiteProfile.defaultPublicationItems,
        notesHeading: String = "Technical notes",
        notesIntro: String = "I write about the techniques behind my work: diffusion, sampling, molecular representations, multimodal reasoning, and the practical craft of research engineering.",
        serviceHeading: String = "Service & awards",
        serviceAcademic: String = "Area Chair · ACL Rolling Review (2025.02)\nWorkshop organizer · AAAI 2024 AIBED\n\nReviewer for ICML, CVPR, ICLR, NeurIPS, AAAI, EMNLP, ACL, ECAI, ECML, and EACL.",
        serviceAwards: String = "Summa cum laude PhD\nErasmus Mundus Full Scholarship\nChinese Government Scholarship",
        contactHeading: String = "Contact",
        contactIntro: String = "I am always happy to hear about thoughtful questions, unusual ideas, and potential collaborations.",
        footerCopyright: String = "© 2026 Mingxiao Li",
        footerLocation: String = "Shanghai, China",
        footerTimezone: String = "Shanghai time",
        footerLastUpdate: String = "Aug 2026"
    ) {
        self.name = name
        self.eyebrow = eyebrow
        self.lead = lead
        self.currentFocus = currentFocus
        self.previousWork = previousWork
        self.email = email
        self.github = github
        self.scholar = scholar
        self.zhihu = zhihu
        self.photoPath = photoPath
        self.photoAlt = photoAlt
        self.photoCaption = photoCaption
        self.pageTitle = pageTitle
        self.metaDescription = metaDescription
        self.researchHeading = researchHeading
        self.researchIntro = researchIntro
        self.researchItems = researchItems
        self.educationHeading = educationHeading
        self.educationItems = educationItems
        self.publicationsHeading = publicationsHeading
        self.publicationItems = publicationItems
        self.notesHeading = notesHeading
        self.notesIntro = notesIntro
        self.serviceHeading = serviceHeading
        self.serviceAcademic = serviceAcademic
        self.serviceAwards = serviceAwards
        self.contactHeading = contactHeading
        self.contactIntro = contactIntro
        self.footerCopyright = footerCopyright
        self.footerLocation = footerLocation
        self.footerTimezone = footerTimezone
        self.footerLastUpdate = footerLastUpdate
    }

    private enum CodingKeys: String, CodingKey {
        case name, eyebrow, lead, currentFocus, previousWork, email, github, scholar, zhihu
        case photoPath, photoAlt, photoCaption, pageTitle, metaDescription
        case researchHeading, researchIntro, researchItems, educationHeading, educationItems
        case publicationsHeading, publicationItems, notesHeading, notesIntro
        case serviceHeading, serviceAcademic, serviceAwards, contactHeading, contactIntro
        case footerCopyright, footerLocation, footerTimezone, footerLastUpdate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = SiteProfile.defaults
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? fallback.name
        eyebrow = try values.decodeIfPresent(String.self, forKey: .eyebrow) ?? fallback.eyebrow
        lead = try values.decodeIfPresent(String.self, forKey: .lead) ?? fallback.lead
        currentFocus = try values.decodeIfPresent(String.self, forKey: .currentFocus) ?? fallback.currentFocus
        previousWork = try values.decodeIfPresent(String.self, forKey: .previousWork) ?? fallback.previousWork
        email = try values.decodeIfPresent(String.self, forKey: .email) ?? fallback.email
        github = try values.decodeIfPresent(String.self, forKey: .github) ?? fallback.github
        scholar = try values.decodeIfPresent(String.self, forKey: .scholar) ?? fallback.scholar
        zhihu = try values.decodeIfPresent(String.self, forKey: .zhihu) ?? fallback.zhihu
        photoPath = try values.decodeIfPresent(String.self, forKey: .photoPath) ?? fallback.photoPath
        photoAlt = try values.decodeIfPresent(String.self, forKey: .photoAlt) ?? fallback.photoAlt
        photoCaption = try values.decodeIfPresent(String.self, forKey: .photoCaption) ?? fallback.photoCaption
        pageTitle = try values.decodeIfPresent(String.self, forKey: .pageTitle) ?? fallback.pageTitle
        metaDescription = try values.decodeIfPresent(String.self, forKey: .metaDescription) ?? fallback.metaDescription
        researchHeading = try values.decodeIfPresent(String.self, forKey: .researchHeading) ?? fallback.researchHeading
        researchIntro = try values.decodeIfPresent(String.self, forKey: .researchIntro) ?? fallback.researchIntro
        researchItems = try values.decodeIfPresent(String.self, forKey: .researchItems) ?? fallback.researchItems
        educationHeading = try values.decodeIfPresent(String.self, forKey: .educationHeading) ?? fallback.educationHeading
        educationItems = try values.decodeIfPresent(String.self, forKey: .educationItems) ?? fallback.educationItems
        publicationsHeading = try values.decodeIfPresent(String.self, forKey: .publicationsHeading) ?? fallback.publicationsHeading
        publicationItems = try values.decodeIfPresent(String.self, forKey: .publicationItems) ?? fallback.publicationItems
        notesHeading = try values.decodeIfPresent(String.self, forKey: .notesHeading) ?? fallback.notesHeading
        notesIntro = try values.decodeIfPresent(String.self, forKey: .notesIntro) ?? fallback.notesIntro
        serviceHeading = try values.decodeIfPresent(String.self, forKey: .serviceHeading) ?? fallback.serviceHeading
        serviceAcademic = try values.decodeIfPresent(String.self, forKey: .serviceAcademic) ?? fallback.serviceAcademic
        serviceAwards = try values.decodeIfPresent(String.self, forKey: .serviceAwards) ?? fallback.serviceAwards
        contactHeading = try values.decodeIfPresent(String.self, forKey: .contactHeading) ?? fallback.contactHeading
        contactIntro = try values.decodeIfPresent(String.self, forKey: .contactIntro) ?? fallback.contactIntro
        footerCopyright = try values.decodeIfPresent(String.self, forKey: .footerCopyright) ?? fallback.footerCopyright
        footerLocation = try values.decodeIfPresent(String.self, forKey: .footerLocation) ?? fallback.footerLocation
        footerTimezone = try values.decodeIfPresent(String.self, forKey: .footerTimezone) ?? fallback.footerTimezone
        footerLastUpdate = try values.decodeIfPresent(String.self, forKey: .footerLastUpdate) ?? fallback.footerLastUpdate
    }

    private static let defaultResearchItems = """
    AI for Science discovery | Molecular generation, unified molecular tokenization, and foundation models for scientific exploration.
    Scientific reasoning models | Models that connect evidence, language, and structured representations to support reliable scientific reasoning.
    Visual generation | Diffusion and multimodal models for controllable images, video, motion, and dynamic visual experiences.
    """

    private static let defaultEducationItems = """
    2025— | Young Researcher | Shanghai AI Laboratory · AI for Science Center
    2024—25 | Postdoctoral Researcher | Computer Science · KU Leuven
    2019—24 | PhD in Computer Science | KU Leuven · summa cum laude
    2018—19 | Master of Artificial Intelligence | KU Leuven
    2016—18 | Master of Theoretical Chemistry & Computational Modeling | KU Leuven
    2011—15 | Bachelor of Material Physics | East China University of Science and Technology
    """

    private static let defaultPublicationItems = """
    NeurIPS 2025 | Consistent Story Generation: Unlocking the Potential of Zigzag Sampling. | https://arxiv.org/abs/2506.09612
    ICML 2025 | DCTdiff: Intriguing Properties of Image Generative Modeling in the DCT Space. | https://arxiv.org/abs/2412.15032
    AAAI 2025 · Oral | NeuroCine: Decoding Vivid Video Sequences from Human Brain Activities. | https://arxiv.org/abs/2402.01590
    ECCV 2024 | Animate Your Motion: Turning Still Images into Dynamic Videos. | https://arxiv.org/abs/2403.10179
    ICLR 2024 | Alleviating Exposure Bias in Diffusion Models through Shifted Time Steps. | https://arxiv.org/abs/2305.15583
    NeurIPS 2023 | Contrast, Attend and Diffuse to Decode High-Resolution Images from Brain Activities. | https://arxiv.org/abs/2305.17214
    ICLR 2024 | Elucidating the Exposure Bias in Diffusion Models. | https://arxiv.org/abs/2308.15321
    AAAI 2023 · Oral | Layout-Aware Dreamer for Embodied Visual Grounding. | https://arxiv.org/abs/2212.00171
    """

    static let defaults = SiteProfile(
        name: "Mingxiao Li",
        eyebrow: "Young Researcher · Shanghai AI Laboratory",
        lead: "I work on generative and understanding models for AI for Science, with a continuing interest in visual generation and multimodal intelligence.",
        currentFocus: "My current work at Shanghai AI Laboratory focuses on AI for Science discovery, with an emphasis on molecular generation, unified molecular tokenization, and reasoning models for scientific problems. In parallel, I continue to develop visual generation models for controllable video synthesis and multimodal understanding.",
        previousWork: "Before joining Shanghai AI Laboratory, I was a postdoctoral researcher at KU Leuven, where my research was guided by Prof. Marie-Francine Moens.",
        email: "eric.lee.xiao@gmail.com",
        github: "https://github.com/Mingxiao-Li",
        scholar: "https://scholar.google.com/citations?user=0t2f7joAAAAJ&hl=en",
        zhihu: "https://www.zhihu.com/people/relax-88"
    )
}

struct NoteDocument: Identifiable, Hashable {
    let id: UUID
    var title: String
    var tags: [String]
    var body: String
    var date: String
    var published: Bool
    var fileURL: URL?

    init(
        id: UUID = UUID(),
        title: String,
        tags: [String] = [],
        body: String,
        date: String,
        published: Bool,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.tags = tags
        self.body = body
        self.date = date
        self.published = published
        self.fileURL = fileURL
    }
}

enum StudioSection: String, CaseIterable, Identifiable {
    case dashboard
    case profile
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .profile: return "Profile"
        case .notes: return "Notes"
        }
    }
}

struct EditorInsertion: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let selectionOffset: Int
    let selectionLength: Int
}

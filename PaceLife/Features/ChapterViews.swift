import SwiftUI
import PhotosUI
import PaceLifeCore

struct ChaptersView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    @State private var archived = false
    var body: some View {
        PaceSubpage(title: "Life Chapters", subtitle: model.text(.chaptersDetail)) {
            Button { creating = true } label: { PaceSquareIcon(systemImage: "plus") }
                .buttonStyle(.plain)
                .accessibilityLabel(model.chapterText(.newChapter)).accessibilityIdentifier("addChapter")
        } content: {
            Label(model.chapterText(.privateNote), systemImage: "lock.shield").font(.footnote).foregroundStyle(PaceColor.textSecondary)
            PaceToggleRow(title: model.chapterText(.archive), isOn: $archived).accessibilityIdentifier("chapterArchive")
            let timeline = model.state.chapterTimeline(archived: archived)
            if timeline.isEmpty {
                PaceCard {
                    PaceEmptyState(systemImage: "book.closed", title: "Life Chapters", message: model.chapterText(.noChapters)) {
                        if !archived { Button(model.chapterText(.newChapter)) { creating = true }.buttonStyle(PaceButtonStyle(kind: .secondary)) }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(timeline.enumerated()), id: \.element.id) { index, chapter in
                    HStack(alignment: .top, spacing: PaceSpacing.s) {
                        VStack(spacing: 0) {
                            Circle().fill(PaceColor.accentStrong).frame(width: 12, height: 12).padding(.top, 22)
                            if index < timeline.count - 1 { Rectangle().fill(PaceColor.border).frame(width: 2).frame(maxHeight: .infinity) }
                        }
                        .frame(width: 14)
                        .accessibilityHidden(true)
                        NavigationLink(value: AppRoute.chapter(chapter.id)) { ChapterRowCard(chapter: chapter) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("chapter.open." + chapter.title)
                            .padding(.bottom, PaceSpacing.s)
                    }
                }
            }
        }
        .sheet(isPresented: $creating) { ChapterEditor() }
    }
}

struct ChapterRowCard: View {
    @Environment(AppModel.self) private var model
    let chapter: LifeChapter
    var body: some View {
        PaceCard {
            HStack(alignment: .top, spacing: PaceSpacing.s) {
                VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                    Text(model.dayLabel(chapter.startDay) + " – " + (chapter.endDay.map(model.dayLabel) ?? model.chapterText(.ongoing)))
                        .font(.caption.weight(.semibold)).foregroundStyle(PaceColor.accent)
                    Text(chapter.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                    Text(model.categoryName(chapter.category)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    if !chapter.notes.isEmpty { Text(chapter.notes).font(.subheadline).lineLimit(2).foregroundStyle(PaceColor.textPrimary) }
                    HStack(spacing: PaceSpacing.xs) {
                        if !chapter.photoIDs.isEmpty { PaceBadge(text: model.number(Double(chapter.photoIDs.count)), systemImage: "photo") }
                        if !chapter.memories.isEmpty { PaceBadge(text: model.number(Double(chapter.memories.count)), systemImage: "text.book.closed") }
                    }
                }
                Spacer(minLength: 0)
                if let id = chapter.photoIDs.first, let image = model.chapterPhoto(id) {
                    Image(uiImage: image).resizable().scaledToFill().frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

struct ChapterDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let chapterID: UUID
    @State private var editing = false
    @State private var memory: ChapterMemory?
    @State private var deleting = false
    @State private var selections: [PhotosPickerItem] = []
    @State private var importing = false
    private var chapter: LifeChapter? { model.state.chapters.first { $0.id == chapterID } }
    var body: some View {
        PaceSubpage(title: chapter?.title ?? "Life Chapters", subtitle: chapter.map { model.dayLabel($0.startDay) + " – " + ($0.endDay.map(model.dayLabel) ?? model.chapterText(.ongoing)) }) {
            if chapter != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editChapter")
            }
        } content: {
            if let chapter {
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack {
                            PaceBadge(text: model.categoryName(chapter.category))
                            if chapter.isArchived { PaceBadge(text: model.pathText(.archived), systemImage: "archivebox") }
                            Spacer()
                        }
                        if !chapter.notes.isEmpty { Text(chapter.notes).font(.body) }
                        Label(model.chapterText(.privateNote), systemImage: "lock.shield").font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        ForEach(model.state.paths.filter { chapter.pathIDs.contains($0.id) }) { path in
                            NavigationLink(value: AppRoute.path(path.id)) { Label(path.title, systemImage: "link") }
                                .buttonStyle(PaceLinkButtonStyle())
                        }
                    }
                }
                photos(chapter)
                PaceSectionTitle(title: model.chapterText(.memories)) {
                    Button { memory = ChapterMemory(title: "") } label: { Label(model.text(.add), systemImage: "plus") }
                        .buttonStyle(PaceLinkButtonStyle()).accessibilityIdentifier("addMemory")
                }
                if chapter.memories.isEmpty {
                    PaceCard { Text(model.text(.noHistory)).foregroundStyle(PaceColor.textSecondary) }
                }
                ForEach(chapter.memories.sorted { $0.day > $1.day }) { entry in
                    Button { memory = entry } label: {
                        PaceCard {
                            VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                                HStack {
                                    Label(entry.title, systemImage: entry.isMilestone ? "flag.checkered" : "text.book.closed")
                                        .font(.headline).foregroundStyle(PaceColor.textPrimary)
                                    Spacer()
                                    Text(model.dayLabel(entry.day)).font(.caption).foregroundStyle(PaceColor.textSecondary)
                                }
                                if !entry.notes.isEmpty { Text(entry.notes).font(.subheadline).foregroundStyle(PaceColor.textPrimary) }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(model.text(.edit))
                }
                VStack(spacing: PaceSpacing.xs) {
                    Button(model.chapterText(chapter.isArchived ? .restore : .archive)) {
                        var updated = chapter; updated.isArchived.toggle(); _ = model.saveChapter(updated)
                    }
                    .buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("archiveChapter")
                    Button(model.chapterText(.deleteChapter), role: .destructive) { deleting = true }
                        .buttonStyle(PaceButtonStyle(kind: .destructive)).accessibilityIdentifier("deleteChapter")
                }
            }
        }
        .disabled(importing)
        .sheet(isPresented: $editing) { if let chapter { ChapterEditor(existing: chapter) } }
        .sheet(item: $memory) { MemoryEditor(chapterID: chapterID, memory: $0) }
        .confirmationDialog(model.chapterText(.deleteChapter), isPresented: $deleting, titleVisibility: .visible) {
            Button(model.chapterText(.deleteChapter), role: .destructive) { if model.deleteChapter(chapterID) { dismiss() } }
        } message: { Text(model.chapterText(.deleteWarning)) }
        .onChange(of: selections) { _, items in
            guard !items.isEmpty else { return }
            importing = true
            Task { @MainActor in
                for item in items {
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) { model.importChapterPhoto(data, chapterID: chapterID) }
                        else { model.photoFailed = true }
                    } catch { model.photoFailed = true }
                    if model.photoFailed { break }
                }
                selections = []; importing = false
            }
        }
    }
    private func photos(_ chapter: LifeChapter) -> some View {
        let pickerTitle = model.chapterText(.addPhotos)
        return VStack(alignment: .leading, spacing: PaceSpacing.s) {
            PaceSectionTitle(title: model.chapterText(.photos)) {
                PhotosPicker(selection: $selections, maxSelectionCount: 10, matching: .images) {
                    Label(pickerTitle, systemImage: "photo.badge.plus").font(.body).foregroundStyle(PaceColor.accent).frame(minHeight: 44)
                }.disabled(importing).accessibilityIdentifier("addChapterPhotos")
            }
            ForEach(chapter.photoIDs, id: \.self) { id in
                PaceCard(padding: PaceSpacing.xs) {
                    VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                        if let image = model.chapterPhoto(id) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .accessibilityLabel(model.chapterText(.photos))
                                .accessibilityIdentifier("chapter.photo." + id.uuidString)
                        } else {
                            Label(model.chapterText(.missingPhoto), systemImage: "photo.badge.exclamationmark").padding(PaceSpacing.s)
                        }
                        Button(model.chapterText(.removePhoto), role: .destructive) {
                            var updated = chapter; updated.photoIDs.removeAll { $0 == id }; _ = model.saveChapter(updated)
                        }
                        .font(.subheadline).foregroundStyle(PaceColor.danger).frame(minHeight: 44).padding(.horizontal, PaceSpacing.xs)
                        .accessibilityIdentifier("chapter.removePhoto." + id.uuidString)
                    }
                }
            }
            if importing { ProgressView().tint(PaceColor.accentStrong) }
            if model.photoFailed {
                Text(model.chapterText(.photoError)).foregroundStyle(PaceColor.danger)
                Button(model.chapterText(.retryCleanup)) { model.cleanChapterPhotos() }.buttonStyle(PaceLinkButtonStyle())
            }
        }
    }
}

struct ChapterEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var chapter: LifeChapter
    @State private var start = Date()
    @State private var end = Date()
    @State private var ongoing = true
    @State private var initialized = false
    init(existing: LifeChapter? = nil) { _chapter = State(initialValue: existing ?? LifeChapter(title: "")) }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                TextField(model.text(.name), text: $chapter.title).accessibilityIdentifier("chapterTitle")
                TextField(model.routineText(.notes), text: $chapter.notes, axis: .vertical).accessibilityIdentifier("chapterNotes")
                Picker(model.pathText(.category), selection: $chapter.category) {
                    ForEach(ChapterCategory.allCases, id: \.self) { Text(model.categoryName($0)).tag($0) }
                }
                DatePicker(model.chapterText(.start), selection: $start, displayedComponents: .date)
                Toggle(model.chapterText(.ongoing), isOn: $ongoing)
                if !ongoing { DatePicker(model.chapterText(.end), selection: $end, in: start..., displayedComponents: .date) }
                Section("Life Paths") {
                    ForEach(model.state.paths) { path in
                        Toggle(path.title, isOn: Binding(get: { chapter.pathIDs.contains(path.id) }, set: {
                            if $0 { chapter.pathIDs.insert(path.id) } else { chapter.pathIDs.remove(path.id) }
                        }))
                    }
                }
                Text(model.chapterText(.privateNote)).font(.footnote)
            }
            .paceFormStyle()
            .navigationTitle("Life Chapters").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !initialized { start = model.date(for: chapter.startDay); end = chapter.endDay.map(model.date) ?? start; ongoing = chapter.endDay == nil; initialized = true }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        chapter.startDay = DayKey(date: start); chapter.endDay = ongoing ? nil : DayKey(date: end)
                        if model.saveChapter(chapter) { dismiss() }
                    }.disabled(chapter.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!ongoing && DayKey(date: end) < DayKey(date: start)))
                        .accessibilityIdentifier("saveChapter")
                }
            }
        }
    }
}

struct MemoryEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let chapterID: UUID
    @State var memory: ChapterMemory
    @State private var date = Date()
    @State private var initialized = false
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                TextField(model.text(.name), text: $memory.title).accessibilityIdentifier("memoryTitle")
                TextField(model.routineText(.notes), text: $memory.notes, axis: .vertical)
                DatePicker(model.chapterText(.start), selection: $date, displayedComponents: .date)
                Toggle(model.chapterText(.milestone), isOn: $memory.isMilestone)
                if model.state.chapters.first(where: { $0.id == chapterID })?.memories.contains(where: { $0.id == memory.id }) == true {
                    Button(model.chapterText(.deleteMemory), role: .destructive) { save(removing: true) }
                }
            }
            .onAppear { if !initialized { date = model.date(for: memory.day); initialized = true } }
            .navigationTitle(model.chapterText(.memories)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { save() }.disabled(memory.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveMemory")
                }
            }
        }
    }
    private func save(removing: Bool = false) {
        guard var chapter = model.state.chapters.first(where: { $0.id == chapterID }) else { return }
        memory.day = DayKey(date: date)
        chapter.memories.removeAll { $0.id == memory.id }
        if !removing { chapter.memories.append(memory) }
        if model.saveChapter(chapter) { dismiss() }
    }
}

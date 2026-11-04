import SwiftUI
import PhotosUI
import PaceLifeCore

struct ChaptersView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var creating = false
    @State private var archived = false
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    SaveErrorBanner()
                    Label(model.chapterText(.privateNote), systemImage: "lock.shield").font(.footnote)
                    Toggle(model.chapterText(.archive), isOn: $archived).accessibilityIdentifier("chapterArchive")
                    if model.state.chapterTimeline(archived: archived).isEmpty {
                        PaceCard { PaceStatus(title: "Life Chapters", message: model.chapterText(.noChapters), systemImage: "book.closed") }
                    }
                    ForEach(model.state.chapterTimeline(archived: archived)) { chapter in
                        NavigationLink { ChapterDetail(chapterID: chapter.id) } label: {
                            PaceCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(model.dayLabel(chapter.startDay)).font(.caption).foregroundStyle(PaceColor.accent)
                                    Text(chapter.title).font(.title3.bold())
                                    Text(model.categoryName(chapter.category)).font(.footnote)
                                    if !chapter.notes.isEmpty { Text(chapter.notes).lineLimit(3) }
                                }
                            }
                        }.buttonStyle(.plain).accessibilityIdentifier("chapter.open." + chapter.title)
                    }
                }.padding(16)
            }
            .background(PaceColor.background).navigationTitle("Life Chapters").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() }.accessibilityIdentifier("closeChapters") }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(model.chapterText(.newChapter)).accessibilityIdentifier("addChapter")
                }
            }
            .sheet(isPresented: $creating) { ChapterEditor() }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SaveErrorBanner()
                if let chapter {
                    PaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(model.chapterText(.privateNote), systemImage: "lock.shield").font(.footnote)
                            Text(chapter.notes)
                            LabeledContent(model.pathText(.category), value: model.categoryName(chapter.category))
                            LabeledContent(model.chapterText(.start), value: model.dayLabel(chapter.startDay))
                            LabeledContent(model.chapterText(.end), value: chapter.endDay.map(model.dayLabel) ?? model.chapterText(.ongoing))
                            ForEach(model.state.paths.filter { chapter.pathIDs.contains($0.id) }) { path in
                                NavigationLink { PathDetail(pathID: path.id) } label: { Label(path.title, systemImage: "link") }
                            }
                        }
                    }
                    photos(chapter)
                    Text(model.chapterText(.memories)).font(.title3.bold())
                    ForEach(chapter.memories.sorted { $0.day > $1.day }) { entry in
                        PaceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(entry.title, systemImage: entry.isMilestone ? "flag.checkered" : "text.book.closed")
                                Text(model.dayLabel(entry.day)).font(.caption)
                                Text(entry.notes)
                                Button(model.text(.edit)) { memory = entry }
                            }
                        }
                    }
                    Button(model.chapterText(.addMemory)) { memory = ChapterMemory(title: "") }
                        .buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("addMemory")
                    Button(model.text(.edit)) { editing = true }.buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("editChapter")
                    Button(model.chapterText(chapter.isArchived ? .restore : .archive)) {
                        var updated = chapter; updated.isArchived.toggle(); _ = model.saveChapter(updated)
                    }.accessibilityIdentifier("archiveChapter")
                    Button(model.chapterText(.deleteChapter), role: .destructive) { deleting = true }.accessibilityIdentifier("deleteChapter")
                }
            }.padding(16).disabled(importing)
        }
        .background(PaceColor.background).navigationTitle(chapter?.title ?? "Life Chapters").navigationBarTitleDisplayMode(.inline)
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
        return VStack(alignment: .leading, spacing: 12) {
            Text(model.chapterText(.photos)).font(.title3.bold())
            ForEach(chapter.photoIDs, id: \.self) { id in
                PaceCard {
                    VStack(alignment: .leading, spacing: 8) {
                        if let image = model.chapterPhoto(id) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 280)
                                .accessibilityLabel(model.chapterText(.photos))
                                .accessibilityIdentifier("chapter.photo." + id.uuidString)
                        } else { Label(model.chapterText(.missingPhoto), systemImage: "photo.badge.exclamationmark") }
                        Button(model.chapterText(.removePhoto), role: .destructive) {
                            var updated = chapter; updated.photoIDs.removeAll { $0 == id }; _ = model.saveChapter(updated)
                        }.accessibilityIdentifier("chapter.removePhoto." + id.uuidString)
                    }
                }
            }
            PhotosPicker(selection: $selections, maxSelectionCount: 10, matching: .images) {
                Label(pickerTitle, systemImage: "photo.badge.plus")
            }.disabled(importing).accessibilityIdentifier("addChapterPhotos")
            if importing { ProgressView() }
            if model.photoFailed {
                Text(model.chapterText(.photoError)).foregroundStyle(PaceColor.danger)
                Button(model.chapterText(.retryCleanup)) { model.cleanChapterPhotos() }
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
            .scrollContentBackground(.hidden).background(PaceColor.background)
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

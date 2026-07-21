import SwiftUI
import ProRoundsDataConfig
import ProRoundsDesignSystem

/// Identifies the editor sheet presentation (`nil` configuration = create).
private struct EditorPresentation: Identifiable {
    let id: UUID
    let configuration: Configuration?
}

/// The Configurations list — the Timer tab root. Dumb: it renders the view model's rows with the
/// design-system `ConfigCard` and forwards intents; the editor view model is built by an injected
/// factory (composition root), so this view constructs no collaborators.
public struct ConfigListView: View {
    @State private var model: ConfigListViewModel
    @State private var presentation: EditorPresentation?
    private let makeEditor: (Configuration?) -> ConfigEditorViewModel
    private let onStartWorkout: (Configuration) -> Void

    public init(
        model: ConfigListViewModel,
        makeEditor: @escaping (Configuration?) -> ConfigEditorViewModel,
        onStartWorkout: @escaping (Configuration) -> Void
    ) {
        _model = State(initialValue: model)
        self.makeEditor = makeEditor
        self.onStartWorkout = onStartWorkout
    }

    public var body: some View {
        content
            .navigationTitle("ProRounds")
            .background(ProRoundsColor.canvas)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentation = EditorPresentation(id: UUID(), configuration: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New workout")
                }
            }
            .task { await model.load() }
            .sheet(item: $presentation) { item in
                ConfigEditorView(model: makeEditor(item.configuration)) {
                    await model.load()
                }
            }
    }

    @ViewBuilder private var content: some View {
        if model.isEmpty {
            emptyState
        } else {
            List {
                ForEach(model.rows) { row in
                    ConfigCard(iconSystemName: row.iconSystemName, name: row.name,
                               metadata: row.metadata, totalText: row.totalText)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md,
                                                  bottom: Spacing.xs, trailing: Spacing.md))
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("configCard")
                        .onTapGesture {
                            if let config = model.configuration(id: row.id) { onStartWorkout(config) }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                if let config = model.configuration(id: row.id) {
                                    presentation = EditorPresentation(id: config.id, configuration: config)
                                }
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(ProRoundsColor.accent.color(for: .dark))
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await model.delete(id: row.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                if let config = model.configuration(id: row.id) {
                                    presentation = EditorPresentation(id: config.id, configuration: config)
                                }
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task { await model.delete(id: row.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(ProRoundsColor.textSecondary)
            Text("No rounds yet")
                .fontToken(.title)
                .foregroundStyle(ProRoundsColor.textPrimary)
            Text("Create your first workout to get started.")
                .fontToken(.body)
                .foregroundStyle(ProRoundsColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("Create your first workout") {
                presentation = EditorPresentation(id: UUID(), configuration: nil)
            }
            .buttonStyle(.proPrimary)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

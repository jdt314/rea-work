import SwiftUI

struct WordEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String
    @State var meaning: String
    @State var pronunciation: String
    var onSave: (String, String, String) -> Void
    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("单词") {
                    TextField("学习语言中的单词", text: $name).accessibilityIdentifier("wordNameField")
                        .textInputAutocapitalization(.never)
                    TextField("中文释义", text: $meaning).accessibilityIdentifier("wordMeaningField")
                    TextField("音标或读音（选填）", text: $pronunciation).textInputAutocapitalization(.never)
                }
            }
            .scrollContentBackground(.hidden).background(Palette.paper)
            .navigationTitle("调整单词").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines),
                               meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                               pronunciation.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }.disabled(!valid).accessibilityIdentifier("confirmEditButton")
                }
            }
        }.presentationDetents([.medium, .large])
    }
}

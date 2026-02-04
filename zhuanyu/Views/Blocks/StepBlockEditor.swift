import SwiftUI

struct StepBlockEditor: View {
    @Binding var block: RecipeBlock

    private var durationBinding: Binding<Int> {
        Binding(
            get: { block.durationMinutes ?? 0 },
            set: { block.durationMinutes = $0 == 0 ? nil : $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Step title", text: $block.title)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $block.text)
                .frame(minHeight: 90)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))

            HStack(spacing: 12) {
                Stepper(value: durationBinding, in: 0...240, step: 1) {
                    Label("Time \(durationBinding.wrappedValue) min", systemImage: "timer")
                }

                IconPicker(icon: $block.icon)
            }

            Picker("Heat", selection: $block.heat) {
                Text("None").tag(nil as HeatLevel?)
                ForEach(HeatLevel.allCases, id: \.self) { heat in
                    Text(heat.label).tag(Optional(heat))
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

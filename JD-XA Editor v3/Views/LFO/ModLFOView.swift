import SwiftUI

struct ModLFOView: View {
    @ObservedObject var viewModel: ModLFOViewModel

    var body: some View {
        SectionCard("Mod LFO", systemImage: "wave.3.right.circle", tint: SectionTint.modLFO, accessory: {
            ChipToggle(title: "Sync", systemImage: "metronome", isOn: $viewModel.isTempoSync)
                .help("Sync the Mod LFO rate to the tempo")
        }) {
            VStack(alignment: .leading, spacing: 14) {
                ChipPicker(LFOShape.allCases, selection: $viewModel.selectedShape) { $0.name }

                HStack(alignment: .top, spacing: 14) {
                    LFORateKnob(
                        isTempoSync: viewModel.isTempoSync,
                        rate: $viewModel.rate,
                        syncedRate: $viewModel.lfoRate
                    )

                    VerticalSlider(title: "Rate Ctrl", value: $viewModel.rateControl, range: -63...63, height: 90, defaultValue: 0)
                        .help("How much the modulation wheel changes the Mod LFO rate")

                    ControlDivider()

                    ControlGroupBox("Depth") {
                        HStack(spacing: 4) {
                            VerticalSlider(title: "Pitch", value: $viewModel.pitchDepth, range: -63...63, height: 90, defaultValue: 0)
                            VerticalSlider(title: "Filter", value: $viewModel.filterDepth, range: -63...63, height: 90, defaultValue: 0)
                            VerticalSlider(title: "Amp", value: $viewModel.ampDepth, range: -63...63, height: 90, defaultValue: 0)
                            VerticalSlider(title: "Pan", value: $viewModel.panDepth, range: -63...63, height: 90, defaultValue: 0)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

class ModLFOViewModel: ObservableObject {
    @Published var selectedShape: LFOShape = .tri
    @Published var isTempoSync = false
    @Published var rate: Double = 64
    @Published var selectedTempoValue = TempoSyncValue.defaultValue
    @Published var lfoRate: Double = 0
    @Published var rateControl: Double = 0
    
    @Published var pitchDepth: Double = 0
    @Published var filterDepth: Double = 0
    @Published var ampDepth: Double = 0
    @Published var panDepth: Double = 0
}

struct ModLFOView_Previews: PreviewProvider {
    static var previews: some View {
        ModLFOView(viewModel: ModLFOViewModel())
            .padding()
            .background(ThemeColors.background)
    }
}

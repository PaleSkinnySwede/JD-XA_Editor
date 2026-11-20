import SwiftUI

struct LFOView: View {
    @ObservedObject var viewModel: LFOViewModel

    var body: some View {
        SectionCard("LFO", systemImage: "wave.3.right", tint: SectionTint.lfo, accessory: {
            HStack(spacing: 4) {
                ChipToggle(title: "Key Trig", isOn: $viewModel.keyTrigger)
                    .help("Restart the LFO cycle on every note")
                ChipToggle(title: "Sync", systemImage: "metronome", isOn: $viewModel.isTempoSync)
                    .help("Sync the LFO rate to the tempo")
            }
        }) {
            VStack(alignment: .leading, spacing: 14) {
                ChipPicker(LFOShape.allCases, selection: $viewModel.selectedShape) { $0.name }

                HStack(alignment: .top, spacing: 14) {
                    LFORateKnob(
                        isTempoSync: viewModel.isTempoSync,
                        rate: $viewModel.rate,
                        syncedRate: $viewModel.lfoRate
                    )

                    VerticalSlider(title: "Fade", value: $viewModel.fadeTime, range: 0...127, height: 90, defaultValue: 0)

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

/// Rate knob that shows note values when the LFO is tempo-synced.
struct LFORateKnob: View {
    let isTempoSync: Bool
    @Binding var rate: Double
    @Binding var syncedRate: Double

    var body: some View {
        if isTempoSync {
            DialKnob(
                title: "Rate",
                value: $syncedRate,
                range: 0...19,
                defaultValue: 11,
                isBidirectional: false,
                displayValues: MIDIConstants.lfoRates
            )
        } else {
            DialKnob(
                title: "Rate",
                value: $rate,
                range: 0...127,
                defaultValue: 64,
                isBidirectional: false
            )
        }
    }
}

class LFOViewModel: ObservableObject {
    @Published var selectedShape: LFOShape = .tri
    @Published var isTempoSync = false
    @Published var rate: Double = 64
    @Published var selectedTempoValue = TempoSyncValue.defaultValue
    @Published var lfoRate: Double = 0
    @Published var keyTrigger = false
    
    @Published var fadeTime: Double = 0
    @Published var pitchDepth: Double = 0
    @Published var filterDepth: Double = 0
    @Published var ampDepth: Double = 0
    @Published var panDepth: Double = 0
}

struct LFOView_Previews: PreviewProvider {
    static var previews: some View {
        LFOView(viewModel: LFOViewModel())
            .padding()
            .background(ThemeColors.background)
    }
}

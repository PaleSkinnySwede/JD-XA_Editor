import SwiftUI

struct LFOView: View {
    @StateObject private var viewModel: LFOViewModel

    let lfoRates = [
        "16", "12", "8", "4", "2", "1",
        "3/4", "2/3", "1/2", "3/8", "1/3",
        "1/4", "3/16", "1/6", "1/8", "3/32",
        "1/12", "1/16", "1/24", "1/32"
    ]
    
    init() {
        _viewModel = StateObject(wrappedValue: LFOViewModel())
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Title
            Text("LFO Controls")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            // Main content
            VStack(spacing: ThemeMetrics.spacing * 2) {
                // Top row: Shape buttons and Tempo Sync
                HStack(spacing: ThemeMetrics.spacing) {
                    // Shape buttons
                    ForEach(LFOShape.allCases, id: \.self) { shape in
                        Button(action: { viewModel.selectedShape = shape }) {
                            Text(shape.name)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.selectedShape == shape ? ThemeColors.accent : ThemeColors.secondaryBackground)
                    }
                    
                    // Tempo Sync button
                    Toggle("Sync", isOn: $viewModel.isTempoSync)
                        .toggleStyle(.button)
                        .tint(ThemeColors.accent)
                        .frame(maxWidth: .infinity)
                }
                
                // Middle section: Rate knob and Key Trigger
                HStack(alignment: .top, spacing: ThemeMetrics.spacing * 3) {
                    // Rate knob
                    if viewModel.isTempoSync {
                        // Tempo sync version
                        DialKnob(
                            title: "Rate",
                            value: $viewModel.lfoRate,
                            range: 0...19,
                            defaultValue: 11,
                            isBidirectional: false,
                            displayValues: MIDIConstants.lfoRates
                        )
                    } else {
                        // Normal rate knob
                        DialKnob(
                            title: "Rate",
                            value: $viewModel.rate,
                            range: 0...127,
                            defaultValue: 64,
                            isBidirectional: false
                        )
                    }
                    
                    // Key Trigger button
                    Toggle("Key Trigger", isOn: $viewModel.keyTrigger)
                        .toggleStyle(.button)
                        .tint(ThemeColors.accent)
                }
                
                // Bottom section: Sliders
                HStack(spacing: ThemeMetrics.spacing) {
                    VerticalSlider(
                        title: "Fade",
                        value: $viewModel.fadeTime,
                        range: 0...127,
                        defaultValue: 0
                    )
                    
                    VerticalSlider(
                        title: "Pitch",
                        value: $viewModel.pitchDepth,
                        range: -63...63,
                        defaultValue: 0
                    )
                    
                    VerticalSlider(
                        title: "Filter",
                        value: $viewModel.filterDepth,
                        range: -63...63,
                        defaultValue: 0
                    )
                    
                    VerticalSlider(
                        title: "Amp",
                        value: $viewModel.ampDepth,
                        range: -63...63,
                        defaultValue: 0
                    )
                    
                    VerticalSlider(
                        title: "Pan",
                        value: $viewModel.panDepth,
                        range: -63...63,
                        defaultValue: 0
                    )
                }
            }
            .padding()
            .background(ThemeColors.secondaryBackground)
            .cornerRadius(ThemeMetrics.cornerRadius)
        }
        .padding()
        .background(ThemeColors.background)
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
        LFOView()
            .background(ThemeColors.background)
    }
}

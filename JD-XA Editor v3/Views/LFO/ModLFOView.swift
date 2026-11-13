import SwiftUI

struct ModLFOView: View {
    @StateObject private var viewModel: ModLFOViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ModLFOViewModel())
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Title
            Text("MOD-LFO Controls")
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
                
                // Middle section: Rate knob and Rate Control slider
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
                            defaultValue: 64
                        )
                    }
                    
                }
                
                // Bottom section: Depth Sliders
                HStack(spacing: ThemeMetrics.spacing) {
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

                    VerticalSlider(
                        title: "Rate Ctrl",
                        value: $viewModel.rateControl,
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
        ModLFOView()
            .background(ThemeColors.background)
    }
}

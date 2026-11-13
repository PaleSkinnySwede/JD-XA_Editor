import SwiftUI

struct DigitalPartialView: View {
    let partNumber: Int
    let partialNumber: Int
    @StateObject private var viewModel: DigitalPartialViewModel
    @Environment(\.midiManager) private var midiManager
    
    init(partNumber: Int, partialNumber: Int) {
        self.partNumber = partNumber
        self.partialNumber = partialNumber
        _viewModel = StateObject(wrappedValue: DigitalPartialViewModel())
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Partial On/Off Switch
            HStack {
                Spacer()
                Toggle("Partial \(partialNumber) On/Off", isOn: $viewModel.isPartialEnabled)
                    .toggleStyle(.switch)
                    .tint(ThemeColors.accent)
            }
            .padding(.horizontal)
            
            // Parameter Sections Tab View
            TabView(selection: $viewModel.selectedSection) {
                LFOContainerView()
                    .tabItem {
                        Text("LFO")
                    }
                    .tag(ParameterSection.lfo)
                
                // Pass the midiService to OscillatorView
                if let midiManager = midiManager {
                    OscillatorView(
                        partNumber: partNumber,
                        partialNumber: partialNumber,
                        midiService: MIDIService(midiManager: midiManager)
                    )
                    .tabItem {
                        Text("OSC")
                    }
                    .tag(ParameterSection.osc)
                }
                
                Text("Filter Coming Soon...")
                    .tabItem {
                        Text("FILTER")
                    }
                    .tag(ParameterSection.filter)
                
                Text("Amp Coming Soon...")
                    .tabItem {
                        Text("AMP")
                    }
                    .tag(ParameterSection.amp)
                
            }
        }
        .background(ThemeColors.background)
        .foregroundColor(ThemeColors.text)
    }
}

enum ParameterSection: String {
    case osc, filter, amp, lfo, modlfo
}

class DigitalPartialViewModel: ObservableObject {
    @Published var isPartialEnabled = true
    @Published var selectedSection: ParameterSection = .osc
}

struct DigitalPartialView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPartialView(partNumber: 1, partialNumber: 1)
            .background(ThemeColors.background)
    }
}

import SwiftUI

// MARK: - Values

/// Digital partial filter type (Filter Mode, 0–7).
/// Cases are declared in display order (allCases drives the buttons);
/// the raw values are the synth's parameter values.
enum FilterMode: UInt8, CaseIterable {
    case bypass = 0
    case lpf = 1
    case lpf2 = 5
    case lpf3 = 6
    case hpf = 2
    case bpf = 3
    case lpf4 = 7
    case pkg = 4

    var name: String {
        switch self {
        case .bypass: return "BYPASS"
        case .lpf: return "LPF1"
        case .hpf: return "HPF"
        case .bpf: return "BPF"
        case .pkg: return "PKG"
        case .lpf2: return "LPF2"
        case .lpf3: return "LPF3"
        case .lpf4: return "LPF4"
        }
    }

    var help: String {
        switch self {
        case .bypass: return "No filtering"
        case .lpf: return "Low-pass: cuts the highs"
        case .hpf: return "High-pass: cuts the lows"
        case .bpf: return "Band-pass: keeps a band around the cutoff"
        case .pkg: return "Peaking: boosts a band around the cutoff"
        case .lpf2: return "Low-pass, gentle resonance"
        case .lpf3: return "Low-pass, softer resonance"
        case .lpf4: return "Low-pass, smooth character"
        }
    }
}

/// Filter Slope (0–1)
enum FilterSlope: UInt8, CaseIterable {
    case minus12 = 0
    case minus24 = 1

    var name: String {
        switch self {
        case .minus12: return "-12 dB"
        case .minus24: return "-24 dB"
        }
    }
}

// MARK: - View model

/// Filter state for one partial. Every change is sent to the synth.
final class FilterViewModel: ObservableObject {
    typealias Address = DigitalPartParameter.ParameterAddress

    static let keyFollowRange: ClosedRange<Double> = -100...100
    static let bipolarRange: ClosedRange<Double> = -63...63

    private let midiService: MIDIService
    private let partNumber: Int
    private let partialNumber: Int

    @Published var mode: FilterMode = .lpf {
        didSet { send(Address.fltMode, Int(mode.rawValue)) }
    }
    @Published var slope: FilterSlope = .minus12 {
        didSet { send(Address.fltSlope, Int(slope.rawValue)) }
    }

    /// 0...127
    @Published var cutoff: Double = 127 {
        didSet { send(Address.fltCutoff, Int(cutoff)) }
    }
    /// 0...127
    @Published var resonance: Double = 0 {
        didSet { send(Address.fltResonance, Int(resonance)) }
    }
    /// Separate high-pass filter before the main filter, 0...127
    @Published var hpfCutoff: Double = 0 {
        didSet { send(Address.fltHPCutoff, Int(hpfCutoff)) }
    }

    /// -63...+63
    @Published var envDepth: Double = 0 {
        didSet { sendBipolar(Address.fltEnvDepth, envDepth) }
    }
    /// Envelope times and level, 0...127
    @Published var attack: Double = 0 {
        didSet { send(Address.fltEnvAttackTime, Int(attack)) }
    }
    @Published var decay: Double = 64 {
        didSet { send(Address.fltEnvDecayTIme, Int(decay)) }
    }
    @Published var sustain: Double = 64 {
        didSet { send(Address.fltEnvSustainLevel, Int(sustain)) }
    }
    @Published var release: Double = 0 {
        didSet { send(Address.fltEnvReleaseTime, Int(release)) }
    }

    /// -100...+100 in steps of 10 (sent as 54...74)
    @Published var keyFollow: Double = 0 {
        didSet { send(Address.fltCutoffKeyFollow, 64 + Int((keyFollow / 10).rounded())) }
    }
    /// -63...+63
    @Published var envVelocitySens: Double = 0 {
        didSet { sendBipolar(Address.fltEnvVelSens, envVelocitySens) }
    }
    /// -63...+63
    @Published var cutoffAftertouchSens: Double = 0 {
        didSet { sendBipolar(Address.fltCutoffATSens, cutoffAftertouchSens) }
    }

    init(partNumber: Int, partialNumber: Int, midiService: MIDIService) {
        self.partNumber = partNumber
        self.partialNumber = partialNumber
        self.midiService = midiService
    }

    /// -63...+63 is sent as 1...127
    private func sendBipolar(_ offset: [UInt8], _ value: Double) {
        send(offset, 64 + Int(value.rounded()))
    }

    private func send(_ offset: [UInt8], _ value: Int) {
        midiService.sendParameterChange(DigitalPartParameter(
            partNumber: partNumber,
            partialNumber: partialNumber,
            parameterOffset: offset,
            value: UInt8(min(max(value, 0), 127))
        ))
    }
}

// MARK: - View

struct FilterView: View {
    @ObservedObject var viewModel: FilterViewModel

    @Environment(\.isCompactLayout) private var isCompact

    private var isBypassed: Bool { viewModel.mode == .bypass }

    var body: some View {
        SectionCard("Filter", systemImage: "camera.filters", tint: SectionTint.filter, accessory: {
            HStack(spacing: 4) {
                Text("SLOPE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(ThemeColors.tertiaryText)
                    .padding(.trailing, 4)
                ForEach(FilterSlope.allCases, id: \.self) { slope in
                    Button(slope.name) { viewModel.slope = slope }
                        .buttonStyle(ChipButtonStyle(isSelected: viewModel.slope == slope && !isBypassed, expands: false))
                }
            }
            .disabled(isBypassed)
            .help(isBypassed ? "The slope has no effect when the filter is bypassed" : "How steeply the filter cuts")
        }) {
            VStack(alignment: .leading, spacing: isCompact ? 12 : 18) {
                ControlGroupBox("Type") {
                    ChipRow(compactMinCellWidth: 60) {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            Button(mode.name) { viewModel.mode = mode }
                                .buttonStyle(ChipButtonStyle(isSelected: viewModel.mode == mode))
                                .help(mode.help)
                        }
                    }
                }

                ControlGroupRow {
                    ControlGroupBox("Filter") {
                        HStack(alignment: .top, spacing: 4) {
                            DialKnob(title: "Cutoff", value: $viewModel.cutoff, range: 0...127,
                                     defaultValue: 127, isBidirectional: false)
                            DialKnob(title: "Resonance", value: $viewModel.resonance, range: 0...127,
                                     defaultValue: 0, isBidirectional: false)
                            DialKnob(title: "HPF", value: $viewModel.hpfCutoff, range: 0...127,
                                     defaultValue: 0, isBidirectional: false)
                                .help("Cutoff of the separate high-pass filter. It works even when the filter is bypassed.")
                        }
                    }

                    ControlDivider()

                    ControlGroupBox("Envelope") {
                        // Depth goes above the ADSR sliders when there's no room beside them
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 4) { envelopeControls }
                            VStack(alignment: .leading, spacing: 8) { envelopeControls }
                        }
                    }

                    ControlDivider()

                    ControlGroupBox("Sensitivity") {
                        HStack(alignment: .top, spacing: 4) {
                            VerticalSlider(title: "Key Flw", value: $viewModel.keyFollow,
                                           range: FilterViewModel.keyFollowRange, step: 10, height: 118, defaultValue: 0)
                                .help("Opens the cutoff for higher notes (+) or lower notes (−)")
                            VerticalSlider(title: "Velocity", value: $viewModel.envVelocitySens,
                                           range: FilterViewModel.bipolarRange, height: 118, defaultValue: 0)
                                .help("How much playing harder deepens the filter envelope")
                            VerticalSlider(title: "AT", value: $viewModel.cutoffAftertouchSens,
                                           range: FilterViewModel.bipolarRange, height: 118, defaultValue: 0)
                                .help("How much aftertouch moves the cutoff")
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder private var envelopeControls: some View {
        DialKnob(title: "Depth", value: $viewModel.envDepth,
                 range: FilterViewModel.bipolarRange, defaultValue: 0)
            .help("How far the envelope moves the cutoff")

        ADSRControls(
            attack: $viewModel.attack,
            decay: $viewModel.decay,
            sustain: $viewModel.sustain,
            release: $viewModel.release
        )
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(viewModel: FilterViewModel(
            partNumber: 1, partialNumber: 1,
            midiService: MIDIService(midiManager: MIDIManager())
        ))
        .padding()
        .frame(width: 800)
        .background(ThemeColors.background)
    }
}

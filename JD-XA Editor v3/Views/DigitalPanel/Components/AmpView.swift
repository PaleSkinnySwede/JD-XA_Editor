import SwiftUI

// MARK: - View model

/// Amp state for one partial. Every change is sent to the synth.
final class AmpViewModel: ObservableObject {
    typealias Address = DigitalPartParameter.ParameterAddress

    static let panRange: ClosedRange<Double> = -64...63
    static let keyFollowRange: ClosedRange<Double> = -100...100
    static let bipolarRange: ClosedRange<Double> = -63...63

    /// Pan knob labels for -64...63: L64 … C … R63
    static let panLabels: [String] = (-64...63).map { value in
        value < 0 ? "L\(-value)" : value == 0 ? "C" : "R\(value)"
    }

    private let midiService: MIDIService
    private let partNumber: Int
    private let partialNumber: Int

    /// 0...127
    @Published var level: Double = 100 {
        didSet { send(Address.ampLevel, Int(level)) }
    }
    /// L64...R63, sent as 0...127 with center 64
    @Published var pan: Double = 0 {
        didSet { send(Address.ampPan, 64 + Int(pan.rounded())) }
    }

    /// Envelope times and level, 0...127
    @Published var attack: Double = 0 {
        didSet { send(Address.ampAttackTime, Int(attack)) }
    }
    @Published var decay: Double = 64 {
        didSet { send(Address.ampDecayTime, Int(decay)) }
    }
    @Published var sustain: Double = 127 {
        didSet { send(Address.ampSustainLevel, Int(sustain)) }
    }
    @Published var release: Double = 0 {
        didSet { send(Address.ampReleaseTime, Int(release)) }
    }

    /// -100...+100 in steps of 10 (sent as 54...74)
    @Published var keyFollow: Double = 0 {
        didSet { send(Address.ampKeyFollow, 64 + Int((keyFollow / 10).rounded())) }
    }
    /// -63...+63
    @Published var velocitySens: Double = 0 {
        didSet { sendBipolar(Address.ampVelSens, velocitySens) }
    }
    /// -63...+63
    @Published var aftertouchSens: Double = 0 {
        didSet { sendBipolar(Address.ampLevelATSens, aftertouchSens) }
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

struct AmpView: View {
    @ObservedObject var viewModel: AmpViewModel

    var body: some View {
        SectionCard("Amp", systemImage: "speaker.wave.2", tint: SectionTint.amp) {
            ControlGroupRow {
                ControlGroupBox("Output") {
                    HStack(alignment: .top, spacing: 4) {
                        DialKnob(title: "Level", value: $viewModel.level, range: 0...127,
                                 defaultValue: 100, isBidirectional: false)
                        DialKnob(title: "Pan", value: $viewModel.pan, range: AmpViewModel.panRange,
                                 defaultValue: 0, displayValues: AmpViewModel.panLabels)
                            .help("Stereo position. Double-click to center.")
                    }
                }

                ControlDivider()

                ControlGroupBox("Envelope") {
                    ADSRControls(
                        attack: $viewModel.attack,
                        decay: $viewModel.decay,
                        sustain: $viewModel.sustain,
                        release: $viewModel.release,
                        defaults: (attack: 0, decay: 64, sustain: 127, release: 0)
                    )
                }

                ControlDivider()

                ControlGroupBox("Sensitivity") {
                    HStack(alignment: .top, spacing: 4) {
                        VerticalSlider(title: "Key Flw", value: $viewModel.keyFollow,
                                       range: AmpViewModel.keyFollowRange, step: 10, height: 118, defaultValue: 0)
                            .help("Makes higher notes louder (+) or quieter (−)")
                        VerticalSlider(title: "Velocity", value: $viewModel.velocitySens,
                                       range: AmpViewModel.bipolarRange, height: 118, defaultValue: 0)
                            .help("How much playing harder makes notes louder")
                        VerticalSlider(title: "AT", value: $viewModel.aftertouchSens,
                                       range: AmpViewModel.bipolarRange, height: 118, defaultValue: 0)
                            .help("How much aftertouch changes the level")
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct AmpView_Previews: PreviewProvider {
    static var previews: some View {
        AmpView(viewModel: AmpViewModel(
            partNumber: 1, partialNumber: 1,
            midiService: MIDIService(midiManager: MIDIManager())
        ))
        .padding()
        .frame(width: 800)
        .background(ThemeColors.background)
    }
}

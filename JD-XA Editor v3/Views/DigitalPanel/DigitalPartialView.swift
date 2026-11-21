import SwiftUI

/// Every section of one partial on a single page, laid out like the
/// synth's panel and its signal flow: OSC, FILTER, AMP, then the two LFOs.
struct DigitalPartialView: View {
    @ObservedObject var state: DigitalPartialState

    var body: some View {
        VStack(spacing: 12) {
            if !state.isEnabled {
                PartialOffBanner(partialNumber: state.partialNumber) {
                    state.isEnabled = true
                }
            }

            OscillatorView(viewModel: state.oscillator)

            FilterView(viewModel: state.filter)

            SectionCard("Amp", systemImage: "speaker.wave.2", tint: SectionTint.amp) {
                ComingSoonView(message: "Amp controls are coming soon")
            }

            LFOContainerView(lfo: state.lfo, modLFO: state.modLFO)
        }
        .foregroundColor(ThemeColors.text)
    }
}

private struct PartialOffBanner: View {
    let partialNumber: Int
    let turnOn: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.slash.fill")
                .foregroundColor(ThemeColors.disconnected)
            Text("Partial \(partialNumber) is off. You can still edit it, but you won't hear it.")
                .font(.callout)
                .foregroundColor(ThemeColors.secondaryText)
            Spacer()
            Button("Turn On", action: turnOn)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ThemeColors.disconnected.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ThemeColors.disconnected.opacity(0.3))
        )
    }
}

struct DigitalPartialView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPartialView(state: DigitalPartialState(
            partNumber: 1, partialNumber: 1,
            midiService: MIDIService(midiManager: MIDIManager())
        ))
        .padding()
        .frame(width: 900)
        .background(ThemeColors.background)
    }
}

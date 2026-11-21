import SwiftUI

/// Every section of one partial on a single page. Each partial has its own
/// OSC, LFO, Mod LFO, FILTER and AMP, so every card is tagged with the
/// partial it belongs to.
struct DigitalPartialView: View {
    @ObservedObject var state: DigitalPartialState

    private var scope: String { "Partial \(state.partialNumber)" }

    var body: some View {
        VStack(spacing: 12) {
            PartialScopeHeader(partialNumber: state.partialNumber)

            if !state.isEnabled {
                PartialOffBanner(partialNumber: state.partialNumber) {
                    state.isEnabled = true
                }
            }

            OscillatorView(viewModel: state.oscillator)

            LFOContainerView(lfo: state.lfo, modLFO: state.modLFO)

            FilterView(viewModel: state.filter)

            AmpView(viewModel: state.amp)
        }
        .environment(\.sectionScope, scope)
        .foregroundColor(ThemeColors.text)
    }
}

/// Says which partial the cards below edit.
private struct PartialScopeHeader: View {
    let partialNumber: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("\(partialNumber)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(ThemeColors.accent, in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                Text("Editing Partial \(partialNumber)")
                    .font(.system(size: 13, weight: .semibold))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
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

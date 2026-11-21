import SwiftUI

/// The header above a partial's column: its number, the wave it's playing
/// and its on/off switch.
struct PartialHeader: View {
    @ObservedObject var state: DigitalPartialState
    @ObservedObject var oscillator: OscillatorViewModel

    private var waveName: String {
        if let number = oscillator.pcmWaveNumber {
            return PCMWaveDatabase.findWave(id: number)?.name ?? "PCM \(number)"
        }
        if oscillator.selectedWaveform == .superSaw { return oscillator.selectedWaveform.name }
        return "\(oscillator.selectedWaveform.name) · \(oscillator.selectedVariation.name)"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(state.partialNumber)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(ThemeColors.text)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7).fill(ThemeColors.raised))

            VStack(alignment: .leading, spacing: 1) {
                Text("Partial \(state.partialNumber)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ThemeColors.text)
                Text(state.isEnabled ? waveName : "Off")
                    .font(.system(size: 11))
                    .foregroundColor(ThemeColors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)

            Toggle("Partial \(state.partialNumber) on", isOn: $state.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(ThemeColors.accent)
                .accessibilityIdentifier("partial-\(state.partialNumber)-switch")
                .help(state.isEnabled ? "Turn Partial \(state.partialNumber) off" : "Turn Partial \(state.partialNumber) on")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(ThemeColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ThemeColors.stroke)
        )
        .opacity(state.isEnabled ? 1 : 0.6)
    }
}

struct PartialHeader_Previews: PreviewProvider {
    static var previews: some View {
        let store = DigitalEditorStore(midiManager: MIDIManager())
        PartialHeader(state: store.state(part: 1, partial: 1), oscillator: store.state(part: 1, partial: 1).oscillator)
            .padding()
            .frame(width: 400)
            .background(ThemeColors.background)
    }
}

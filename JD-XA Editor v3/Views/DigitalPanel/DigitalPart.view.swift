import SwiftUI

/// The three partials of a part as selectable tiles, each with its own
/// on/off switch and the waveform it's playing.
struct PartialStrip: View {
    let partNumber: Int
    @ObservedObject var store: DigitalEditorStore

    var body: some View {
        let selection = store.selectedPartialBinding(for: partNumber)
        HStack(spacing: 10) {
            ForEach(DigitalEditorStore.partials, id: \.self) { partial in
                PartialTile(
                    state: store.state(part: partNumber, partial: partial),
                    oscillator: store.state(part: partNumber, partial: partial).oscillator,
                    isSelected: selection.wrappedValue == partial,
                    onSelect: { selection.wrappedValue = partial }
                )
            }
        }
    }
}

private struct PartialTile: View {
    @ObservedObject var state: DigitalPartialState
    @ObservedObject var oscillator: OscillatorViewModel
    let isSelected: Bool
    let onSelect: () -> Void

    private var waveName: String {
        if let number = oscillator.pcmWaveNumber {
            return PCMWaveDatabase.findWave(id: number)?.name ?? "PCM \(number)"
        }
        if oscillator.selectedWaveform == .superSaw { return oscillator.selectedWaveform.name }
        return "\(oscillator.selectedWaveform.name) · \(oscillator.selectedVariation.name)"
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Text("\(state.partialNumber)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .black.opacity(0.85) : ThemeColors.text)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(isSelected ? ThemeColors.accent : ThemeColors.raised)
                        )

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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // On the select button only: on the whole tile, the shortcut
            // went to the on/off switch instead
            .keyboardShortcut(KeyEquivalent(Character("\(state.partialNumber)")), modifiers: .command)
            .help("Edit Partial \(state.partialNumber) (⌘\(state.partialNumber))")

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
                .fill(isSelected ? ThemeColors.raised : ThemeColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? ThemeColors.accent.opacity(0.7) : ThemeColors.stroke, lineWidth: isSelected ? 1.5 : 1)
        )
        .opacity(state.isEnabled ? 1 : 0.6)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

struct PartialStrip_Previews: PreviewProvider {
    static var previews: some View {
        PartialStrip(partNumber: 1, store: DigitalEditorStore(midiManager: MIDIManager()))
            .padding()
            .frame(width: 800)
            .background(ThemeColors.background)
    }
}

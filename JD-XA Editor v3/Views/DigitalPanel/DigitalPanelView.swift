import SwiftUI

// MARK: - Store

/// Editor state for one Digital partial. Kept in `DigitalEditorStore` so it
/// survives switching between parts and partials.
final class DigitalPartialState: ObservableObject {
    let partNumber: Int
    let partialNumber: Int
    let oscillator: OscillatorViewModel
    let lfo = LFOViewModel()
    let modLFO = ModLFOViewModel()

    /// UI only for now; not sent to the synth yet.
    @Published var isEnabled = true

    init(partNumber: Int, partialNumber: Int, midiService: MIDIService) {
        self.partNumber = partNumber
        self.partialNumber = partialNumber
        self.oscillator = OscillatorViewModel(
            partNumber: partNumber,
            partialNumber: partialNumber,
            midiService: midiService
        )
    }
}

/// Holds the state of all four Digital parts (three partials each) and the
/// one `MIDIService` they send through.
final class DigitalEditorStore: ObservableObject {
    static let parts = 1...4
    static let partials = 1...3

    let midiService: MIDIService
    private let states: [Int: [Int: DigitalPartialState]]

    /// The partial being edited, per part
    @Published var selectedPartial: [Int: Int] = [:]

    init(midiManager: MIDISending) {
        let service = MIDIService(midiManager: midiManager)
        midiService = service
        var states: [Int: [Int: DigitalPartialState]] = [:]
        for part in Self.parts {
            for partial in Self.partials {
                states[part, default: [:]][partial] = DigitalPartialState(
                    partNumber: part, partialNumber: partial, midiService: service
                )
            }
        }
        self.states = states
    }

    func state(part: Int, partial: Int) -> DigitalPartialState {
        states[part]![partial]!
    }

    func selectedPartialBinding(for part: Int) -> Binding<Int> {
        Binding(
            get: { self.selectedPartial[part] ?? 1 },
            set: { self.selectedPartial[part] = $0 }
        )
    }
}

// MARK: - Part editor

/// Editor for one Digital part: a strip to pick the partial, then every
/// section of that partial on one scrolling page.
struct DigitalPanelView: View {
    let partNumber: Int
    @ObservedObject var store: DigitalEditorStore

    private var selectedPartial: Int { store.selectedPartial[partNumber] ?? 1 }

    var body: some View {
        VStack(spacing: 0) {
            PartialStrip(partNumber: partNumber, store: store)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            Divider().overlay(ThemeColors.stroke)

            ScrollView {
                DigitalPartialView(state: store.state(part: partNumber, partial: selectedPartial))
                    .padding(20)
                    // New identity per partial so the PCM sheet and drag
                    // states don't carry over
                    .id("\(partNumber)-\(selectedPartial)")
            }
        }
        .background(ThemeColors.background)
        .navigationTitle("Digital Part \(partNumber)")
        .navigationSubtitle("Partial \(selectedPartial)")
    }
}

struct DigitalPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPanelView(partNumber: 1, store: DigitalEditorStore(midiManager: MIDIManager()))
            .frame(width: 900, height: 800)
            .preferredColorScheme(.dark)
    }
}

import SwiftUI

// MARK: - Store

/// Editor state for one Digital partial. Kept in `DigitalEditorStore` so it
/// survives switching between parts.
final class DigitalPartialState: ObservableObject {
    let partNumber: Int
    let partialNumber: Int
    let oscillator: OscillatorViewModel
    let filter: FilterViewModel
    let amp: AmpViewModel
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
        self.filter = FilterViewModel(
            partNumber: partNumber,
            partialNumber: partialNumber,
            midiService: midiService
        )
        self.amp = AmpViewModel(
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
}

// MARK: - Part editor

/// Editor for one Digital part: its three partials side by side, every
/// section on one page. Each section is one row, so the same card of every
/// partial lines up (all three filters next to each other, and so on). It
/// scrolls down when the window is too short, and sideways when it's
/// narrower than three minimum columns.
struct DigitalPanelView: View {
    let partNumber: Int
    @ObservedObject var store: DigitalEditorStore

    private static let minColumnWidth: CGFloat = 270
    private static let spacing: CGFloat = 12
    private static let padding: CGFloat = 12
    private static var minWidth: CGFloat {
        let columns = CGFloat(DigitalEditorStore.partials.count)
        return columns * minColumnWidth + (columns - 1) * spacing + 2 * padding
    }

    private var partials: [DigitalPartialState] {
        DigitalEditorStore.partials.map { store.state(part: partNumber, partial: $0) }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    header
                    Divider().overlay(ThemeColors.stroke)
                    ScrollView(.vertical) {
                        VStack(spacing: Self.spacing) {
                            row { OscillatorView(viewModel: $0.oscillator) }
                            row { LFOContainerView(lfo: $0.lfo, modLFO: $0.modLFO) }
                            row { FilterView(viewModel: $0.filter) }
                            row { AmpView(viewModel: $0.amp) }
                        }
                        .padding(Self.padding)
                    }
                }
                .frame(width: max(proxy.size.width, Self.minWidth), height: proxy.size.height)
            }
        }
        // The cards sit in narrow columns
        .environment(\.isCompactLayout, true)
        .foregroundColor(ThemeColors.text)
        .background(ThemeColors.background)
        .navigationTitle("Digital Part \(partNumber)")
    }

    /// One header per partial above its column: its number, the wave it
    /// plays and its on/off switch.
    private var header: some View {
        HStack(spacing: Self.spacing) {
            ForEach(partials, id: \.partialNumber) { state in
                PartialHeader(state: state, oscillator: state.oscillator)
            }
        }
        .padding(.horizontal, Self.padding)
        .padding(.vertical, 14)
    }

    /// The same section for every partial, with equal widths and heights
    private func row<Card: View>(@ViewBuilder _ card: @escaping (DigitalPartialState) -> Card) -> some View {
        HStack(alignment: .top, spacing: Self.spacing) {
            ForEach(partials, id: \.partialNumber) { state in
                PartialColumnCell(state: state) { card(state) }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// One card in a partial's column, dimmed while the partial is off.
private struct PartialColumnCell<Content: View>: View {
    @ObservedObject var state: DigitalPartialState
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .top)
            .opacity(state.isEnabled ? 1 : 0.5)
    }
}

struct DigitalPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPanelView(partNumber: 1, store: DigitalEditorStore(midiManager: MIDIManager()))
            .frame(width: 1690, height: 1400)
            .preferredColorScheme(.dark)
    }
}

import SwiftUI

//MARK: - BasicWaveformPicker
public struct WaveformPicker: View {
    @Binding var selectedWaveform: DOscWaveform
    @Binding var selectedVariation: WaveformVariation
    @Binding var pcmWaveNumber: Int?
    var onWaveformUpdate: ((DOscWaveform, WaveformVariation) -> Void)?
    var onPCMUpdate: ((Int?) -> Void)?
    
    @State private var showingPCMPicker = false
    @State private var searchText = ""
    
    private var isPCM: Bool { pcmWaveNumber != nil }

    private var pcmWaveName: String? {
        guard let number = pcmWaveNumber else { return nil }
        return PCMWaveDatabase.findWave(id: number)?.name ?? "Wave \(number)"
    }

    public var body: some View {
        waveformGroup
            .sheet(isPresented: $showingPCMPicker) {
                // Route the picker's choice through onPCMUpdate so it gets sent
                PCMWaveformPicker(
                    pcmWaveNumber: Binding(
                        get: { pcmWaveNumber },
                        set: { onPCMUpdate?($0) }
                    ),
                    searchText: $searchText
                )
            }
    }

    private var waveformGroup: some View {
        ControlGroupBox("Waveform") {
            HStack(spacing: 4) {
                ForEach(DOscWaveform.allCases, id: \.self) { waveform in
                    Button(waveform.name) {
                        onWaveformUpdate?(waveform, selectedVariation)
                    }
                    .buttonStyle(ChipButtonStyle(isSelected: selectedWaveform == waveform && !isPCM))
                }

                Button {
                    showingPCMPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up")
                        Text(pcmWaveName ?? "PCM…")
                            .truncationMode(.middle)
                    }
                }
                .buttonStyle(ChipButtonStyle(isSelected: isPCM))
                .frame(minWidth: 96)
                .help(pcmWaveName.map { "PCM wave: \($0). Click to choose another." } ?? "Choose a SuperNATURAL PCM wave")
            }
        }
    }
}

// MARK: - VariationPicker

/// A / B / C variation of the basic waveform. Not available for SUPER-SAW or PCM.
struct VariationPicker: View {
    let selectedWaveform: DOscWaveform
    let selectedVariation: WaveformVariation
    let isPCM: Bool
    let onSelect: (WaveformVariation) -> Void

    private var isDisabled: Bool { selectedWaveform == .superSaw || isPCM }

    var body: some View {
        HStack(spacing: 4) {
            Text("VARIATION")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(ThemeColors.tertiaryText)
                .padding(.trailing, 4)
            ForEach(WaveformVariation.allCases, id: \.self) { variation in
                Button(variation.name) { onSelect(variation) }
                    .buttonStyle(ChipButtonStyle(isSelected: selectedVariation == variation && !isDisabled))
                    .frame(width: 28)
            }
        }
        .disabled(isDisabled)
        .help(isDisabled ? "Variations are only available for the basic waveforms" : "Waveform variation")
    }
}

// MARK: - PCMWaveformPicker
public struct PCMWaveformPicker: View {
    @Binding var pcmWaveNumber: Int?
    @Binding var searchText: String
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: PCMCategory?
    
    public init(pcmWaveNumber: Binding<Int?>, searchText: Binding<String>) {
        self._pcmWaveNumber = pcmWaveNumber
        self._searchText = searchText
    }
    
    private var filteredWaves: [PCMWave] {
        if searchText.isEmpty {
            return selectedCategory?.waves ?? []
        }
        // If searching, search across all categories
        return PCMWaveDatabase.categories
            .flatMap { $0.waves }
            .filter { wave in
                wave.displayName.lowercased().contains(searchText.lowercased())
            }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search all waveforms", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(ThemeMetrics.spacing)

            HSplitView {
                // Category List
                List(PCMWaveDatabase.categories, selection: $selectedCategory) { category in
                    Text(category.name)
                        .tag(category)
                }
                .frame(minWidth: 150, maxWidth: 200)
                .listStyle(.sidebar)
                
                // Waveform List
                List {
                    if searchText.isEmpty && selectedCategory == nil {
                        Text("Select a category or search for waveforms")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(filteredWaves) { wave in
                            Button {
                                pcmWaveNumber = wave.id
                                dismiss()
                            } label: {
                                HStack {
                                    Text(wave.displayName)
                                        .foregroundColor(ThemeColors.text)
                                    Spacer()
                                    if pcmWaveNumber == wave.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(ThemeColors.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

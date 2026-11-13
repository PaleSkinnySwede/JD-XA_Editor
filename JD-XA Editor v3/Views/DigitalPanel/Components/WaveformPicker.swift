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
    
    private var variationsDisabled: Bool {
        selectedWaveform == .superSaw || pcmWaveNumber != nil
    }
    
    public var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Basic Waveform Selection
            HStack(spacing: ThemeMetrics.spacing) {
                ForEach(DOscWaveform.allCases, id: \.self) { waveform in
                    Button(action: {
                        selectedWaveform = waveform
                        onWaveformUpdate?(waveform, selectedVariation)
                    }) {
                        Text(waveform.name)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedWaveform == waveform && pcmWaveNumber == nil ? ThemeColors.accent : ThemeColors.secondaryBackground)
                }
                
                // PCM Button
                Button(action: {
                    showingPCMPicker = true
                }) {
                    if let number = pcmWaveNumber,
                       let wave = PCMWaveDatabase.findWave(id: number) {
                        Text(wave.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("PCM")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .buttonStyle(.bordered)
                .tint(pcmWaveNumber != nil ? ThemeColors.accent : ThemeColors.secondaryBackground)
            }
            
            // Variation Selection
            HStack(spacing: ThemeMetrics.spacing) {
                ForEach(WaveformVariation.allCases, id: \.self) { variation in
                    Button(action: {
                        selectedVariation = variation
                        onWaveformUpdate?(selectedWaveform, variation)
                    }) {
                        Text(variation.name)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedVariation == variation ? ThemeColors.accent : ThemeColors.secondaryBackground)
                    .disabled(variationsDisabled)
                    .opacity(variationsDisabled ? 0.5 : 1)
                }
            }
        }
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
        .searchable(text: $searchText, prompt: "Search all waveforms")
        .frame(minWidth: 500, minHeight: 400)
    }
}

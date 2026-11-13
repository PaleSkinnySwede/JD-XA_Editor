import SwiftUI

struct DigitalPanelView: View {
    @StateObject private var viewModel = DigitalPanelViewModel()
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Parts Tab View
            TabView(selection: $viewModel.selectedPart) {
                ForEach(1...4, id: \.self) { partNumber in
                    DigitalPartView(partNumber: partNumber)
                        .tabItem {
                            Text("Part \(partNumber)")
                        }
                        .tag(partNumber)
                }
            }
            .background(ThemeColors.background)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColors.background)
    }
}

class DigitalPanelViewModel: ObservableObject {
    @Published var selectedPart: Int = 1
}

struct DigitalPanelView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPanelView()
    }
}

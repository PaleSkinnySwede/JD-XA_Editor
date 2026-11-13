import SwiftUI

struct DigitalPartView: View {
    let partNumber: Int
    @StateObject private var viewModel: DigitalPartViewModel
    
    init(partNumber: Int) {
        self.partNumber = partNumber
        _viewModel = StateObject(wrappedValue: DigitalPartViewModel())
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.spacing) {
            // Partials Tab View
            TabView(selection: $viewModel.selectedPartial) {
                ForEach(1...3, id: \.self) { partialNumber in
                    DigitalPartialView(
                        partNumber: partNumber,
                        partialNumber: partialNumber
                    )
                    .tabItem {
                        Text("Partial \(partialNumber)")
                    }
                    .tag(partialNumber)
                }
            }
        }
        .background(ThemeColors.background)
    }
}

class DigitalPartViewModel: ObservableObject {
    @Published var selectedPartial: Int = 1
}

struct DigitalPartView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalPartView(partNumber: 1)
            .background(ThemeColors.background)
    }
}

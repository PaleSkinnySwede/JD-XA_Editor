import SwiftUI

/// LFO and Mod LFO side by side, or stacked when the window is narrow.
struct LFOContainerView: View {
    @ObservedObject var lfo: LFOViewModel
    @ObservedObject var modLFO: ModLFOViewModel

    var body: some View {
        AdaptivePair {
            LFOView(viewModel: lfo)
        } trailing: {
            ModLFOView(viewModel: modLFO)
        }
    }
}

struct LFOContainerView_Previews: PreviewProvider {
    static var previews: some View {
        LFOContainerView(lfo: LFOViewModel(), modLFO: ModLFOViewModel())
            .padding()
            .background(ThemeColors.background)
    }
}

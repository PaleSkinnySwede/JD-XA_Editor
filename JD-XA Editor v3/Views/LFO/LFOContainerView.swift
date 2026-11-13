import SwiftUI

struct LFOContainerView: View {
    var body: some View {
        HStack(spacing: ThemeMetrics.spacing * 2) {
            // Left LFO
            LFOView()
                .frame(maxWidth: .infinity)
            
            // Right LFO (Mod LFO)
            ModLFOView()
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(ThemeColors.background)
    }
}

struct LFOContainerView_Previews: PreviewProvider {
    static var previews: some View {
        LFOContainerView()
            .background(ThemeColors.background)
    }
}

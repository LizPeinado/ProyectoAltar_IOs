import SwiftUI

struct PortadaCancion: View {
    let cancion: Cancion
    let radio: CGFloat

    var body: some View {
        Image(cancion.portada)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: radio))
            .accessibilityHidden(true)
    }
}

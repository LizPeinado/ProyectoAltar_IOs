import SwiftUI

struct TarjetaCancion: View {
    let cancion: Cancion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PortadaCancion(cancion: cancion, radio: 18)
            Text(cancion.titulo).font(.headline)
            Text("Oliver Tree").font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
    }
}

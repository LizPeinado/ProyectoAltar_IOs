import SwiftUI

struct ReproductorBarra: View {
    @Environment(MusicaControl.self) private var musica

    var body: some View {
        if let cancion = musica.cancion {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    PortadaCancion(cancion: cancion, radio: 8)
                        .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(cancion.titulo).font(.headline).lineLimit(2)
                        Text("Oliver Tree").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { musica.cambiar(-1) } label: { Image(systemName: "backward.end.fill") }
                        .accessibilityLabel("Canción anterior")
                    Button { musica.alternar() } label: {
                        Image(systemName: musica.sonando ? "pause.fill" : "play.fill")
                    }
                    .accessibilityLabel(musica.sonando ? "Pausar" : "Reproducir")
                    Button { musica.cambiar(1) } label: { Image(systemName: "forward.end.fill") }
                        .accessibilityLabel("Canción siguiente")
                }
                if let error = musica.error {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

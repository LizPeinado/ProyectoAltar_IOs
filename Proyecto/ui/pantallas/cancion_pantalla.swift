import SwiftUI

struct CancionPantalla: View {
    let cancion: Cancion
    @Environment(MusicaControl.self) private var musica
    @Environment(AppModel.self) private var appModel

    private var seleccionada: Bool { musica.cancion?.id == cancion.id }
    private var estaSonando: Bool { seleccionada && musica.sonando }
    private var altarAbierto: Bool { appModel.immersiveSpaceState != .closed }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PortadaCancion(cancion: cancion, radio: 20)
                    .frame(width: 190, height: 190)
                Text("Oliver Tree").foregroundStyle(.secondary)
                if altarAbierto {
                    Text("Cierra la experiencia desde Altar para escuchar la playlist.")
                        .font(.callout).foregroundStyle(.orange)
                }
                Button {
                    musica.seleccionar(cancion)
                } label: {
                    HStack(spacing: 16) {
                        Text(cancion.titulo).multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: estaSonando ? "pause.fill" : "play.fill")
                    }
                    .padding(16)
                    .background(seleccionada ? Color.orange.opacity(0.25) : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(altarAbierto)
                .accessibilityHint(estaSonando ? "Pausar" : "Reproducir")
            }
            .padding(28)
            .frame(maxWidth: 750)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(cancion.titulo)
    }
}

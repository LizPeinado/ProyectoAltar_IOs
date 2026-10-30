import RealityKit
import RealityKitContent
import SwiftUI
import Combine
import Foundation

struct VistaRealityKit: View {
    @Environment(AppModel.self) private var appModel
    @State private var escena: Entity?
    @State private var paso = 0 // Solo informa el progreso; las escenas controlan los pasos.
    @State private var cargando = true
    @State private var mensajeError: String?

    var body: some View {
        RealityView { content in
            appModel.errorEscena = nil
            do {
                let altar = try await Entity(named: "ExperienciaAltar", in: realityKitContentBundle)
                let oliver = altar.findEntity(named: "OliverMusica")?.findEntity(named: "oliver_idle")
                if oliver?.components[AnimationLibraryComponent.self]?.animations["oliver_baila"] == nil {
                    appModel.errorEscena = "La escena cargó, pero falta oliver_baila en la Animation Library de oliver_idle."
                }
                // La primera escena también queda visible si el Behavior inicial no arranca.
                altar.isEnabled = true
                altar.findEntity(named: "AltarSinElementos")?.isEnabled = true
                for nombre in ["AltarConFloreros", "AltarConPanYFloreros", "AltarCompleto"] {
                    altar.findEntity(named: nombre)?.isEnabled = false
                }
                content.add(altar)
                escena = altar
            } catch {
                let detalle = error as NSError
                let mensaje = "No se pudo cargar el altar (\(detalle.domain), \(detalle.code)): \(detalle.localizedDescription)"
                mensajeError = mensaje
                appModel.errorEscena = mensaje
                print("Error cargando ExperienciaAltar: \(String(reflecting: error))")
            }
            cargando = false
        }
        .gesture(
            SpatialTapGesture().targetedToAnyEntity().onEnded { toque in
                guard toque.entity.isActive else { return }
                var entidad: Entity? = toque.entity
                while let actual = entidad {
                    if actual.name == "mp3" {
                        // Un segundo toque reinicia la música, sin superponer audio o baile.
                        actual.stopAllAnimations(recursive: true)
                        actual.stopAllAudio()
                        escena?.findEntity(named: "OliverMusica")?.stopAllAnimations(recursive: true)
                        if let escena {
                            // Un aviso activa los Behaviors de música y baile
                            NotificationCenter.default.post(
                                name: Notification.Name("RealityKit.NotificationTrigger"),
                                object: nil,
                                userInfo: [
                                    "RealityKit.NotificationTrigger.Scene": escena,
                                    "RealityKit.NotificationTrigger.Identifier": "baila"
                                ]
                            )
                        }
                        return
                    }
                    entidad = actual.parent
                }
                _ = toque.entity.applyTapForBehaviors()
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RealityKit.NotificationTrigger"))) { aviso in
            guard let id = aviso.userInfo?["RealityKit.NotificationTrigger.Identifier"] as? String else { return }
            switch id {
            case "altar.paso1": paso = 1
            case "altar.paso2": paso = 2
            case "altar.paso3": paso = 3
            default: break
            }
        }
        .onDisappear {
            escena?.stopAllAnimations(recursive: true)
            escena?.findEntity(named: "mp3")?.stopAllAudio()
            escena = nil
        }
        .overlay {
            if cargando {
                ProgressView("Preparando el altar…")
                    .padding().glassBackgroundEffect()
            } else if let mensajeError {
                Text(mensajeError).padding().glassBackgroundEffect()
            } else {
                VStack(spacing: 8) {
                    Text("Día de Muertos").font(.headline)
                    Text(textoProgreso).font(.subheadline)
                }
                .padding().glassBackgroundEffect()
            }
        }
    }

    private var textoProgreso: String {
        switch paso {
        case 0: return "Toca el florero para colocarlo"
        case 1: return "Toca el pan de muerto para colocarlo"
        case 2: return "Toca el Skate para colocarlo"
        default: return "¡Altar completo! Toca el MP3 para escuchar la canción."
        }
    }
}

#Preview(immersionStyle: .mixed) {
    VistaRealityKit()
        .environment(AppModel())
}

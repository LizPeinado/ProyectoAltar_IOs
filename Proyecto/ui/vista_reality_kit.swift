import RealityKit
import RealityKitContent
import SwiftUI
import Combine
import Foundation

struct VistaRealityKit: View {
    @Environment(AppModel.self) private var appModel
    @State private var escena: Entity?
    @State private var paso = 0
    @State private var cargando = true
    @State private var mensajeError: String?

    // Estado de la música y el baile (se controla 100% desde Swift)
    private enum EstadoMusica { case detenida, sonando, pausada }
    @State private var estadoMusica: EstadoMusica = .detenida
    @State private var controladorAudio: AudioPlaybackController?
    @State private var controladorBaile: AnimationPlaybackController?

    var body: some View {
        RealityView { content in
            appModel.errorEscena = nil
            do {
                let altar = try await Entity(named: "ExperienciaAltar", in: realityKitContentBundle)
                altar.isEnabled = true
                altar.findEntity(named: "AltarSinElementos")?.isEnabled = true
                for nombre in ["AltarConFloreros", "AltarConPanYFloreros", "AltarCompleto"] {
                    altar.findEntity(named: nombre)?.isEnabled = false
                }

                // Asegura que la zona de toque del mp3 reciba gestos
                if let zona = altar.findEntity(named: "mp3")?.findEntity(named: "ZonaToque"),
                   zona.components[InputTargetComponent.self] == nil {
                    zona.components.set(InputTargetComponent())
                }

                content.add(altar)
                escena = altar
            } catch {
                let detalle = error as NSError
                let mensaje = "No se pudo cargar el altar: \(detalle.localizedDescription)"
                mensajeError = mensaje
                appModel.errorEscena = mensaje
                print("Error cargando altar: \(error)")
            }
            cargando = false
        }
        .gesture(
            SpatialTapGesture().targetedToAnyEntity().onEnded { toque in
                guard toque.entity.isActive else { return }
                var entidad: Entity? = toque.entity
                while let actual = entidad {
                    if actual.name == "mp3" {
                        alternarMusica()
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
            detenerTodo()
            escena = nil
        }
        .overlay {
            if cargando {
                ProgressView("Preparando el altar…").padding().glassBackgroundEffect()
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

    // MARK: - Música y baile

    /// Primer toque: suena la canción y Oliver baila. Segundo toque: pausa y Oliver vuelve a idle.
    private func alternarMusica() {
        guard let escena,
              let radio = escena.findEntity(named: "mp3"),
              let oliverMusica = escena.findEntity(named: "OliverMusica"),
              let oliver = oliverMusica.findEntity(named: "oliver_idle") else {
            print("ERROR: faltan mp3, OliverMusica u oliver_idle.")
            return
        }
        let reposo = escena.findEntity(named: "OliverReposo")

        switch estadoMusica {
        case .detenida:
            guard let recurso = recursoCancion(de: radio) else {
                print("ERROR: no se encontró oliver_song.mp3.")
                return
            }
            let audio = radio.playAudio(recurso)
            audio.completionHandler = {
                Task { @MainActor in volverAIdle(reposo: reposo, baile: oliverMusica, terminado: true) }
            }
            controladorAudio = audio

            mostrarBaile(oliverMusica: oliverMusica, oliver: oliver, reposo: reposo)
            estadoMusica = .sonando

        case .sonando:
            controladorAudio?.pause()
            controladorBaile?.pause()
            volverAIdle(reposo: reposo, baile: oliverMusica, terminado: false)
            estadoMusica = .pausada

        case .pausada:
            controladorAudio?.play()
            mostrarBaile(oliverMusica: oliverMusica, oliver: oliver, reposo: reposo)
            controladorBaile?.resume()
            estadoMusica = .sonando
        }
    }

    /// Busca el audio en la AudioLibrary del mp3 (RCP) o, si no está, lo carga de la escena.
    private func recursoCancion(de radio: Entity) -> AudioResource? {
        if let recurso = radio.components[AudioLibraryComponent.self]?.resources["oliver_song.mp3"] {
            return recurso
        }
        return try? AudioFileResource.load(
            named: "/Root/oliver_song_mp3",
            from: "ExperienciaAltar.usda",
            in: realityKitContentBundle
        )
    }

    /// Oculta a Oliver en reposo y muestra a Oliver bailando.
    private func mostrarBaile(oliverMusica: Entity, oliver: Entity, reposo: Entity?) {
        fijarVisible(reposo, false)
        oliverMusica.isEnabled = true
        fijarVisible(oliverMusica, true)

        // Si ya existe un baile pausado, solo se reanuda (en sincronía con el audio)
        if let controlador = controladorBaile, controlador.isPaused { return }

        guard let baile = oliver.components[AnimationLibraryComponent.self]?.animations["oliver_baila"] else {
            print("ERROR: falta oliver_baila en la Animation Library de oliver_idle.")
            return
        }
        oliver.stopAllAnimations(recursive: true)
        controladorBaile = oliver.playAnimation(baile.repeat(), transitionDuration: 0, startsPaused: false)
    }

    /// Muestra a Oliver en reposo (idle, que sigue animándose) y oculta al que baila.
    private func volverAIdle(reposo: Entity?, baile: Entity, terminado: Bool) {
        fijarVisible(reposo, true)
        fijarVisible(baile, false)
        if terminado {
            controladorBaile?.stop()
            controladorBaile = nil
            controladorAudio = nil
            estadoMusica = .detenida
        }
    }

    private func fijarVisible(_ entidad: Entity?, _ visible: Bool) {
        entidad?.components.set(OpacityComponent(opacity: visible ? 1 : 0))
    }

    private func detenerTodo() {
        controladorAudio?.stop()
        controladorAudio = nil
        controladorBaile?.stop()
        controladorBaile = nil
        escena?.findEntity(named: "mp3")?.stopAllAudio()
        escena?.findEntity(named: "OliverMusica")?.stopAllAnimations(recursive: true)
        estadoMusica = .detenida
    }

    private var textoProgreso: String {
        switch paso {
        case 0: return "Toca el florero para colocarlo"
        case 1: return "Toca el pan de muerto para colocarlo"
        case 2: return "Toca el Skate para colocarlo"
        default:
            return estadoMusica == .sonando
                ? "Toca el MP3 de nuevo para pausar la canción."
                : "¡Altar completo! Toca el MP3 para escuchar la canción."
        }
    }
}

#Preview(immersionStyle: .mixed) {
    VistaRealityKit()
        .environment(AppModel())
}

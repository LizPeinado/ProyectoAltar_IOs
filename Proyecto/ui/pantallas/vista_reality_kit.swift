import simd
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

    // Estado de la musica y el baile
    private enum EstadoMusica { case detenida, sonando, pausada }
    @State private var estadoMusica: EstadoMusica = .detenida
    @State private var controladorAudio: AudioPlaybackController?
    @State private var controladorBaile: AnimationPlaybackController?

    //espacio vacio nuevo.... lets go papoi
    var body: some View {
        RealityView { content in
            appModel.errorEscena = nil
            do {
                let controlador = Entity()
                content.add(controlador)
                let altar = try await Entity(named: "ExperienciaAltar", in: realityKitContentBundle)
                ParticulasOfrendas.preparar(en: altar)
                paso = 0
                actualizar(altar)

                // Asegura que la zona de toque del mp3 reciba gestos
                if let zona = altar.findEntity(named: "mp3")?.findEntity(named: "ZonaToque"),
                   zona.components[InputTargetComponent.self] == nil {
                    zona.components.set(InputTargetComponent())
                }

                controlador.addChild(altar)
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
                    if paso < objetos.count, actual.name == objetos[paso], let altar = escena, !colocando {
                        colocar(actual, en: altar)
                        return
                    }
                    if paso == 3, actual.name == "mp3" {
                        alternarMusica()
                        return
                    }
                    entidad = actual.parent
                }
            }
        )
        .onDisappear {
            colocacion?.cancel()
            colocando = false
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

    private let objetos = ["florero", "pan_muerto", "Skate"]
    @State private var colocando = false
    @State private var colocacion: Task<Void, Never>?

    private func actualizar(_ altar: Entity) {
        for (i, nombre) in ["AltarSinElementos", "AltarConFloreros", "AltarConPanYFloreros", "AltarCompleto"].enumerated() {
            altar.findEntity(named: nombre)?.isEnabled = i == paso
        }
        let guias = altar.findEntity(named: "GuiasPasos")
        for (i, nombre) in ["img_florero", "img_pan", "img_skate", "img_oliver"].enumerated() {
            guias?.findEntity(named: nombre)?.isEnabled = i == paso
        }
        altar.findEntity(named: "mp3")?.isEnabled = paso == 3
        altar.findEntity(named: "OliverMusica")?.isEnabled = false
        altar.findEntity(named: "GuiaOliverMusica")?.isEnabled = false
        if paso == 3, let idle = altar.findEntity(named: "OliverReposo")?.findEntity(named: "oliver_idle"),
           let anim = idle.components[AnimationLibraryComponent.self]?.animations["idle"] ?? idle.availableAnimations.first {
            idle.playAnimation(anim.repeat())
        }
    }

    private func colocar(_ objeto: Entity, en altar: Entity) {
        colocando = true
        let posiciones: [SIMD3<Float>] = [[-0.20210855, 0.34998375, 0.007992597], [0.031656224, -0.86576074, 0.37484542], [0.6551537, 0.42534515, -0.02212952]]
        let escalas: [Float] = [0.9402131, 2.5043864, 0.69758445]
        let destino = Transform(scale: SIMD3(repeating: escalas[paso]), rotation: simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]), translation: posiciones[paso])
        objeto.move(to: destino, relativeTo: objeto.parent, duration: 0.45)
        colocacion = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
            paso += 1
            actualizar(altar)
            colocando = false
        }
    }
 
    // Primer toque: suena la canción y Oliver baila. Segundo toque: pausa y Oliver vuelve a idle.
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

    // Busca el audio en la AudioLibrary del mp3o, si no está, lo carga de la escena.
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

    // Oculta a Oliver en reposo y muestra a Oliver bailando.
    private func mostrarBaile(oliverMusica: Entity, oliver: Entity, reposo: Entity?) {
        fijarVisible(reposo, false)
        oliverMusica.isEnabled = true
        fijarVisible(oliverMusica, true)

        // Si ya existe un baile pausado, solo se reanuda
        if let controlador = controladorBaile, controlador.isPaused { return }

        guard let baile = oliver.components[AnimationLibraryComponent.self]?.animations["oliver_baila"] else {
            print("ERROR: falta oliver_baila en la Animation Library de oliver_idle.")
            return
        }
        oliver.stopAllAnimations(recursive: true)
        controladorBaile = oliver.playAnimation(baile.repeat(), transitionDuration: 0, startsPaused: false)
    }

    // Muestra a Oliver en reposo (idle, que sigue animándose) y oculta al que baila.
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

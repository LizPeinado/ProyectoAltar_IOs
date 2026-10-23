import SwiftUI
import RealityKit
import Foundation

struct ImmersiveView: View {
    // 0: florero, 1: pan, 2: skate, 3: altar terminado.
    @State private var paso = 0
    @State private var escena: Entity?
    @State private var cargando = true
    @State private var mensajeError: String?

    var body: some View {
        RealityView { content in
            do {
                let nuevaEscena = try await cargarEscenaAltar()
                paso = 0
                mostrarPaso(en: nuevaEscena)
                content.add(nuevaEscena)
                escena = nuevaEscena
            } catch {
                mensajeError = "No se pudo cargar el altar: \(error.localizedDescription)"
            }
            cargando = false
        } update: { _ in
            if let escena {
                mostrarPaso(en: escena)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { toque in
                    // El toque puede llegar a una pieza interna del USDZ.
                    var objeto: Entity? = toque.entity
                    while let actual = objeto {
                        if actual.name == "florero" || actual.name == "pan_muerto"
                            || actual.name == "Skate" {
                            tocarObjeto(actual.name)
                            break
                        }
                        objeto = actual.parent
                    }
                }
        )
        .overlay {
            if cargando {
                ProgressView("Cargando altar…")
                    .padding()
                    .glassBackgroundEffect()
            } else if let mensajeError {
                Text(mensajeError)
                    .padding()
                    .glassBackgroundEffect()
            }
        }
    }

    private func tocarObjeto(_ nombre: String) {
        // Solo el objeto del paso actual permite avanzar.
        // Un toque repetido en el objeto anterior no salta pasos.
        switch paso {
        case 0:
            if nombre == "florero" { paso = 1 }
        case 1:
            if nombre == "pan_muerto" { paso = 2 }
        case 2:
            if nombre == "Skate" { paso = 3 }
        default:
            break
        }
    }

    private func mostrarPaso(en escena: Entity) {
        // Ocultar también desactiva los toques de los objetos anteriores.
        for objeto in escena.children {
            objeto.isEnabled = false
        }

        switch paso {
        case 0:
            escena.findEntity(named: "Altar_sin_elementos")?.isEnabled = true
            escena.findEntity(named: "florero")?.isEnabled = true
        case 1:
            escena.findEntity(named: "altar_floreros")?.isEnabled = true
            escena.findEntity(named: "pan_muerto")?.isEnabled = true
        case 2:
            escena.findEntity(named: "altar_panyfloreros")?.isEnabled = true
            escena.findEntity(named: "Skate")?.isEnabled = true
        case 3:
            escena.findEntity(named: "altar_completo")?.isEnabled = true
            escena.findEntity(named: "oliver_tree")?.isEnabled = true
            escena.findEntity(named: "vestido_catrina")?.isEnabled = true
        default:
            break
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}

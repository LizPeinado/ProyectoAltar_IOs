//
//  vista_reality_kit.swift
//  Proyecto
//
//  Created by alumno on 10/28/26.
//

import RealityKit
import RealityKitContent
import SwiftUI

struct VistaRealityKit: View {

    // Etapa actual del altar.
    @State private var paso = 0

    @State private var contenedor: Entity?
    @State private var cargando = true
    @State private var mensajeError: String?

    var body: some View {
        
        RealityView { content in

            let nuevoContenedor = Entity()

            contenedor = nuevoContenedor

            content.add(nuevoContenedor)

            await cargarEscena(paso: 0)

            cargando = false


        }

        .gesture(

            SpatialTapGesture()

                .targetedToAnyEntity()

                .onEnded { toque in

                    var objeto: Entity? = toque.entity
                    

                    while let actual = objeto {

                        if actual.name == "florero"

                            || actual.name == "pan_muerto"

                            || actual.name == "Skate"
                        {

                            let nombre = actual.name

                            Task {

                                await tocarObjeto(nombre)

                            }

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

    // Comprobar si se tocó el objeto correcto.

    private func tocarObjeto(_ nombre: String) async {

        switch paso {

        case 0:

            if nombre == "florero" {
                await cargarEscena(paso: 1)

            }

        case 1:

            if nombre == "pan_muerto" {

                await cargarEscena(paso: 2)

            }

        case 2:

            if nombre == "Skate" {

                await cargarEscena(paso: 3)

            }

        default:

            break

        }

    }

    @MainActor

    private func cargarEscena(paso nuevoPaso: Int) async {

        let nombreEscena: String

        switch nuevoPaso {

        case 0:

            nombreEscena = "AltarSinElementos"

        case 1:

            nombreEscena = "AltarConFloreros"

        case 2:

            nombreEscena = "AltarConPanYFloreros"

        case 3:

            nombreEscena = "AltarCompleto"

        default:

            return

        }

        do {

            // Cargar la escena desde Reality Composer Pro.

            let nuevaEscena = try await Entity(

                named: nombreEscena,

                in: realityKitContentBundle

            )

            // Retirar la escena anterior.

            contenedor?.children.forEach {

                $0.removeFromParent()

            }

            contenedor?.addChild(nuevaEscena)

            paso = nuevoPaso

            mensajeError = nil

        } catch {

            mensajeError = """

                No se pudo cargar la escena \(nombreEscena):

                \(error.localizedDescription)

                """

        }

    }

}

#Preview(immersionStyle: .mixed) {
    VistaRealityKit()
}

import RealityKit
import Foundation

@MainActor
func cargarEscenaAltar() async throws -> Entity {
    let escena = Entity()
    // Metros: frente al usuario y apoyado en el suelo del espacio inmersivo.
    escena.position = [0, 0, -2]

    let altarVacio = try await cargarModelo("Altar_sin_elementos")
    let medidas = altarVacio.visualBounds(relativeTo: altarVacio).extents
    // Los cuatro altares comparten escala para conservar sus proporciones.
    let escalaAltar: Float = 1.4 / max(medidas.x, 0.001)
    prepararModelo(altarVacio, escala: escalaAltar, posicion: .zero)
    escena.addChild(altarVacio)

    for nombre in ["altar_floreros", "altar_panyfloreros", "altar_completo"] {
        let altar = try await cargarModelo(nombre)
        prepararModelo(altar, escala: escalaAltar, posicion: .zero)
        escena.addChild(altar)
    }

    for nombre in ["florero", "pan_muerto", "Skate"] {
        let objeto = try await cargarModelo(nombre)
        let medidas = objeto.visualBounds(relativeTo: objeto).extents
        let escala: Float = 0.35 / max(max(medidas.x, medidas.y), max(medidas.z, 0.001))
        // El objeto para tocar aparece delante del altar, a la derecha.
        prepararModelo(objeto, escala: escala, posicion: [0.95, 0.8, 0.5])
        objeto.generateCollisionShapes(recursive: true)
        objeto.components.set(InputTargetComponent())
        escena.addChild(objeto)
    }

    let oliver = try await cargarModelo("oliver_tree")
    let alturaOliver = oliver.visualBounds(relativeTo: oliver).extents.y
    prepararModelo(oliver, escala: 1.3 / max(alturaOliver, 0.001), posicion: [-1.3, 0, 0])
    escena.addChild(oliver)

    let catrina = try await cargarModelo("vestido_catrina")
    let alturaCatrina = catrina.visualBounds(relativeTo: catrina).extents.y
    prepararModelo(catrina, escala: 1.3 / max(alturaCatrina, 0.001), posicion: [1.3, 0, 0])
    escena.addChild(catrina)

    return escena
}

@MainActor
private func cargarModelo(_ nombre: String) async throws -> Entity {
    // Los archivos de Proyecto/Modelos se incluyen en el bundle de la app.
    let modelo = try await Entity(named: "\(nombre).usdz", in: Bundle.main)
    let contenedor = Entity()
    contenedor.name = nombre
    contenedor.addChild(modelo)
    return contenedor
}

@MainActor
private func prepararModelo(_ contenedor: Entity, escala: Float, posicion: SIMD3<Float>) {
    guard let modelo = contenedor.children.first else { return }
    modelo.scale *= escala
    let limites = contenedor.visualBounds(relativeTo: contenedor)
    // Centramos el modelo y colocamos su parte inferior en la altura indicada.
    modelo.position -= SIMD3<Float>(limites.center.x, limites.min.y, limites.center.z)
    contenedor.position = posicion
}

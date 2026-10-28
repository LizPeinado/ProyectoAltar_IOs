import RealityKit
import RealityKitContent
import SwiftUI
 
struct VistaRealityKit: View {
 
    @State private var paso = 0
    @State private var contenedor: Entity?
    @State private var cargando = true
    @State private var mensajeError: String?
    @State private var procesandoToque = false
 
    private let posiciones: [String: SIMD3<Float>] = [
        "florero": SIMD3<Float>(-0.20, 0.35, 0.0),
        "pan_muerto": SIMD3<Float>(0.0, 0.35, 0.0),
        "Skate": SIMD3<Float>(0.20, 0.35, 0.0)
    ]
 
    var body: some View {
 
        RealityView { content in
 
            let nuevoContenedor = Entity()
            contenedor = nuevoContenedor
            content.add(nuevoContenedor)
 
            await cargarEscena(paso: 0)
 
            cargando = false
 
        } placeholder: {
 
            ProgressView("Preparando el altar...")
                .padding()
                .glassBackgroundEffect()
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { toque in
 
                    var objeto: Entity? = toque.entity
 
                    while let actual = objeto {
 
                        if posiciones[actual.name] != nil {
 
                            let nombre = actual.name
 
                            Task { @MainActor in
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
 
                ProgressView("Preparando el altar...")
                    .padding()
                    .glassBackgroundEffect()
 
            } else if let mensajeError {
 
                Text(mensajeError)
                    .padding()
                    .glassBackgroundEffect()
 
            } else {
 
                VStack(spacing: 8) {
 
                    Text("Día de Muertos")
                        .font(.headline)
 
                    Text(textoProgreso)
                        .font(.subheadline)
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
    }
 
    private var textoProgreso: String {
 
        switch paso {
        case 0:
            return "Toca el florero para colocarlo"
        case 1:
            return "Toca el pan de muerto para colocarlo"
        case 2:
            return "Toca el Skate para colocarlo"
        default:
            return "¡Altar completo!"
        }
    }
 
    @MainActor
    private func tocarObjeto(_ nombre: String) async {
 
        guard !procesandoToque else { return }
 
        let objetoEsperado: String
        let siguientePaso = paso + 1
 
        switch paso {
        case 0:
            objetoEsperado = "florero"
        case 1:
            objetoEsperado = "pan_muerto"
        case 2:
            objetoEsperado = "Skate"
        default:
            return
        }
 
        guard nombre == objetoEsperado else { return }
 
        guard let objeto = buscarObjeto(nombre) else {
            mensajeError = "No se encontró la ofrenda: \(nombre)"
            return
        }
 
        procesandoToque = true
        defer { procesandoToque = false }
 
        // 1. Colocar la ofrenda en la escena actual.
        colocarObjeto(objeto, nombre: nombre)
 
        // 2. Esperar cinco segundos para que se vea el resultado.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
 
        // 3. Cambiar a la siguiente escena.
        await cargarEscena(paso: siguientePaso)
    }
 
    @MainActor
    private func buscarObjeto(_ nombre: String) -> Entity? {
 
        guard let escena = contenedor?.children.first else {
            return nil
        }
 
        return buscarEntidad(nombre, dentroDe: escena)
    }
 
    private func buscarEntidad(
        _ nombre: String,
        dentroDe entidad: Entity
    ) -> Entity? {
 
        if entidad.name == nombre {
            return entidad
        }
 
        for hijo in entidad.children {
            if let encontrado = buscarEntidad(
                nombre,
                dentroDe: hijo
            ) {
                return encontrado
            }
        }
 
        return nil
    }
 
    @MainActor
    private func colocarObjeto(
        _ objeto: Entity,
        nombre: String
    ) {
 
        guard let destino = posiciones[nombre],
              let escena = contenedor?.children.first,
              let padre = objeto.parent else {
            return
        }
 
        // La posición de destino se expresa respecto a la escena.
        let destinoEnMundo = escena.convert(
            position: destino,
            to: nil
        )
 
        let destinoEnPadre = padre.convert(
            position: destinoEnMundo,
            from: nil
        )
 
        objeto.position = destinoEnPadre
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
 
            let nuevaEscena = try await Entity(
                named: nombreEscena,
                in: realityKitContentBundle
            )
 
            contenedor?.children.forEach {
                $0.removeFromParent()
            }
 
            contenedor?.addChild(nuevaEscena)
 
            paso = nuevoPaso
            mensajeError = nil
 
        } catch {
 
            mensajeError = """
            No se pudo cargar \(nombreEscena):
            \(error.localizedDescription)
            """
        }
    }
}
 
#Preview(immersionStyle: .mixed) {
    VistaRealityKit()
}

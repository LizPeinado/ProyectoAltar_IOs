import RealityKit
import SwiftUI

public enum ParticulasOfrendas {
    @MainActor
    public static func preparar(en altar: Entity) {
        let efectos: [(paso: String, objeto: String, tamano: SIMD3<Float>, color: Color)] = [
            ("AltarSinElementos", "florero", [0.26, 0.25, 0.39], Color(red: 1, green: 0.78, blue: 0.27)),
            ("AltarConFloreros", "pan_muerto", [0.16, 0.16, 0.07], Color(red: 1, green: 0.91, blue: 0.43)),
            ("AltarConPanYFloreros", "Skate", [0.30, 0.24, 0.53], Color(red: 1, green: 0.57, blue: 0.16))
        ]

        for efecto in efectos {
            guard let paso = altar.findEntity(named: efecto.paso),
                  let objeto = paso.children.first(where: { $0.name == efecto.objeto }),
                  let origen = objeto.children.first(where: { $0.name == "ParticulasOfrenda" }) else { continue }

            let color = ParticleEmitterComponent.ParticleEmitter.Color(efecto.color)
            var particulas = ParticleEmitterComponent()
            particulas.emitterShape = .box
            particulas.emitterShapeSize = efecto.tamano
            particulas.particlesInheritTransform = true
            particulas.isEmitting = true
            particulas.speed = 0.08
            particulas.speedVariation = 0.035
            particulas.mainEmitter.color = .constant(.single(color))
            particulas.mainEmitter.birthRate = 24
            particulas.mainEmitter.lifeSpan = 0.85
            particulas.mainEmitter.size = 0.009
            particulas.mainEmitter.sizeVariation = 0.004
            particulas.mainEmitter.isLightingEnabled = false
            origen.components.set(particulas)
        }
    }
}

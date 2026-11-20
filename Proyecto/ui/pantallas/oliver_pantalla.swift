import SwiftUI
import UIKit

struct OliverPantalla: View {
    // Foto de Oliver Tree
    private var foto: UIImage? {
        guard let textura = UIImage(named: "foto_oliver")?.cgImage,
              let recorte = textura.cropping(to: CGRect(x: 495, y: 256, width: 494, height: 768)) else {
            return nil
        }
        return UIImage(cgImage: recorte)
    }

    var body: some View {
        // Información directa de Oliver
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .center, spacing: 26) {
                    if let foto {
                        Image(uiImage: foto).resizable().scaledToFit()
                            .frame(width: 150, height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .accessibilityLabel("Retrato de Oliver Tree")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Oliver Tree").font(.largeTitle.bold())
                        Text("Oliver Tree Nickell").font(.title3)
                        Text("Santa Cruz, California, Estados Unidos")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
                Divider()
                bloque("Biografía", texto: "Cantante, compositor, productor y creador audiovisual estadounidense. Su propuesta une música, humor y personajes visuales con una identidad muy reconocible.")
                bloque("Trayectoria", texto: "Ugly is Beautiful (2020), Cowboy Tears (2022) y Alone In A Crowd (2023) muestran distintas etapas de su propuesta musical y visual.")
                bloque("Música e identidad", texto: "Su obra combina pop alternativo, rock y electrónica. La autoaceptación y la búsqueda de un lugar propio forman parte de los temas de Ugly is Beautiful.")
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func bloque(_ titulo: String, texto: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo).font(.headline).foregroundStyle(.orange)
            Text(texto).font(.body).fixedSize(horizontal: false, vertical: true)
        }
    }
}

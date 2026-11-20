import SwiftUI

struct AltarPantalla: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            
            VStack(spacing: 24) {
                Text("Altar de Oliver").font(.largeTitle.bold())
                Text("Música y memoria").font(.title2).foregroundStyle(.secondary)
                Text("Coloca las ofrendas y descubre la música de Oliver en una experiencia inmersiva.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                ToggleImmersiveSpaceButton()
                if let error = appModel.errorEscena {
                    Text(error).font(.callout).foregroundStyle(.orange).textSelection(.enabled)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }
}

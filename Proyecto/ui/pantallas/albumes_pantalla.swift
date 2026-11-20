import SwiftUI

struct AlbumesPantalla: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Elige una canción").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 20)], spacing: 24) {
                        ForEach(cancionesOliver) { cancion in
                            NavigationLink {
                                CancionPantalla(cancion: cancion)
                            } label: {
                                TarjetaCancion(cancion: cancion)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(28)
                .frame(maxWidth: 850)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Álbumes")
        }
        .safeAreaInset(edge: .bottom) { ReproductorBarra() }
    }
}

//
//  ContentView.swift
//  Proyecto
//
//  Created by alumno on 10/19/26.
//

import SwiftUI

struct VistaVentanas: View {
    @Environment(AppModel.self) private var appModel
    @State private var musica = MusicaControl()

    var body: some View {
        TabView {
            Tab("Altar", systemImage: "house.fill") {
                AltarPantalla()
            }
            Tab("Álbumes", systemImage: "square.stack.fill") {
                AlbumesPantalla()
            }
            Tab("Oliver", systemImage: "person.fill") {
                OliverPantalla()
            }
        }
        .tint(.orange)
        .preferredColorScheme(.dark)
        .environment(musica)
        .onChange(of: appModel.immersiveSpaceState) { _, estado in
            if estado != .closed { musica.detener() }
        }
        .onDisappear { musica.detener() }
    }
}

#Preview(windowStyle: .automatic) {
    VistaVentanas()
        .environment(AppModel())
}

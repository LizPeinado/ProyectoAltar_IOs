//
//  ContentView.swift
//  Proyecto
//
//  Created by alumno on 10/19/26.
//

import SwiftUI
import RealityKit

struct VistaVentanas: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack {
            ToggleImmersiveSpaceButton()
            if let error = appModel.errorEscena {
                Text(error)
                    .font(.callout)
                    .textSelection(.enabled)
                    .padding()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    VistaVentanas()
        .environment(AppModel())
}

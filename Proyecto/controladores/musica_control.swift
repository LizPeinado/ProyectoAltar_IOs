import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class MusicaControl: NSObject, AVAudioPlayerDelegate {

    private(set) var cancion: Cancion?
    private(set) var sonando = false
    private(set) var error: String?

    @ObservationIgnored private var reproductor: AVAudioPlayer?

    func seleccionar(_ cancion: Cancion) {
        if self.cancion?.id == cancion.id {
            alternar()
        } else {
            preparar(cancion)
            alternar()
        }
    }

    func alternar() {
        if cancion == nil {
            return
        }

        if let reproductor, reproductor.isPlaying {
            reproductor.pause()
            sonando = false
            return
        }

        do {
            if reproductor == nil {
                let url = Bundle.main.url(
                    forResource: cancion!.archivo,
                    withExtension: "mp3"
                ) ?? Bundle.main.url(
                    forResource: cancion!.archivo,
                    withExtension: "mp3",
                    subdirectory: "recursos/musica"
                )

                if let url {
                    let audio = try AVAudioPlayer(contentsOf: url)
                    audio.delegate = self
                    audio.prepareToPlay()
                    reproductor = audio
                } else {
                    error = "No se encontró el archivo de la canción."
                    return
                }
            }

            sonando = reproductor?.play() ?? false

            if !sonando {
                error = "No se pudo reproducir la canción."
            } else {
                error = nil
            }

        } catch {
            sonando = false
            self.error = "No se pudo abrir el archivo de audio."
        }
    }

    func cambiar(_ salto: Int) {
        if let cancion,
           let indice = cancionesOliver.firstIndex(where: { $0.id == cancion.id }) {

            let estabaSonando = sonando
            let siguiente = (indice + salto + cancionesOliver.count) % cancionesOliver.count

            preparar(cancionesOliver[siguiente])

            if estabaSonando {
                alternar()
            }
        }
    }

    func detener() {
        preparar(nil)
    }

    private func preparar(_ cancion: Cancion?) {
        reproductor?.stop()
        reproductor = nil

        self.cancion = cancion
        sonando = false
        error = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        let id = ObjectIdentifier(player)

        Task { @MainActor [weak self] in
            if let self,
               let audio = self.reproductor,
               ObjectIdentifier(audio) == id {

                self.reproductor = nil
                self.sonando = false

                self.error = flag ? nil : "La reproducción se interrumpió."
            }
        }
    }
}

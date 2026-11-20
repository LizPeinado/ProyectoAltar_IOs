struct Cancion: Identifiable {
    let titulo: String
    let archivo: String
    let portada: String

    var id: String { archivo }
}

let cancionesOliver = [
    Cancion(titulo: "Ugly Is Beautiful", archivo: "ugly_is_beautiful", portada: "album_1514394064"),
    Cancion(titulo: "Cowboy Tears", archivo: "cowboy_tears", portada: "album_1603620507"),
    Cancion(titulo: "Love You Madly", archivo: "love_you_madly", portada: "love_you_madly")
]

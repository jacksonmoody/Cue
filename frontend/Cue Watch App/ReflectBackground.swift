//
//  ReflectBackground.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/30/26.
//

import SwiftUI
import WatchKit

struct ReflectBackground: View {
    let videoTitle: String
    var videoURL: URL? {
        Bundle.main.url(forResource: videoTitle, withExtension: "mp4")
    }

    var body: some View {
        if let url = videoURL {
            InlineMovieView(videoURL: url)
                .frame(width: 500)
                .ignoresSafeArea(.all)
        }
    }
}

private struct InlineMovieView: WKInterfaceObjectRepresentable {
    let videoURL: URL

    func makeWKInterfaceObject(context: Context) -> WKInterfaceInlineMovie {
        WKInterfaceInlineMovie()
    }

    func updateWKInterfaceObject(_ movie: WKInterfaceInlineMovie, context: Context) {
        movie.setVideoGravity(.resizeAspectFill)
        movie.setLoops(true)
        movie.setMovieURL(videoURL)
        movie.setAutoplays(true)
        movie.playFromBeginning()
    }
}

#Preview {
    ReflectBackground(videoTitle: "waves")
}

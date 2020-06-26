//
//  ContentView.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @Binding var document: VideoMemeDocument

    var body: some View {
        ZStack {
            VideoPlayer(player: document.viewModel.player)
            
            VStack {
                TextField("Text", text: $document.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .font(.system(.largeTitle, design: .rounded))
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .padding(.top, 60)
                    .padding()

                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(VideoMemeDocument()))
    }
}

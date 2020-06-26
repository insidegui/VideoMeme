//
//  VideoMemeApp.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import SwiftUI
import Combine

@main
struct VideoMemeApp: App {
    var body: some Scene {
        DocumentScene()
    }
}

struct DocumentScene: Scene {
    
    private let exportCommand = PassthroughSubject<Void, Never>()
    
    var body: some Scene {
        DocumentGroup(viewing: VideoMemeDocument.self) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .onReceive(exportCommand) { _ in
                    file.document.beginExport()
                }
        }.commands {
            CommandMenu("Video") {
                Button("Export…") {
                    exportCommand.send()
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}

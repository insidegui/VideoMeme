//
//  VideoMemeDocument.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

extension UTType {
    static var videoFiles: UTType {
        UTType(importedAs: "public.mpeg-4")
    }
}

struct VideoMemeDocument: FileDocument {

    var renderer = VideoRenderer()
    
    let viewModel = VideoViewModel()
    
    var title = "Enter Title Here"

    static var readableContentTypes: [UTType] { [.videoFiles] }
    
    private let scratchURL: URL
    
    init() { scratchURL = Self.makeTemporaryFileURL() }

    init(fileWrapper: FileWrapper, contentType: UTType) throws {
        let tempURL = Self.makeTemporaryFileURL()
        self.scratchURL = tempURL
        
        guard let videoData = fileWrapper.regularFileContents else { return }
        
        FileManager.default.createFile(atPath: tempURL.path, contents: videoData, attributes: nil)
        
        viewModel.videoURL = tempURL
    }
    
    func write(to fileWrapper: inout FileWrapper, contentType: UTType) throws {
        let videoData = try Data(contentsOf: self.scratchURL)
        let wrapper = FileWrapper(regularFileWithContents: videoData)
        fileWrapper = wrapper
    }

    private static func makeTemporaryFileURL() -> URL {
        let name = UUID().uuidString
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(name)
            .appendingPathExtension("mp4")
    }
    
    func beginExport() {
        let panel = NSSavePanel()
        panel.prompt = "Export"
        panel.allowedFileTypes = ["mp4"]
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        export(to: url)
    }
    
    private func export(to url: URL) {
        guard let item = viewModel.player.currentItem else { return }
        
        renderer.renderClip(playerItem: item, title: title, outputURL: url) { result in
            switch result {
            case .success:
                print("Done")
            case .failure(let error):
                print("Failed to render: \(error)")
            }
        }
    }
    
}

//
//  main_view.swift
//  created by Harri Hilding Smatt on 2026-01-14
//

import Accelerate
import AVFoundation
import SwiftUI

struct MainView : View {
    @State var globeImage: Image = Image(systemName: "globe")
    @State var renderView : RenderView
    @State var showRenderView : Bool = false
    @State var useDarkTheme : Bool = true

    init() {
        let renderView = RenderView()
        self.renderView = renderView
     }

    var body: some View {
        VStack {
            if showRenderView {
                renderView
                    .aspectRatio(contentMode: .fill)
                    .navigationTitle("TRACMO - dj_dave_33_again.mp.3 [mtl visualz]")
                    .frame(width: 800.0, height: 800.0, alignment: .topLeading)
            }
            else {
                ZStack {
                    VStack {
                        if !showRenderView {
                            HStack {
                                globeImage
                                    .imageScale(.large)
                                    .foregroundColor(.red)
                                globeImage
                                    .imageScale(.large)
                                    .foregroundColor(.green)
                                globeImage
                                    .imageScale(.large)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Text("Hello, world!")
                            .fontDesign(.rounded)
                            .fontWidth(.expanded)
                            .fontWeight(.heavy)
                        
                        if !showRenderView {
                            Button("Click me!") {
                                withAnimation {
                                    showRenderView = true
                                    start_demo()
                                }
                            }
                        }
                    }
                    .background(.cyan)
                    .lineSpacing(10.0)
                    .opacity(0.5146)
                }
                .contentMargins(0.0)
                .padding(EdgeInsets())
                .frame(width: 800.0, height: 800.0, alignment: .bottomTrailing)
            }
        }
        .border(.green, width: 1.0)
        .contentMargins(0.0)
        .padding(EdgeInsets())
        .background(.blue)
        .aspectRatio(contentMode: .fill)
        .preferredColorScheme(useDarkTheme ? .dark : .light)
        .transition(.asymmetric(insertion: .opacity, removal: .slide))
        .frame(width: 760.0, height: 832.0, alignment: .center)
        .windowResizeBehavior(.disabled)
        .fixedSize()
    }
    
    func start_demo() {
        do {
            let audioEngine = AVAudioEngine()
            _ = audioEngine.mainMixerNode
            audioEngine.prepare()
            try audioEngine.start()
            
            guard let audioUrl = Bundle.main.url(forResource: "dj_fred", withExtension: "mp3") else {
                print("mp3 not found")
                return
            }
            
            let player = AVAudioPlayerNode()
            let audioFile = try AVAudioFile(forReading: audioUrl)
            let format = audioFile.processingFormat
            
            audioEngine.attach(player)
            audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
            audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 256, format: nil) { (buffer, time) in
                var rms : Float = 0
                vDSP_measqv(buffer.floatChannelData![0], 1, &rms, 256)
                renderView.coordinator.setAudioRmsValue(uint8(rms * 100.0) & 0x03)
                useDarkTheme = uint8(rms * 100.0) <= 2
            }
            
            let restart = { () -> Void in
                DispatchQueue.global(qos: .background).async {
                    showRenderView = false
                    audioEngine.reset()
                    audioEngine.stop()
                }
            }
            player.scheduleFile(audioFile, at: nil, completionHandler: restart)
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

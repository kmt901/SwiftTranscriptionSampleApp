/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The transcript view.
*/

import Foundation
import SwiftUI
import Speech
import AVFoundation

struct TranscriptView: View {
    @Binding var story: Story
    @State var isRecording = false
    @State var isPlaying = false
    
    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber
    
    @State var downloadProgress = 0.0
    
    @State var currentPlaybackTime = 0.0
    
    @State var timer: Timer?
    
    init(story: Binding<Story>) {
        self._story = story
        let transcriber = SpokenWordTranscriber(story: story)
        recorder = Recorder(transcriber: transcriber)
        speechTranscriber = transcriber
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !story.isDone {
                    liveRecordingView
                } else {
                    playbackView
                }
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle(story.title)
        .toolbar {
            ToolbarItem {
                Button {
                    handleRecordingButtonTap()
                } label: {
                    if isRecording {
                        Label("Stop", systemImage: "pause.fill").tint(.red)
                    } else {
                        Label("Record", systemImage: "record.circle").tint(.red)
                    }
                }
                .disabled(story.isDone)
            }
            
            ToolbarItem {
                Button {
                    handlePlayButtonTap()
                } label: {
                    Label("Play", systemImage: isPlaying ? "pause.fill" : "play").foregroundStyle(.blue).font(.title)
                }
                .disabled(!story.isDone)
            }
            
            ToolbarItem {
                ProgressView(value: downloadProgress, total: 100)
            }
            
        }
        .onChange(of: isRecording) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue == true {
                Task {
                    do {
                        // TODO: - Fix Sending main actor-isolated 'self.recorder' to nonisolated instance method 'record(story:)' risks causing data races between nonisolated and main actor-isolated uses
                        try await recorder.record(story: $story)
                    } catch {
                        print("could not record: \(error)")
                    }
                }
            } else {
                Task {
                    // TODO: - Sending main actor-isolated 'self.recorder' to nonisolated instance method 'stopRecording(story:)' risks causing data races between nonisolated and main actor-isolated uses
                    try await recorder.stopRecording(story: $story)
                }
            }
        }
        .onChange(of: isPlaying) {
            handlePlayback()
        }
    }
    
    @ViewBuilder
    var liveRecordingView: some View {
        Text(speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var playbackView: some View {
        textScrollView(attributedString: story.storyBrokenUpByLines())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

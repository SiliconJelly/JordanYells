//
//  ContentView.swift
//  JordanYells
//
//  Created by Sandy Ft Khaotung on 2025/07/03.
//

import SwiftUI

struct Shot: Identifiable {
    let id = UUID()
    let date: Date
    let feedback: String
}

struct UserProfile {
    var name: String = "Jordan Fan"
    var avatar: String = "person.crop.circle"
}

struct ContentView: View {
    var body: some View {
        CameraView()
    }
}

struct VideoRecorderView: View {
    var onFinish: (URL) -> Void = { _ in }
    var body: some View {
        VStack(spacing: 24) {
            Text("Video Recorder Coming Soon")
                .font(.title2)
                .padding()
            Button("Simulate Recording & Analyze") {
                // Simulate a video file URL
                let mockURL = URL(string: "file:///mock/video.mov")!
                onFinish(mockURL)
            }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

struct FeedbackView: View {
    let feedback: String
    var body: some View {
        VStack(spacing: 24) {
            Text("AI Feedback")
                .font(.title2)
                .fontWeight(.bold)
            Text(feedback)
                .font(.body)
                .padding()
            Spacer()
        }
        .padding()
    }
}

struct ProfileView: View {
    let userProfile: UserProfile
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: userProfile.avatar)
                .resizable()
                .frame(width: 80, height: 80)
                .padding()
            Text(userProfile.name)
                .font(.title2)
                .fontWeight(.bold)
            Text("Basketball enthusiast. Ready to improve!")
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

struct GeminiAPI {
    static func mockAnalyze(videoURL: URL) -> String {
        // Return a Michael Jordan-style mock feedback
        return "Not bad! But you gotta keep that elbow in and follow through like a champ. Next time, bend those knees and own the court!"
    }
}

#Preview {
    ContentView()
}

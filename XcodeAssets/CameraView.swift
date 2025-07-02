import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var shotHistory = ShotHistoryService()
    @StateObject private var userProfile = UserProfileService()
    @StateObject private var poseDetection = PoseDetectionService.shared
    @State private var feedbackText: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingHistory: Bool = false
    @State private var showingProfile: Bool = false
    @State private var lastAnalyzedFrame: UIImage?
    @State private var showPoseAnalysis: Bool = true

    var body: some View {
        ZStack {
            if cameraService.cameraPermissionGranted {
                ZStack {
                    CameraPreview(session: cameraService.getPreviewLayer())
                        .ignoresSafeArea()
                    
                    // Pose detection overlay
                    PoseOverlayView(
                        pose: poseDetection.currentPose,
                        confidence: poseDetection.confidence,
                        showAnalysis: showPoseAnalysis
                    )
                }
                
                // Top status bar
                VStack {
                    HStack {
                        if isAnalyzing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing shot...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                        }
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showingProfile = true
                            }) {
                                Image(systemName: userProfile.profile.avatar)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showingHistory = true
                            }) {
                                Image(systemName: "clock.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showPoseAnalysis.toggle()
                            }) {
                                Image(systemName: showPoseAnalysis ? "figure.basketball" : "figure.basketball.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    Spacer()
                }
                
                // Bottom feedback area
                VStack {
                    Spacer()
                    if showFeedback && !feedbackText.isEmpty {
                        FeedbackBubble(text: feedbackText)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                }
                .padding(.bottom, 40)
            } else {
                // Camera permission denied or error state
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let errorMessage = cameraService.errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Open Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .onAppear {
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
        }
        .onReceive(cameraService.$currentFrame) { frame in
            guard let frame = frame else { return }
            analyzeFrame(frame)
            
            // Also analyze pose in real-time
            poseDetection.analyzePose(from: frame) { pose in
                // Pose analysis is handled automatically by the service
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(shotHistory: shotHistory)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(userProfile: userProfile, shotHistory: shotHistory)
        }
    }
    
    private func analyzeFrame(_ frame: UIImage) {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        showFeedback = false
        lastAnalyzedFrame = frame
        
        GeminiAPIService.shared.analyze(frame: frame) { feedback in
            DispatchQueue.main.async {
                self.feedbackText = feedback
                self.isAnalyzing = false
                self.showFeedback = true
                
                // Save shot to history
                let imageData = frame.jpegData(compressionQuality: 0.7)
                let shot = Shot(feedback: feedback, imageData: imageData)
                self.shotHistory.addShot(shot)
                
                // Voice feedback
                if self.userProfile.profile.voiceFeedbackEnabled {
                    VoiceService.shared.speak(feedback)
                }
                
                // Auto-hide feedback after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.showFeedback = false
                    }
                }
            }
        }
    }
}

struct FeedbackBubble: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "basketball.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureVideoPreviewLayer
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        session.frame = UIScreen.main.bounds
        view.layer.addSublayer(session)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        session.frame = uiView.bounds
    }
} 
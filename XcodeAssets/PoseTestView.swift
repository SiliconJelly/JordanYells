import SwiftUI
import Vision
import UIKit

struct PoseTestView: View {
    @StateObject private var poseDetection = PoseDetectionService.shared
    @State private var testImage: UIImage?
    @State private var showingImagePicker = false
    @State private var testResults: [String] = []
    @State private var isRunningTest = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Test Image Display
                    if let testImage = testImage {
                        Image(uiImage: testImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No test image selected")
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    // Test Controls
                    VStack(spacing: 12) {
                        Button("Select Test Image") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Run Pose Analysis") {
                            runPoseAnalysis()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testImage == nil || isRunningTest)
                        
                        Button("Test with Sample Data") {
                            testWithSampleData()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isRunningTest)
                    }
                    
                    // Real-time Analysis
                    if poseDetection.isAnalyzing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing pose...")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Confidence Display
                    if poseDetection.confidence > 0 {
                        HStack {
                            Text("Confidence:")
                                .fontWeight(.semibold)
                            Text("\(Int(poseDetection.confidence * 100))%")
                                .foregroundColor(confidenceColor)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Current Pose Analysis
                    if let pose = poseDetection.currentPose {
                        PoseAnalysisCard(pose: pose)
                    }
                    
                    // Test Results
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Test Results")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            ForEach(testResults, id: \.self) { result in
                                Text("• \(result)")
                                    .font(.caption)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Pose Detection Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $testImage)
        }
    }
    
    private func runPoseAnalysis() {
        guard let image = testImage else { return }
        
        isRunningTest = true
        testResults.removeAll()
        
        poseDetection.analyzePose(from: image) { pose in
            DispatchQueue.main.async {
                isRunningTest = false
                
                if let pose = pose {
                    testResults.append("✅ Pose detected successfully")
                    testResults.append("Shoulder angle: \(Int(pose.shoulderAngle))°")
                    testResults.append("Elbow angle: \(Int(pose.elbowAngle))°")
                    testResults.append("Knee angle: \(Int(pose.kneeAngle))°")
                    testResults.append("Body alignment: \(Int(pose.bodyAlignment))°")
                    testResults.append("Follow-through: \(Int(pose.followThrough * 100))%")
                    testResults.append("Overall score: \(Int(pose.overallScore))")
                    testResults.append("Feedback: \(pose.formFeedback)")
                } else {
                    testResults.append("❌ No pose detected")
                    testResults.append("Try a different image with a clear person")
                }
            }
        }
    }
    
    private func testWithSampleData() {
        isRunningTest = true
        testResults.removeAll()
        
        // Simulate pose detection with sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let samplePose = BasketballPose(
                shoulderAngle: 92.5,
                elbowAngle: 88.3,
                wristAngle: 47.2,
                kneeAngle: 118.7,
                ankleAngle: 89.1,
                bodyAlignment: 3.2,
                releasePoint: CGPoint(x: 0.52, y: 0.31),
                followThrough: 0.85
            )
            
            poseDetection.currentPose = samplePose
            poseDetection.confidence = 0.87
            
            testResults.append("🧪 Sample data test completed")
            testResults.append("Shoulder angle: \(Int(samplePose.shoulderAngle))°")
            testResults.append("Elbow angle: \(Int(samplePose.elbowAngle))°")
            testResults.append("Knee angle: \(Int(samplePose.kneeAngle))°")
            testResults.append("Body alignment: \(Int(samplePose.bodyAlignment))°")
            testResults.append("Follow-through: \(Int(samplePose.followThrough * 100))%")
            testResults.append("Overall score: \(Int(samplePose.overallScore))")
            testResults.append("Feedback: \(samplePose.formFeedback)")
            
            isRunningTest = false
        }
    }
    
    private var confidenceColor: Color {
        switch poseDetection.confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
}

struct PoseAnalysisCard: View {
    let pose: BasketballPose
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pose Analysis")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                AnalysisRow(title: "Shoulder Angle", value: "\(Int(pose.shoulderAngle))°", ideal: "90°", isGood: abs(pose.shoulderAngle - 90) < 10)
                AnalysisRow(title: "Elbow Angle", value: "\(Int(pose.elbowAngle))°", ideal: "90°", isGood: abs(pose.elbowAngle - 90) < 10)
                AnalysisRow(title: "Knee Angle", value: "\(Int(pose.kneeAngle))°", ideal: "120°", isGood: abs(pose.kneeAngle - 120) < 20)
                AnalysisRow(title: "Body Alignment", value: "\(Int(pose.bodyAlignment))°", ideal: "0°", isGood: pose.bodyAlignment < 10)
                AnalysisRow(title: "Follow-through", value: "\(Int(pose.followThrough * 100))%", ideal: "80%", isGood: pose.followThrough > 0.7)
            }
            
            Divider()
            
            HStack {
                Text("Overall Score:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(pose.overallScore))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            Text(pose.formFeedback)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        switch pose.overallScore {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default: return .red
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let ideal: String
    let isGood: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isGood ? .green : .orange)
            
            Spacer()
            
            Text("(\(ideal))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
struct PoseTestView_Previews: PreviewProvider {
    static var previews: some View {
        PoseTestView()
    }
}
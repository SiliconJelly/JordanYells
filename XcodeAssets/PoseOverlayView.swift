import SwiftUI
import Vision

struct PoseOverlayView: View {
    let pose: BasketballPose?
    let confidence: Double
    let showAnalysis: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pose visualization
                if let pose = pose, confidence > 0.5 {
                    PoseVisualizationView(pose: pose, size: geometry.size)
                        .opacity(showAnalysis ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: showAnalysis)
                }
                
                // Form score indicator
                if let pose = pose, showAnalysis {
                    VStack {
                        HStack {
                            FormScoreView(score: pose.overallScore)
                            Spacer()
                        }
                        .padding(.top, 100)
                        .padding(.leading, 20)
                        Spacer()
                    }
                }
                
                // Confidence indicator
                if confidence > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            ConfidenceIndicator(confidence: confidence)
                                .padding(.top, 100)
                                .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

struct PoseVisualizationView: View {
    let pose: BasketballPose
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw body skeleton
            drawSkeleton(context: context, size: size)
            
            // Draw angle indicators
            drawAngles(context: context, size: size)
            
            // Draw form feedback
            drawFormFeedback(context: context, size: size)
        }
    }
    
    private func drawSkeleton(context: GraphicsContext, size: CGSize) {
        // This would draw the actual skeleton based on pose points
        // For now, we'll create a simplified visualization
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Draw basic body outline
        let bodyPath = Path { path in
            path.move(to: CGPoint(x: centerX, y: centerY - 100))
            path.addLine(to: CGPoint(x: centerX, y: centerY + 100))
        }
        
        context.stroke(bodyPath, with: .color(.green), lineWidth: 3)
        
        // Draw arms
        let leftArmPath = Path { path in
            path.move(to: CGPoint(x: centerX - 20, y: centerY - 80))
            path.addLine(to: CGPoint(x: centerX - 60, y: centerY - 40))
        }
        
        let rightArmPath = Path { path in
            path.move(to: CGPoint(x: centerX + 20, y: centerY - 80))
            path.addLine(to: CGPoint(x: centerX + 60, y: centerY - 40))
        }
        
        context.stroke(leftArmPath, with: .color(.blue), lineWidth: 2)
        context.stroke(rightArmPath, with: .color(.blue), lineWidth: 2)
        
        // Draw joints
        let joints = [
            CGPoint(x: centerX, y: centerY - 80), // Shoulders
            CGPoint(x: centerX - 40, y: centerY - 60), // Left elbow
            CGPoint(x: centerX + 40, y: centerY - 60), // Right elbow
            CGPoint(x: centerX, y: centerY), // Hips
            CGPoint(x: centerX, y: centerY + 60), // Knees
            CGPoint(x: centerX, y: centerY + 120) // Ankles
        ]
        
        for joint in joints {
            let jointPath = Path { path in
                path.addEllipse(in: CGRect(x: joint.x - 5, y: joint.y - 5, width: 10, height: 10))
            }
            context.fill(jointPath, with: .color(.red))
        }
    }
    
    private func drawAngles(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Draw angle indicators
        let shoulderAngleText = Text("Shoulder: \(Int(pose.shoulderAngle))°")
            .font(.caption)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.7))
            .padding(4)
            .cornerRadius(4)
        
        let elbowAngleText = Text("Elbow: \(Int(pose.elbowAngle))°")
            .font(.caption)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.7))
            .padding(4)
            .cornerRadius(4)
        
        let kneeAngleText = Text("Knee: \(Int(pose.kneeAngle))°")
            .font(.caption)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.7))
            .padding(4)
            .cornerRadius(4)
        
        context.draw(shoulderAngleText, at: CGPoint(x: centerX - 80, y: centerY - 100))
        context.draw(elbowAngleText, at: CGPoint(x: centerX - 80, y: centerY - 60))
        context.draw(kneeAngleText, at: CGPoint(x: centerX - 80, y: centerY + 40))
    }
    
    private func drawFormFeedback(context: GraphicsContext, size: CGSize) {
        let feedback = pose.formFeedback
        let feedbackText = Text(feedback)
            .font(.caption)
            .foregroundColor(.white)
            .background(Color.orange.opacity(0.8))
            .padding(8)
            .cornerRadius(8)
        
        context.draw(feedbackText, at: CGPoint(x: size.width / 2, y: size.height - 100))
    }
}

struct FormScoreView: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Form Score")
                .font(.caption)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: score)
                
                Text("\(Int(score))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        switch score {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default: return .red
        }
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(6)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
}

// MARK: - Preview
struct PoseOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            PoseOverlayView(
                pose: BasketballPose(
                    shoulderAngle: 90,
                    elbowAngle: 85,
                    wristAngle: 45,
                    kneeAngle: 120,
                    ankleAngle: 90,
                    bodyAlignment: 5,
                    releasePoint: CGPoint(x: 0.5, y: 0.3),
                    followThrough: 0.8
                ),
                confidence: 0.85,
                showAnalysis: true
            )
        }
    }
} 
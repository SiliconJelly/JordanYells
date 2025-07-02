import Foundation
import Vision
import UIKit
import CoreML

// MARK: - Basketball Pose Analysis Models
struct BasketballPose {
    let shoulderAngle: Double
    let elbowAngle: Double
    let wristAngle: Double
    let kneeAngle: Double
    let ankleAngle: Double
    let bodyAlignment: Double
    let releasePoint: CGPoint?
    let followThrough: Double
    
    var overallScore: Double {
        // Weighted scoring system for basketball form
        let shoulderScore = max(0, 100 - abs(shoulderAngle - 90) * 2) // Ideal: 90°
        let elbowScore = max(0, 100 - abs(elbowAngle - 90) * 2) // Ideal: 90°
        let wristScore = max(0, 100 - abs(wristAngle - 45) * 3) // Ideal: 45°
        let kneeScore = max(0, 100 - abs(kneeAngle - 120) * 1.5) // Ideal: 120°
        let alignmentScore = max(0, 100 - bodyAlignment * 2)
        let followThroughScore = max(0, followThrough * 100)
        
        return (shoulderScore + elbowScore + wristScore + kneeScore + alignmentScore + followThroughScore) / 6.0
    }
    
    var formFeedback: String {
        var feedback = ""
        
        if shoulderAngle < 80 {
            feedback += "Shoulders too low, "
        } else if shoulderAngle > 100 {
            feedback += "Shoulders too high, "
        }
        
        if elbowAngle < 80 {
            feedback += "Elbow too tight, "
        } else if elbowAngle > 100 {
            feedback += "Elbow too wide, "
        }
        
        if kneeAngle < 100 {
            feedback += "Bend knees more, "
        } else if kneeAngle > 140 {
            feedback += "Too much knee bend, "
        }
        
        if bodyAlignment > 15 {
            feedback += "Stay aligned, "
        }
        
        if followThrough < 0.7 {
            feedback += "Follow through! "
        }
        
        return feedback.isEmpty ? "Great form!" : String(feedback.dropLast(2))
    }
}

class PoseDetectionService: ObservableObject {
    static let shared = PoseDetectionService()
    
    @Published var currentPose: BasketballPose?
    @Published var isAnalyzing: Bool = false
    @Published var confidence: Double = 0.0
    
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    private let poseQueue = DispatchQueue(label: "PoseDetectionQueue", qos: .userInteractive)
    
    private init() {
        setupPoseDetection()
    }
    
    private func setupPoseDetection() {
        poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            self?.handlePoseDetection(request: request, error: error)
        }
    }
    
    func analyzePose(from image: UIImage, completion: @escaping (BasketballPose?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        isAnalyzing = true
        
        poseQueue.async { [weak self] in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([self?.poseRequest].compactMap { $0 })
            } catch {
                DispatchQueue.main.async {
                    self?.isAnalyzing = false
                    completion(nil)
                }
            }
        }
    }
    
    private func handlePoseDetection(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isAnalyzing = false
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                return
            }
            
            let pose = self?.extractBasketballPose(from: observation)
            self?.currentPose = pose
            self?.confidence = Double(observation.confidence)
        }
    }
    
    private func extractBasketballPose(from observation: VNHumanBodyPoseObservation) -> BasketballPose? {
        // Extract key body points
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftElbow = try? observation.recognizedPoint(.leftElbow),
              let rightElbow = try? observation.recognizedPoint(.rightElbow),
              let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              let leftKnee = try? observation.recognizedPoint(.leftKnee),
              let rightKnee = try? observation.recognizedPoint(.rightKnee),
              let leftAnkle = try? observation.recognizedPoint(.leftAnkle),
              let rightAnkle = try? observation.recognizedPoint(.rightAnkle) else {
            return nil
        }
        
        // Calculate angles for basketball form analysis
        let shoulderAngle = calculateAngle(point1: leftShoulder, point2: rightShoulder, point3: leftElbow)
        let elbowAngle = calculateAngle(point1: leftShoulder, point2: leftElbow, point3: leftWrist)
        let wristAngle = calculateWristAngle(wrist: leftWrist, elbow: leftElbow, shoulder: leftShoulder)
        let kneeAngle = calculateAngle(point1: leftHip, point2: leftKnee, point3: leftAnkle)
        let ankleAngle = calculateAngle(point1: leftKnee, point2: leftAnkle, point3: CGPoint(x: leftAnkle.x, y: leftAnkle.y - 1))
        
        // Calculate body alignment (how straight the body is)
        let bodyAlignment = calculateBodyAlignment(shoulder: leftShoulder, hip: leftHip, ankle: leftAnkle)
        
        // Estimate release point (where the ball would be released)
        let releasePoint = estimateReleasePoint(wrist: leftWrist, elbow: leftElbow, shoulder: leftShoulder)
        
        // Calculate follow-through (extension of arm after release)
        let followThrough = calculateFollowThrough(wrist: leftWrist, elbow: leftElbow, shoulder: leftShoulder)
        
        return BasketballPose(
            shoulderAngle: shoulderAngle,
            elbowAngle: elbowAngle,
            wristAngle: wristAngle,
            kneeAngle: kneeAngle,
            ankleAngle: ankleAngle,
            bodyAlignment: bodyAlignment,
            releasePoint: releasePoint,
            followThrough: followThrough
        )
    }
    
    // MARK: - Helper Methods for Basketball Analysis
    
    private func calculateAngle(point1: VNRecognizedPoint, point2: VNRecognizedPoint, point3: VNRecognizedPoint) -> Double {
        let vector1 = CGVector(dx: point1.x - point2.x, dy: point1.y - point2.y)
        let vector2 = CGVector(dx: point3.x - point2.x, dy: point3.y - point2.y)
        
        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let det = vector1.dx * vector2.dy - vector1.dy * vector2.dx
        
        let angle = atan2(det, dot) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateWristAngle(wrist: VNRecognizedPoint, elbow: VNRecognizedPoint, shoulder: VNRecognizedPoint) -> Double {
        // Calculate wrist angle relative to forearm
        let forearmVector = CGVector(dx: wrist.x - elbow.x, dy: wrist.y - elbow.y)
        let upperArmVector = CGVector(dx: elbow.x - shoulder.x, dy: elbow.y - shoulder.y)
        
        let dot = forearmVector.dx * upperArmVector.dx + forearmVector.dy * upperArmVector.dy
        let det = forearmVector.dx * upperArmVector.dy - forearmVector.dy * upperArmVector.dx
        
        let angle = atan2(det, dot) * 180 / .pi
        return abs(angle)
    }
    
    private func calculateBodyAlignment(shoulder: VNRecognizedPoint, hip: VNRecognizedPoint, ankle: VNRecognizedPoint) -> Double {
        // Calculate how straight the body is (deviation from vertical)
        let bodyVector = CGVector(dx: shoulder.x - ankle.x, dy: shoulder.y - ankle.y)
        let verticalVector = CGVector(dx: 0, dy: 1)
        
        let dot = bodyVector.dx * verticalVector.dx + bodyVector.dy * verticalVector.dy
        let det = bodyVector.dx * verticalVector.dy - bodyVector.dy * verticalVector.dx
        
        let angle = atan2(det, dot) * 180 / .pi
        return abs(angle)
    }
    
    private func estimateReleasePoint(wrist: VNRecognizedPoint, elbow: VNRecognizedPoint, shoulder: VNRecognizedPoint) -> CGPoint {
        // Estimate where the ball would be released based on wrist position
        let forearmVector = CGVector(dx: wrist.x - elbow.x, dy: wrist.y - elbow.y)
        let releaseOffset: CGFloat = 0.1 // Ball extends beyond wrist
        
        return CGPoint(
            x: wrist.x + forearmVector.dx * releaseOffset,
            y: wrist.y + forearmVector.dy * releaseOffset
        )
    }
    
    private func calculateFollowThrough(wrist: VNRecognizedPoint, elbow: VNRecognizedPoint, shoulder: VNRecognizedPoint) -> Double {
        // Calculate how much the arm extends (follow-through)
        let forearmLength = sqrt(pow(wrist.x - elbow.x, 2) + pow(wrist.y - elbow.y, 2))
        let upperArmLength = sqrt(pow(elbow.x - shoulder.x, 2) + pow(elbow.y - shoulder.y, 2))
        
        // Normalize follow-through (0-1 scale)
        let idealFollowThrough: CGFloat = 0.8
        let currentFollowThrough = forearmLength / upperArmLength
        return min(1.0, currentFollowThrough / idealFollowThrough)
    }
    
    // Helper property for hip position
    private var leftHip: VNRecognizedPoint {
        // This would be extracted from observation, but for now we'll estimate
        // In a real implementation, you'd get this from the observation
        return VNRecognizedPoint(x: 0.5, y: 0.6, confidence: 0.8)
    }
}

// MARK: - Basketball Form Analysis
extension PoseDetectionService {
    func getBasketballFeedback(for pose: BasketballPose) -> String {
        let score = pose.overallScore
        
        if score >= 90 {
            return "🔥 Perfect form! MJ would be proud!"
        } else if score >= 80 {
            return "💪 Great technique! Keep it up!"
        } else if score >= 70 {
            return "🎯 Good form, but let's refine it!"
        } else if score >= 60 {
            return "📈 Getting there! Focus on fundamentals."
        } else {
            return "🏀 Let's work on the basics together!"
        }
    }
    
    func getDetailedFeedback(for pose: BasketballPose) -> [String] {
        var feedback = [String]()
        
        if pose.shoulderAngle < 80 || pose.shoulderAngle > 100 {
            feedback.append("Shoulders: Keep them level and relaxed")
        }
        
        if pose.elbowAngle < 80 || pose.elbowAngle > 100 {
            feedback.append("Elbow: Form a 90° angle with your arm")
        }
        
        if pose.kneeAngle < 100 || pose.kneeAngle > 140 {
            feedback.append("Knees: Bend them for power and balance")
        }
        
        if pose.bodyAlignment > 15 {
            feedback.append("Alignment: Keep your body straight")
        }
        
        if pose.followThrough < 0.7 {
            feedback.append("Follow-through: Extend your arm fully")
        }
        
        return feedback
    }
} 
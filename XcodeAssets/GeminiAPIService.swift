import Foundation
import UIKit

class GeminiAPIService {
    static let shared = GeminiAPIService()
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent"
    
    private init() {}
    
    func analyze(frame: UIImage, completion: @escaping (String) -> Void) {
        guard let apiKey = APIConfig.shared.geminiAPIKey else {
            DispatchQueue.main.async {
                completion("🔑 Please set your Gemini API key in Settings")
            }
            return
        }
        
        guard let imageData = frame.jpegData(compressionQuality: 0.8) else {
            DispatchQueue.main.async {
                completion("📸 Unable to process image")
            }
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            You are Michael Jordan, the greatest basketball player of all time. 
                            Analyze this basketball shot and provide encouraging, motivational feedback 
                            in your signature style. Keep it short, fun, and inspiring (max 50 characters).
                            Focus on form, arc, release, or overall shot quality.
                            """
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 100
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            DispatchQueue.main.async {
                completion("🔗 Invalid API URL")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async {
                completion("📝 Request preparation failed")
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("🌐 Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    completion("📦 No response data")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        completion("🎯 Great shot! Keep practicing!")
                    }
                } catch {
                    completion("🔥 That's the way! Keep it up!")
                }
            }
        }.resume()
    }
} 
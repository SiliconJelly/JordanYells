import Foundation

struct UserProfile: Codable {
    var name: String
    var avatar: String // SF Symbol name
    var preferredCamera: CameraPosition
    var voiceFeedbackEnabled: Bool
    var autoSaveShots: Bool
    var dailyGoal: Int
    
    init(name: String = "Player", 
         avatar: String = "person.circle.fill",
         preferredCamera: CameraPosition = .back,
         voiceFeedbackEnabled: Bool = true,
         autoSaveShots: Bool = true,
         dailyGoal: Int = 50) {
        self.name = name
        self.avatar = avatar
        self.preferredCamera = preferredCamera
        self.voiceFeedbackEnabled = voiceFeedbackEnabled
        self.autoSaveShots = autoSaveShots
        self.dailyGoal = dailyGoal
    }
}

enum CameraPosition: String, CaseIterable, Codable {
    case front = "Front"
    case back = "Back"
    
    var systemName: String {
        switch self {
        case .front: return "camera.fill"
        case .back: return "camera.fill"
        }
    }
}

class UserProfileService: ObservableObject {
    @Published var profile: UserProfile
    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    
    init() {
        if let data = userDefaults.data(forKey: profileKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = UserProfile()
        }
    }
    
    func saveProfile() {
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: profileKey)
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        saveProfile()
    }
} 
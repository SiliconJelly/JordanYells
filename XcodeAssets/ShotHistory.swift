import Foundation
import UIKit

struct Shot: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let feedback: String
    let imageData: Data?
    var rating: Int? // 1-5 stars, optional
    
    init(date: Date = Date(), feedback: String, imageData: Data? = nil, rating: Int? = nil) {
        self.date = date
        self.feedback = feedback
        self.imageData = imageData
        self.rating = rating
    }
}

class ShotHistoryService: ObservableObject {
    @Published var shots: [Shot] = []
    private let userDefaults = UserDefaults.standard
    private let shotsKey = "saved_shots"
    
    init() {
        loadShots()
    }
    
    func addShot(_ shot: Shot) {
        shots.insert(shot, at: 0) // Add to beginning
        saveShots()
    }
    
    func removeShot(_ shot: Shot) {
        shots.removeAll { $0.id == shot.id }
        saveShots()
    }
    
    func updateShotRating(_ shot: Shot, rating: Int) {
        if let index = shots.firstIndex(where: { $0.id == shot.id }) {
            shots[index] = Shot(date: shot.date, feedback: shot.feedback, imageData: shot.imageData, rating: rating)
            saveShots()
        }
    }
    
    // MARK: - Statistics
    var totalShots: Int {
        shots.count
    }
    
    var averageRating: Double {
        let ratedShots = shots.compactMap { $0.rating }
        guard !ratedShots.isEmpty else { return 0 }
        return Double(ratedShots.reduce(0, +)) / Double(ratedShots.count)
    }
    
    var todayShots: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return shots.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
    }
    
    var weeklyShots: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return shots.filter { $0.date >= weekAgo }.count
    }
    
    // MARK: - Private Methods
    private func saveShots() {
        do {
            let data = try JSONEncoder().encode(shots)
            userDefaults.set(data, forKey: shotsKey)
        } catch {
            print("Failed to save shots: \(error)")
        }
    }
    
    private func loadShots() {
        guard let data = userDefaults.data(forKey: shotsKey) else { return }
        do {
            shots = try JSONDecoder().decode([Shot].self, from: data)
        } catch {
            print("Failed to load shots: \(error)")
            shots = []
        }
    }
} 
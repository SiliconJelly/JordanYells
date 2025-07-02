import SwiftUI

struct HistoryView: View {
    @ObservedObject var shotHistory: ShotHistoryService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics Header
                StatisticsHeader(shotHistory: shotHistory)
                    .padding()
                
                // Shot History List
                if shotHistory.shots.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(shotHistory.shots) { shot in
                            ShotHistoryRow(shot: shot, shotHistory: shotHistory)
                        }
                        .onDelete(perform: deleteShots)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Shot History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteShots(offsets: IndexSet) {
        for index in offsets {
            shotHistory.removeShot(shotHistory.shots[index])
        }
    }
}

struct StatisticsHeader: View {
    @ObservedObject var shotHistory: ShotHistoryService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(title: "Total Shots", value: "\(shotHistory.totalShots)", icon: "basketball.fill")
                StatCard(title: "Today", value: "\(shotHistory.todayShots)", icon: "calendar")
                StatCard(title: "This Week", value: "\(shotHistory.weeklyShots)", icon: "chart.line.uptrend.xyaxis")
            }
            
            if shotHistory.averageRating > 0 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Average Rating: \(String(format: "%.1f", shotHistory.averageRating))")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ShotHistoryRow: View {
    let shot: Shot
    @ObservedObject var shotHistory: ShotHistoryService
    @State private var showingRating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shot.feedback)
                        .font(.body)
                        .lineLimit(2)
                    
                    Text(shot.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    if let rating = shot.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    } else {
                        Button("Rate") {
                            showingRating = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            if let imageData = shot.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .actionSheet(isPresented: $showingRating) {
            ActionSheet(
                title: Text("Rate this shot"),
                buttons: (1...5).map { rating in
                    .default(Text("\(rating) Star\(rating == 1 ? "" : "s")")) {
                        shotHistory.updateShotRating(shot, rating: rating)
                    }
                } + [.cancel()]
            )
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "basketball")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No shots yet!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start practicing and your shot history will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
} 
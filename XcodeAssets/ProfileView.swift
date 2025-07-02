import SwiftUI

struct ProfileView: View {
    @ObservedObject var userProfile: UserProfileService
    @ObservedObject var shotHistory: ShotHistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var showingNameEdit = false
    @State private var tempName = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section(header: Text("Profile")) {
                    HStack {
                        Image(systemName: userProfile.profile.avatar)
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userProfile.profile.name)
                                .font(.headline)
                            Text("Basketball Player")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            tempName = userProfile.profile.name
                            showingNameEdit = true
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                
                // Stats Section
                Section(header: Text("Statistics")) {
                    StatRow(title: "Total Shots", value: "\(shotHistory.totalShots)", icon: "basketball.fill")
                    StatRow(title: "Today's Shots", value: "\(shotHistory.todayShots)", icon: "calendar")
                    StatRow(title: "Weekly Shots", value: "\(shotHistory.weeklyShots)", icon: "chart.line.uptrend.xyaxis")
                    if shotHistory.averageRating > 0 {
                        StatRow(title: "Average Rating", value: String(format: "%.1f", shotHistory.averageRating), icon: "star.fill")
                    }
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Picker("Preferred Camera", selection: $userProfile.profile.preferredCamera) {
                        ForEach(CameraPosition.allCases, id: \.self) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    .onChange(of: userProfile.profile.preferredCamera) { _ in
                        userProfile.saveProfile()
                    }
                    
                    Toggle("Voice Feedback", isOn: $userProfile.profile.voiceFeedbackEnabled)
                        .onChange(of: userProfile.profile.voiceFeedbackEnabled) { _ in
                            userProfile.saveProfile()
                        }
                    
                    Toggle("Auto-save Shots", isOn: $userProfile.profile.autoSaveShots)
                        .onChange(of: userProfile.profile.autoSaveShots) { _ in
                            userProfile.saveProfile()
                        }
                    
                    HStack {
                        Text("Daily Goal")
                        Spacer()
                        Stepper("\(userProfile.profile.dailyGoal) shots", value: $userProfile.profile.dailyGoal, in: 10...200, step: 10)
                            .onChange(of: userProfile.profile.dailyGoal) { _ in
                                userProfile.saveProfile()
                            }
                    }
                }
                
                // Progress Section
                Section(header: Text("Today's Progress")) {
                    let progress = Double(shotHistory.todayShots) / Double(userProfile.profile.dailyGoal)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(shotHistory.todayShots) / \(userProfile.profile.dailyGoal)")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(progress, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Edit Name", isPresented: $showingNameEdit) {
            TextField("Name", text: $tempName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                userProfile.profile.name = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                userProfile.saveProfile()
            }
        } message: {
            Text("Enter your name")
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
} 
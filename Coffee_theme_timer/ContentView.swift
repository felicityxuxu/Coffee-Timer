//
//  ContentView.swift
//  Coffee_theme_timer
//
//  Created by Yongxu Zhu on 2/13/25.
//

import SwiftUI
import AVFoundation
import Lottie
import StoreKit

struct CoffeeSticker: Identifiable, Codable {
    let id: Int
    let name: String
    var isCollected: Bool
    let isPremium: Bool
    
    var image: Image {
        let imageName = name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "è", with: "e")
        print("Loading image: \(imageName)")
        
        // Add debug check for image existence
        if UIImage(named: imageName) == nil {
            print("⚠️ Warning: Image '\(imageName)' not found in assets")
        } else {
            print("✅ Image '\(imageName)' found successfully")
        }
        
        return Image(imageName)
    }
    
    static let allStickers: [CoffeeSticker] = [
        CoffeeSticker(id: 0, name: "Caffè Americano", isCollected: false, isPremium: false),
        CoffeeSticker(id: 1, name: "Espresso", isCollected: false, isPremium: false),
        CoffeeSticker(id: 2, name: "Caffè Latte", isCollected: false, isPremium: false),
        CoffeeSticker(id: 3, name: "Cappuccino", isCollected: false, isPremium: false),
        CoffeeSticker(id: 4, name: "Caffè Mocha", isCollected: false, isPremium: false),
        CoffeeSticker(id: 5, name: "Flat White", isCollected: false, isPremium: false),
        CoffeeSticker(id: 6, name: "Macchiato", isCollected: false, isPremium: false),
        CoffeeSticker(id: 7, name: "Irish Coffee", isCollected: false, isPremium: false),
        CoffeeSticker(id: 8, name: "Affogato", isCollected: false, isPremium: false),
        CoffeeSticker(id: 9, name: "Ristretto", isCollected: false, isPremium: false),
        CoffeeSticker(id: 10, name: "Turkish Coffee", isCollected: false, isPremium: true),
        CoffeeSticker(id: 11, name: "Vietnamese Coffee", isCollected: false, isPremium: true),
        CoffeeSticker(id: 12, name: "Greek Frappé", isCollected: false, isPremium: true),
        CoffeeSticker(id: 13, name: "Dalgona Coffee", isCollected: false, isPremium: true),
        CoffeeSticker(id: 14, name: "Café Cubano", isCollected: false, isPremium: true),
        CoffeeSticker(id: 15, name: "Café con Leche", isCollected: false, isPremium: true),
        CoffeeSticker(id: 16, name: "Red Eye", isCollected: false, isPremium: true),
        CoffeeSticker(id: 17, name: "Cortado", isCollected: false, isPremium: true),
        CoffeeSticker(id: 18, name: "Café au Lait", isCollected: false, isPremium: true),
        CoffeeSticker(id: 19, name: "Cold Brew", isCollected: false, isPremium: true)
    ]
}

class CoffeeCollection: ObservableObject {
    @Published var stickers: [CoffeeSticker]
    
    init() {
        // Always initialize with all stickers first
        self.stickers = CoffeeSticker.allStickers
        
        // Then try to load saved state
        if let data = UserDefaults.standard.data(forKey: "coffeeStickers"),
           let decoded = try? JSONDecoder().decode([CoffeeSticker].self, from: data) {
            // Only update if the count matches
            if decoded.count == CoffeeSticker.allStickers.count {
                self.stickers = decoded
            } else {
                // If count doesn't match, reset UserDefaults
                UserDefaults.standard.removeObject(forKey: "coffeeStickers")
            }
        }
        
        // Debug print
        print("Loaded \(self.stickers.count) stickers")
    }
    
    func saveStickers() {
        if let encoded = try? JSONEncoder().encode(stickers) {
            UserDefaults.standard.set(encoded, forKey: "coffeeStickers")
        }
    }
    
    func collectRandomSticker() -> CoffeeSticker? {
        let isPremiumUnlocked = UserDefaults.standard.bool(forKey: "isPremiumUnlocked")
        let availableStickers = stickers.enumerated().filter { 
            !$0.element.isCollected && 
            (!$0.element.isPremium || isPremiumUnlocked)
        }
        
        guard !availableStickers.isEmpty else { return nil }
        
        let randomIndex = availableStickers.randomElement()!
        stickers[randomIndex.offset].isCollected = true
        saveStickers()
        return stickers[randomIndex.offset]
    }
    
    func resetCollection() {
        stickers = CoffeeSticker.allStickers
        UserDefaults.standard.removeObject(forKey: "coffeeStickers")
        saveStickers()
    }
}

struct MusicTrack: Identifiable, Equatable {
    let id: Int
    let title: String
    let artist: String
    let duration: String
    let filename: String
    
    static let sampleTracks = [
        MusicTrack(id: 0, title: "Autumn Leaves", artist: "Jazz Café", duration: "3:45", filename: "jazz1"),
        MusicTrack(id: 1, title: "Rainy Day Jazz", artist: "Coffee House", duration: "4:12", filename: "jazz2"),
        MusicTrack(id: 2, title: "Smooth Evening", artist: "Jazz Ensemble", duration: "3:58", filename: "jazz3"),
        MusicTrack(id: 3, title: "Coffee Break", artist: "Jazz Trio", duration: "3:30", filename: "jazz4"),
        MusicTrack(id: 4, title: "Midnight Piano", artist: "Jazz Piano", duration: "4:05", filename: "jazz5"),
        MusicTrack(id: 5, title: "Café Ambience", artist: "Smooth Jazz", duration: "3:50", filename: "jazz6"),
        MusicTrack(id: 6, title: "Gentle Sax", artist: "Jazz Quartet", duration: "4:20", filename: "jazz7"),
        MusicTrack(id: 7, title: "Study Time", artist: "Jazz Lounge", duration: "3:40", filename: "jazz8"),
        MusicTrack(id: 8, title: "Cozy Night", artist: "Jazz Club", duration: "4:15", filename: "jazz9"),
        MusicTrack(id: 9, title: "Morning Jazz", artist: "Coffee Jazz", duration: "3:55", filename: "jazz10")
    ]
}

class MusicPlayer: ObservableObject {
    @Published var currentTrack: MusicTrack?
    @Published var isPlaying: Bool = false
    @Published var selectedTrackId: Int?
    @Published var isPreviewMode: Bool = true
    
    private var audioPlayer: AVAudioPlayer?
    private var previewTimer: Timer?
    
    // Add error handling
    @Published var errorMessage: String?
    @Published var showingError: Bool = false
    
    func togglePlay(track: MusicTrack) {
        if currentTrack?.id == track.id {
            if isPlaying {
                pausePlayback()
            } else {
                startPlayback()
            }
        } else {
            stopPlayback()
            currentTrack = track
            selectedTrackId = track.id
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let track = currentTrack else {
            print("DEBUG: No track selected")
            return
        }
        
        // Debug print to check the filename we're trying to load
        print("DEBUG: Attempting to play track: \(track.filename)")
        
        // Check if file exists in bundle
        let bundle = Bundle.main
        if let path = bundle.path(forResource: track.filename, ofType: "mp3") {
            print("DEBUG: Found file path: \(path)")
            let url = URL(fileURLWithPath: path)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                
                // Set up audio session
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                if isPreviewMode {
                    print("DEBUG: Starting 15-second preview")
                    audioPlayer?.currentTime = 0
                    audioPlayer?.play()
                    previewTimer?.invalidate()
                    previewTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
                        self?.pausePlayback()
                    }
                } else {
                    print("DEBUG: Starting full playback in loop")
                    audioPlayer?.numberOfLoops = -1
                    audioPlayer?.play()
                }
                
                isPlaying = true
            } catch {
                print("DEBUG: Failed to play audio: \(error.localizedDescription)")
                showPlaybackError(message: "Failed to play audio: \(error.localizedDescription)")
            }
        } else {
            print("DEBUG: Could not find audio file: \(track.filename).mp3")
            print("DEBUG: Bundle path: \(bundle.bundlePath)")
            print("DEBUG: Available resources: \(bundle.paths(forResourcesOfType: "mp3", inDirectory: nil))")
            showPlaybackError(message: "Cannot find the music in directory: \(track.filename).mp3")
        }
    }
    
    private func pausePlayback() {
        audioPlayer?.pause()
        previewTimer?.invalidate()
        isPlaying = false
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        previewTimer?.invalidate()
        isPlaying = false
    }
    
    // Call this when starting the timer
    func startTimerPlayback() {
        isPreviewMode = false
        if currentTrack != nil {
            stopPlayback()
            startPlayback()
        }
    }
    
    // Call this when stopping the timer
    func stopTimerPlayback() {
        isPreviewMode = true
        stopPlayback()
    }
    
    // Add error handling
    private func showPlaybackError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showingError = true
        }
    }
}

struct ContentView: View {
    @State private var showingTimer = false
    @State private var showingCollection = false
    @State private var showingMusicSelection = false
    @StateObject private var musicPlayer = MusicPlayer()
    
    var body: some View {
        ZStack {
            // Background color
            Color(uiColor: UIColor(red: 0.95, green: 0.92, blue: 0.90, alpha: 1.00))
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Group for Welcome Message and Coffee Animation (reduced vertical spacing)
                VStack(spacing: 4) {
                    Text("Welcome to Our Virtual Coffee Shop!")
                        .font(.custom("Chalkboard SE", size: 20))
                    LottieView(animationName: "coffee-animation", loopMode: .loop)
                        .frame(width: 500, height: 500)
                }
                .padding(.top, 100)
                
                // Button group moved up with reduced space after animation
                VStack(spacing: 20) {
                    Button(action: {
                        showingTimer = true
                    }) {
                        ActionButtonView(
                            icon: "play.circle.fill",
                            text: "Start Focus Time"
                        )
                    }
                    
                    Button(action: {
                        showingCollection = true
                    }) {
                        ActionButtonView(
                            icon: "star.circle.fill",
                            text: "Coffee Collections"
                        )
                    }
                    
                    Button(action: {
                        showingMusicSelection = true
                    }) {
                        ActionButtonView(
                            icon: "music.note",
                            text: "Background Music"
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingTimer) {
            TimerView(musicPlayer: musicPlayer)
        }
        .sheet(isPresented: $showingCollection) {
            CollectionView()
        }
        .sheet(isPresented: $showingMusicSelection) {
            MusicSelectionView(musicPlayer: musicPlayer)
        }
    }
}

struct ActionButtonView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(text)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(uiColor: UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.00))
        )
        .cornerRadius(15)
    }
}

struct TimerDisplayView: View {
    var body: some View {
        VStack {
            // Replace the Image with LottieView
            LottieView(animationName: "coffee-animation", loopMode: .loop)
                .frame(width: 500, height: 500)
        }
    }
}

struct UnlockCoffeeAlert: View {
    let sticker: CoffeeSticker
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("New Coffee Unlocked! 🎉")
                    .font(.title2)
                    .bold()
                
                Text("You've unlocked: \(sticker.name)")
                    .font(.headline)
                
                sticker.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 2)
                
                Button("Awesome!") {
                    isPresented = false
                }
                .font(.custom("Chalkboard SE", size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.brown)
                .cornerRadius(10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 10)
            )
            .padding(40)
        }
    }
}

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int = 25 * 60
    @State private var initialTime: Int = 25 * 60
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var showingTimeSettings = false
    @StateObject private var collection = CoffeeCollection()
    @State private var showingNewSticker = false
    @State private var newSticker: CoffeeSticker?
    @StateObject private var musicPlayer: MusicPlayer
    
    // Update presetDurations to remove custom option
    private let presetDurations = [
        ("25 min", 25),
        ("45 min", 45),
        ("60 min", 60)
    ]
    
    // Add these properties
    @State private var minutes: Int = 25
    @State private var seconds: Int = 0
    
    // Update to cool medium brown
    private let progressBrown = Color(uiColor: UIColor(red: 0.6, green: 0.45, blue: 0.35, alpha: 1.0))
    @State private var showHomeButton = false
    
    // Add enum for coffee making stages
    enum CoffeeStage: String, CaseIterable {
        case grinding = "coffee-grinder"
        case tampering = "coffee-tampering"
        case brewing = "coffee-brewing"
        case filtering = "coffee-filtering"
        
        var animationName: String {
            return self.rawValue
        }
    }
    
    // Add state for current animation stage
    @State private var currentStage: CoffeeStage = .grinding
    
    init(musicPlayer: MusicPlayer) {
        _musicPlayer = StateObject(wrappedValue: musicPlayer)
    }
    
    // Helper function to determine scale based on animation name
    private func getAnimationScale(_ animationName: String) -> CGFloat {
        switch animationName {
        case "coffee-grinder":
            return 0.6  // Keep grinder animation at current scale
        case "coffee-tampering":
            return 0.6  // Keep tampering animation at current scale
        case "coffee-brewing":
            return 0.8  // Increase brewing animation scale
        case "coffee-filtering":
            return 0.8  // Increase filtering animation scale
        default:
            return 1.2
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: UIColor(red: 0.95, green: 0.92, blue: 0.90, alpha: 1.00))
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Add home button at the top if timer is completed
                if showHomeButton {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Return Home")
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(progressBrown)
                        )
                    }
                    .padding(.bottom, 5)
                }
                
                // Timer Circle with Animation
                ZStack {
                    // Circular Progress
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressBrown, style: StrokeStyle(
                            lineWidth: 20,
                            lineCap: .round
                        ))
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: progress)
                    
                    // Updated Lottie Animation with larger scale
                    LottieView(
                        animationName: currentStage.animationName,
                        loopMode: .loop,
                        scale: getAnimationScale(currentStage.animationName)
                    )
                    .frame(width: 500, height: 500)
                }
                .padding(.top, 20)
                
                // Timer Display (directly after progress circle)
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.brown)
                    .padding(.top, -80)
                
                // Preset Duration Buttons
                HStack(spacing: 20) {
                    ForEach(presetDurations, id: \.0) { title, minutes in
                        Button(action: {
                            if !isRunning {
                                initialTime = minutes * 60
                                timeRemaining = initialTime
                            }
                        }) {
                            Text(title)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(initialTime == minutes * 60 ? Color.brown : Color.gray)
                                )
                        }
                        .disabled(isRunning)
                    }
                }
                .padding(.top, 5)
                
                // Custom Duration Pickers
                if !isRunning {
                    HStack(spacing: 30) {
                        // Minutes Picker
                        VStack(spacing: 8) {
                            Text("Minutes")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(uiColor: UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.00)))
                            Picker("", selection: $minutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.brown)
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 80)
                            .clipped()
                        }
                        
                        // Seconds Picker
                        VStack(spacing: 8) {
                            Text("Seconds")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(uiColor: UIColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.00)))
                            Picker("", selection: $seconds) {
                                ForEach(0...59, id: \.self) { second in
                                    Text("\(second)")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.brown)
                                        .tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 80)
                            .clipped()
                        }
                    }
                    .padding(.vertical, 5)
                    .onChange(of: minutes, initial: false) { _, newValue in
                        updateCustomTime()
                    }
                    .onChange(of: seconds, initial: false) { _, newValue in
                        updateCustomTime()
                    }
                }
                
                Spacer(minLength: 20)
                
                // Control Buttons
                HStack(spacing: 50) {
                    // Start/Pause Button
                    Button(action: toggleTimer) {
                        Circle()
                            .fill(progressBrown)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Stop Button
                    Button(action: stopTimer) {
                        Circle()
                            .fill(progressBrown)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.bottom, 50)
                
                // Add close button at bottom right
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(progressBrown)
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding()
            .overlay {
                if showingNewSticker, let sticker = newSticker {
                    UnlockCoffeeAlert(sticker: sticker, isPresented: $showingNewSticker)
                }
            }
        }
    }
    
    private var progress: Double {
        Double(timeRemaining) / Double(initialTime)
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
            musicPlayer.stopPlayback() // Stop music when paused
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        showHomeButton = false
        musicPlayer.startTimerPlayback()
        currentStage = .grinding // Reset to first stage
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                updateCoffeeStage() // Update animation stage
            } else {
                stopTimerWithoutDismiss()
                if let sticker = collection.collectRandomSticker() {
                    newSticker = sticker
                    showingNewSticker = true
                }
                showHomeButton = true
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        pauseTimer()
        musicPlayer.stopPlayback()
        resetTimer()
        dismiss()
    }
    
    private func stopTimerWithoutDismiss() {
        pauseTimer()
        musicPlayer.stopPlayback()
        resetTimer()
    }
    
    // Add new function to reset timer
    private func resetTimer() {
        timeRemaining = initialTime
        if !isRunning {
            // Reset to custom time if pickers are set
            let customTime = minutes * 60 + seconds
            if customTime > 0 {
                initialTime = customTime
                timeRemaining = customTime
            }
        }
    }
    
    // Update updateCustomTime
    private func updateCustomTime() {
        if !isRunning {
            let newTime = minutes * 60 + seconds
            if newTime > 0 {
                initialTime = newTime
                timeRemaining = newTime
            }
        }
    }
    
    // Update the updateCoffeeStage function to include debug print
    private func updateCoffeeStage() {
        let totalTime = initialTime
        let stageTime = totalTime / 4
        let timeElapsed = initialTime - timeRemaining
        
        let newStage: CoffeeStage
        switch timeElapsed {
        case 0..<stageTime:
            newStage = .grinding
        case stageTime..<(stageTime * 2):
            newStage = .tampering
        case (stageTime * 2)..<(stageTime * 3):
            newStage = .brewing
        default:
            newStage = .filtering
        }
        
        if currentStage != newStage {
            print("Changing stage from \(currentStage) to \(newStage) at time \(timeElapsed)/\(totalTime)")
            currentStage = newStage
        }
    }
}

struct TimeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var initialTime: Int
    @Binding var timeRemaining: Int
    @State private var minutes: Int = 25
    @State private var seconds: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Duration")) {
                    HStack {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        Text("min")
                            .foregroundColor(.gray)
                        
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0...59, id: \.self) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        Text("sec")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Text("Total time: \(minutes):\(String(format: "%02d", seconds))")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.brown)
                }
            }
            .navigationTitle("Custom Duration")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let newTime = minutes * 60 + seconds
                    if newTime > 0 {
                        initialTime = newTime
                        timeRemaining = newTime
                        dismiss()
                    }
                }
                .disabled(minutes == 0 && seconds == 0)
            )
        }
        .onAppear {
            minutes = initialTime / 60
            seconds = initialTime % 60
        }
    }
}

// Add this class to handle purchases
class StoreManager: ObservableObject {
    @Published var isPremiumUnlocked = false
    static let premiumStickersId = "com.coffee.premium.stickers"
    
    init() {
        // Check if premium is already unlocked
        isPremiumUnlocked = UserDefaults.standard.bool(forKey: "isPremiumUnlocked")
        
        // Start listening for transactions
        Task {
            await observeTransactionUpdates()
        }
    }
    
    @MainActor
    func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                // Handle successful transaction
                isPremiumUnlocked = true
                UserDefaults.standard.set(true, forKey: "isPremiumUnlocked")
                await transaction.finish()
            }
        }
    }
}

// Update CollectionView to include purchase button
struct CollectionView: View {
    @StateObject private var collection = CoffeeCollection()
    @StateObject private var storeManager = StoreManager()
    @State private var showingPurchaseAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Coffee Collection")
                            .font(.title)
                            .bold()
                        Text("\(collectedCount)/50 Collected")
                            .foregroundColor(.brown)
                    }
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: Double(collectedCount) / 50.0)
                            .stroke(Color.brown, style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            ))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .padding()
                .background(Color(uiColor: UIColor.systemBackground))
                
                if !storeManager.isPremiumUnlocked {
                    VStack {
                        Text("Unlock Premium Coffees")
                            .font(.headline)
                        Text("Get access to 10 exclusive coffee stickers")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button(action: {
                            showingPurchaseAlert = true
                        }) {
                            HStack {
                                Text("Unlock for $5.99")
                                    .font(.custom("Chalkboard SE", size: 14))
                                Image(systemName: "crown.fill")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .padding(.top, 8)  // Add some top padding
                }
                
                // Update GridView to show images
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
                        ForEach(collection.stickers) { sticker in
                            VStack {
                                ZStack(alignment: .topTrailing) {
                                    sticker.image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .opacity(sticker.isCollected ? 1.0 : 0.3)
                                        .shadow(radius: sticker.isCollected ? 2 : 0)
                                    
                                    if sticker.isPremium {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                            .shadow(radius: 2)
                                            .padding(4)
                                    }
                                }
                                
                                Text(sticker.name)
                                    .font(.caption)
                                    .foregroundColor(.brown)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                
                                if sticker.isPremium && !sticker.isCollected {
                                    Text("Premium")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .stroke(Color.yellow, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                        }
                    }
                    .padding()
                }
                .background(Color(uiColor: UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)))
            }
            .navigationTitle("Coffee Collection")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Unlock Premium Coffees", isPresented: $showingPurchaseAlert) {
            Button("Purchase ($5.99)") {
                // Handle purchase
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get access to 10 exclusive premium coffee stickers!")
        }
    }
    
    private var collectedCount: Int {
        collection.stickers.filter { $0.isCollected }.count
    }
}

struct MusicSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var musicPlayer: MusicPlayer
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(uiColor: UIColor(red: 0.95, green: 0.92, blue: 0.90, alpha: 1.00))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(MusicTrack.sampleTracks) { track in
                                MusicTrackRow(
                                    track: track,
                                    isPlaying: musicPlayer.isPlaying && musicPlayer.currentTrack?.id == track.id,
                                    isSelected: musicPlayer.selectedTrackId == track.id,
                                    onTap: {
                                        musicPlayer.togglePlay(track: track)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Now Playing View
                    if let currentTrack = musicPlayer.currentTrack {
                        NowPlayingView(
                            track: currentTrack,
                            isPlaying: musicPlayer.isPlaying
                        ) {
                            musicPlayer.togglePlay(track: currentTrack)
                        }
                    }
                }
            }
            .navigationTitle("Choose Music")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    musicPlayer.stopPlayback()
                    dismiss()
                }
            )
            .alert("Playback Error", isPresented: $musicPlayer.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(musicPlayer.errorMessage ?? "Unknown error occurred")
            }
        }
        .onAppear {
            // Debug print available resources
            print("DEBUG: Available MP3 files in bundle:")
            let paths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
            if !paths.isEmpty {
                paths.forEach { print($0) }
            } else {
                print("DEBUG: No MP3 files found in bundle")
            }
            
            // Set up audio session
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("DEBUG: Failed to set up audio session: \(error)")
            }
        }
        .onDisappear {
            if musicPlayer.isPreviewMode {
                musicPlayer.stopPlayback()
            }
        }
    }
}

struct MusicTrackRow: View {
    let track: MusicTrack
    let isPlaying: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Play/Selected indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brown : Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : .brown)
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(track.artist)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Duration
                Text(track.duration)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NowPlayingView: View {
    let track: MusicTrack
    let isPlaying: Bool
    let onPlayPausePressed: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Now Playing")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(track.title)
                        .font(.system(size: 16, weight: .medium))
                    Text(track.artist)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Play/Pause button
                Button(action: onPlayPausePressed) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.brown)
                }
            }
            .padding()
            .background(Color(uiColor: UIColor.systemBackground))
        }
    }
}

// Update LottieView to include scale
struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let scale: CGFloat
    
    init(animationName: String, loopMode: LottieLoopMode = .loop, scale: CGFloat = 1.0) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.scale = scale
    }
    
    func makeUIView(context: Context) -> UIView {
        // Create a container view to handle scaling
        let containerView = UIView(frame: .zero)
        
        // Create and configure the animation view
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.play()
        
        // Add animation view to container
        containerView.addSubview(animationView)
        
        // Setup constraints
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: scale),
            animationView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: scale),
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the animation view in the container
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        
        // Update animation
        animationView.animation = .named(animationName)
        animationView.play()
    }
}

#Preview {
    ContentView()
}

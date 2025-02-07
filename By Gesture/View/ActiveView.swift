import SwiftUI
import UIKit
import AudioToolbox

struct ActiveView: View {
    @State private var isShowText = false
    @State private var isGone = false
    @State private var isActive = false
    @State private var isPressed = false
    @State private var isTouching = false
    @State private var lastPosition = CGSize.zero
    @State private var lastHapticTime = Date()
    @State private var touchStartTime: Date?
    @State private var holdHapticTimer: Timer?
    
    private let minimumInterval: TimeInterval = 0.082
    private let holdThreshold: TimeInterval = 1.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if isActive {
                activeView
            } else {
                startButton
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBar(hidden: true)
        .onAppear { startHoldHaptic() }
        .onDisappear { stopHoldHaptic() }
    }
    
    private var activeView: some View {
        Color.black
            .edgesIgnoringSafeArea(.all)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged(handleTouch)
                    .onEnded { _ in handleTouchEnd() }
            )
            .simultaneousGesture(
                TapGesture(count: 3).onEnded(closeActiveView)
            )
            .simultaneousGesture(
                TapGesture().onEnded { generateHapticFeedback(.medium) }
            )
            .overlay(
                Text("Tap 3 times to close")
                    .foregroundColor(.white)
                    .fontWeight(.heavy)
                    .opacity(isShowText ? 1 : 0)
                    .onAppear(perform: showTextTemporarily)
            )
    }
    
    private var startButton: some View {
        VStack {
            HStack {
                Image(systemName: "hand.draw.fill")
                Text("START")
            }
            .frame(maxWidth: .infinity)
            .font(.headline.bold())
            .padding()
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(50)
            .overlay(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.white, lineWidth: 3)
            )
            .scaleEffect(isPressed ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .onTapGesture(perform: startActiveMode)
        }
        .frame(width: 152)
        .opacity(isGone ? 0 : 1)
    }
    
    // MARK: - Actions
    private func startActiveMode() {
        isPressed = true
        generateHapticFeedback(.medium)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPressed = false
            withAnimation { isGone = true }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { isActive = true }
            }
        }
    }
    
    private func closeActiveView() {
        withAnimation {
            isActive = false
            isShowText = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { isGone = false }
        }
    }
    
    private func showTextTemporarily() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.75)) { isShowText = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.75)) { isShowText = false }
        }
    }
    
    private func handleTouch(value: DragGesture.Value) {
        isTouching = true
        let currentTime = Date()
        let distance = value.translation.distance(to: lastPosition)
        
        let minMovementThreshold: CGFloat = 0.4
        if distance >= minMovementThreshold && currentTime.timeIntervalSince(lastHapticTime) >= minimumInterval {
            let intensity: UIImpactFeedbackGenerator.FeedbackStyle =
                distance < 3 ? .light : (distance < 6 ? .medium : .heavy)
            generateHapticFeedback(intensity)
            lastHapticTime = currentTime
        }
        
        lastPosition = value.translation
        if touchStartTime == nil { touchStartTime = Date() }
    }
    
    private func handleTouchEnd() {
        isTouching = false
        if let touchStart = touchStartTime, Date().timeIntervalSince(touchStart) > holdThreshold {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        touchStartTime = nil
        lastPosition = .zero
    }
    
    // MARK: - Haptic Feedback
    private func startHoldHaptic() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
            holdHapticTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if isTouching { generateHapticFeedback(.medium) }
            }
        }
    }
    
    private func stopHoldHaptic() {
        holdHapticTimer?.invalidate()
        holdHapticTimer = nil
    }
    
    private func generateHapticFeedback(_ intensity: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: intensity).impactOccurred()
    }
}

// MARK: - Extensions
private extension CGSize {
    func distance(to other: CGSize) -> CGFloat {
        sqrt(pow(width - other.width, 2) + pow(height - other.height, 2))
    }
}

// MARK: - Preview
struct ActiveView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveView()
    }
}

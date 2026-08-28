import Combine
import CoreLocation
import HealthKit
import SwiftUI

class AutonomousRunManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var elapsedSeconds: Int = 0
    @Published var distanceMeters: Double = 0
    @Published var currentPaceSecPerKm: Double = 0
    @Published var heartRate: Double = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var startDate: Date? = nil   // ajustado a cada resume para excluir tempo pausado

    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var elapsedTimer: Timer?
    private var lastLocation: CLLocation?
    private var pauseBegin: Date? = nil
    private var runLocations: [[String: Double]] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 5
    }

    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        healthStore.requestAuthorization(
            toShare: [caloriesType],
            read: [hrType, caloriesType]
        ) { _, _ in }
    }

    func startRun() {
        startDate = Date()
        // startDate @Published — alimenta Text(.timer) na UI sem Timer adicional
        elapsedSeconds = 0
        distanceMeters = 0
        currentPaceSecPerKm = 0
        heartRate = 0
        runLocations = []
        lastLocation = nil
        isActive = true
        isPaused = false
        locationManager.startUpdatingLocation()
        startWorkoutSession()
        startElapsedTimer()
    }

    func pauseRun() {
        isPaused = true
        pauseBegin = Date()
        locationManager.stopUpdatingLocation()
        workoutSession?.pause()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func resumeRun() {
        isPaused = false
        // Avança startDate pelo tempo que ficou pausado, para que Text(.timer) mostre
        // apenas o tempo efetivo de corrida — sem contar o intervalo de pausa.
        if let pb = pauseBegin {
            let pauseDuration = Date().timeIntervalSince(pb)
            startDate = startDate.map { $0.addingTimeInterval(pauseDuration) }
            pauseBegin = nil
        }
        locationManager.startUpdatingLocation()
        workoutSession?.resume()
        startElapsedTimer()
    }

    func finishRun() -> [String: Any] {
        isActive = false
        isPaused = false
        locationManager.stopUpdatingLocation()
        workoutSession?.end()
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        let avgPace = distanceMeters > 0
            ? Double(elapsedSeconds) / (distanceMeters / 1000)
            : 0.0

        let runData: [String: Any] = [
            "elapsedSeconds": elapsedSeconds,
            "distanceMeters": distanceMeters,
            "averagePaceSecPerKm": avgPace,
            "locations": runLocations,
            "startTimestamp": startDate?.timeIntervalSince1970 ?? 0,
            "endTimestamp": Date().timeIntervalSince1970,
            "title": "BLDR Run (Watch)",
        ]

        saveRunDataLocally(runData)
        return runData
    }

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.isActive, !self.isPaused else { return }
            self.elapsedSeconds += 1
        }
    }

    // MARK: — CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isActive, !isPaused else { return }
        runLocations.append([
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
        ])
        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 2 {
                distanceMeters += delta
                if distanceMeters > 50 && elapsedSeconds > 0 {
                    currentPaceSecPerKm = Double(elapsedSeconds) / (distanceMeters / 1000)
                }
            }
        }
        lastLocation = location
    }

    // MARK: — HKWorkoutSession (mantém Watch acordado + FC em tempo real)

    private func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config)
            workoutBuilder?.delegate = self
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            print("[BLDR] WorkoutSession error: \(error)")
        }
    }

    // MARK: — Persistência local (App Group)

    private func saveRunDataLocally(_ data: [String: Any]) {
        guard let defaults = UserDefaults(suiteName: "group.com.bldr.fitness") else { return }
        let key = "pending_run_\(Int(Date().timeIntervalSince1970))"
        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            defaults.set(encoded, forKey: key)
        }
    }

    // MARK: — Formatação

    func formattedPace() -> String {
        guard currentPaceSecPerKm > 0 else { return "--:--" }
        let min = Int(currentPaceSecPerKm) / 60
        let sec = Int(currentPaceSecPerKm) % 60
        return String(format: "%d:%02d/km", min, sec)
    }

    func formattedDistance() -> String {
        String(format: "%.2f km", distanceMeters / 1000)
    }

    func formattedElapsed() -> String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: — FC em tempo real

extension AutonomousRunManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              collectedTypes.contains(hrType) else { return }
        let bpm = workoutBuilder.statistics(for: hrType)?
            .mostRecentQuantity()?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
        DispatchQueue.main.async { self.heartRate = bpm }
    }
}

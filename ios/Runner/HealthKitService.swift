import HealthKit
import Flutter

class HealthKitService: NSObject {
  static let shared = HealthKitService()
  private let healthStore = HKHealthStore()
  private var hrObserverQuery: HKObserverQuery?
  private var eventSink: FlutterEventSink?

  // MARK: — Permissão
  func requestPermission(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false); return
    }
    let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let workoutType = HKObjectType.workoutType()
    healthStore.requestAuthorization(
      toShare: [caloriesType],
      read: [hrType, caloriesType, workoutType]
    ) { success, _ in
      DispatchQueue.main.async { result(success) }
    }
  }

  // MARK: — Treinos recentes do Apple Health
  func fetchRecentWorkouts(
      lookbackHours: Double,
      limit: Int,
      result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(
        code: "HEALTH_DATA_UNAVAILABLE",
        message: "O Apple Health não está disponível neste dispositivo.",
        details: nil))
      return
    }

    let now = Date()
    let start = now.addingTimeInterval(-max(1, lookbackHours) * 60 * 60)
    let predicate = HKQuery.predicateForSamples(
      withStart: start,
      end: now,
      options: .strictEndDate)
    let sort = NSSortDescriptor(
      key: HKSampleSortIdentifierEndDate,
      ascending: false)
    let query = HKSampleQuery(
      sampleType: HKObjectType.workoutType(),
      predicate: predicate,
      limit: max(1, min(limit, 50)),
      sortDescriptors: [sort]
    ) { _, samples, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "HEALTH_WORKOUT_QUERY_FAILED",
            message: "Não foi possível consultar os treinos do Apple Health.",
            details: error.localizedDescription))
        }
        return
      }

      let workouts = (samples as? [HKWorkout]) ?? []
      let formatter = ISO8601DateFormatter()
      let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
      let bpmUnit = HKUnit.count().unitDivided(by: .minute())

      let payload: [[String: Any]] = workouts.map { workout in
        var item: [String: Any] = [
          "id": workout.uuid.uuidString,
          "provider": "apple_watch",
          "activity_type": self.activityName(for: workout.workoutActivityType),
          "started_at": formatter.string(from: workout.startDate),
          "ended_at": formatter.string(from: workout.endDate),
          "duration_s": Int(workout.duration.rounded()),
          "source_name": workout.sourceRevision.source.name,
        ]

        if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
          item["calories"] = Int(calories.rounded())
        }
        if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
          item["distance_km"] = distance / 1000
        }
        if let averageHeartRate = workout.statistics(for: heartRateType)?
          .averageQuantity()?.doubleValue(for: bpmUnit) {
          item["average_heart_rate"] = Int(averageHeartRate.rounded())
        }
        return item
      }

      DispatchQueue.main.async { result(payload) }
    }
    healthStore.execute(query)
  }

  private func activityName(for type: HKWorkoutActivityType) -> String {
    switch type {
    case .traditionalStrengthTraining, .functionalStrengthTraining:
      return "Musculação"
    case .running:
      return "Corrida"
    case .walking:
      return "Caminhada"
    case .cycling:
      return "Ciclismo"
    case .swimming:
      return "Natação"
    case .highIntensityIntervalTraining:
      return "HIIT"
    case .yoga:
      return "Yoga"
    case .soccer:
      return "Futebol"
    case .tennis:
      return "Tênis"
    case .rowing:
      return "Remo"
    case .stairClimbing:
      return "Escada"
    case .elliptical:
      return "Elíptico"
    case .dance:
      return "Dança"
    case .pilates:
      return "Pilates"
    default:
      return "Treino"
    }
  }

  func checkPermission(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false); return
    }
    let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let status = healthStore.authorizationStatus(for: caloriesType)
    result(status == .sharingAuthorized)
  }

  // MARK: — FC em tempo real
  func startHeartRateMonitoring(eventSink: @escaping FlutterEventSink) {
    self.eventSink = eventSink
    let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    hrObserverQuery = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, _, error in
      guard error == nil else { return }
      self?.fetchLatestHeartRate()
    }
    healthStore.execute(hrObserverQuery!)
    healthStore.enableBackgroundDelivery(for: hrType, frequency: .immediate) { _, _ in }
  }

  func stopHeartRateMonitoring() {
    if let query = hrObserverQuery {
      healthStore.stop(query)
      hrObserverQuery = nil
    }
    eventSink = nil
  }

  private func fetchLatestHeartRate() {
    let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: hrType,
      predicate: nil,
      limit: 1,
      sortDescriptors: [sort]
    ) { [weak self] _, samples, _ in
      guard let sample = samples?.first as? HKQuantitySample else { return }
      let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
      DispatchQueue.main.async {
        self?.eventSink?(bpm)
      }
    }
    healthStore.execute(query)
  }

  // MARK: — Calorias do dia
  func fetchTodayCaloriesBurned(result: @escaping FlutterResult) {
    let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(
      withStart: startOfDay, end: now, options: .strictStartDate)

    let query = HKStatisticsQuery(
      quantityType: caloriesType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum
    ) { _, statistics, _ in
      let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
      DispatchQueue.main.async { result(calories) }
    }
    healthStore.execute(query)
  }

  // MARK: — Salvar treino no app Saúde
  func saveWorkoutCalories(
      calories: Double,
      startTimestamp: Double,
      endTimestamp: Double,
      result: @escaping FlutterResult) {
    let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    let startDate = Date(timeIntervalSince1970: startTimestamp / 1000)
    let endDate = Date(timeIntervalSince1970: endTimestamp / 1000)
    let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
    let sample = HKQuantitySample(
      type: caloriesType,
      quantity: quantity,
      start: startDate,
      end: endDate)
    healthStore.save(sample) { success, _ in
      DispatchQueue.main.async { result(success) }
    }
  }
}

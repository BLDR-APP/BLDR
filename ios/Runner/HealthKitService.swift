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
    healthStore.requestAuthorization(
      toShare: [caloriesType],
      read: [hrType, caloriesType]
    ) { success, _ in
      DispatchQueue.main.async { result(success) }
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

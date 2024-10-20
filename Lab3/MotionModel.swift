//
//  MotionModel.swift
//  Lab3
//
//  Created by mingyun zhang on 10/19/24.
//
import CoreMotion

// Define a protocol to allow communication between the MotionModel and the ViewController.
protocol MotionDelegate {
    func activityUpdated(activity: CMMotionActivity)  // Called when a new activity is detected (e.g., walking, running).
    func pedometerUpdated(pedData: CMPedometerData)  // Called when new pedometer data is available (e.g., step count).
}

// The MotionModel class handles motion and pedometer data using CoreMotion.
class MotionModel {
    
    // MARK: =====Class Variables=====
    private let activityManager = CMMotionActivityManager()  // Handles motion activity (e.g., walking, running).
    private let pedometer = CMPedometer()  // Manages step counting and pedometer data.
    var delegate: MotionDelegate? = nil  // Delegate to pass activity and pedometer updates to the ViewController.
    
    // MARK: =====Motion Methods=====
    
    // Start monitoring the user's activity (walking, running, stationary, etc.).
    func startActivityMonitoring() {
        if CMMotionActivityManager.isActivityAvailable() {  // Check if activity monitoring is available on this device.
            self.activityManager.startActivityUpdates(to: OperationQueue.main) { (activity: CMMotionActivity?) in
                if let unwrappedActivity = activity, let delegate = self.delegate {  // Ensure activity and delegate exist.
                    delegate.activityUpdated(activity: unwrappedActivity)  // Notify the delegate of the activity update.
                }
            }
        } else {
            print("Activity monitoring is not available on this device.")  // Handle the case where activity monitoring is unavailable.
        }
    }
    
    // Start monitoring step count using the pedometer, only for today's steps.
    func startPedometerMonitoring() {
        if CMPedometer.isStepCountingAvailable() {  // Check if step counting is available on this device.
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())  // Get the start of the current day (midnight).
            
            // Start receiving pedometer updates from the beginning of today.
            pedometer.startUpdates(from: startOfDay) { (pedData, error) in
                if let error = error {  // Handle any errors that occur while retrieving pedometer data.
                    print("Pedometer error: \(error.localizedDescription)")  // Print the error message.
                    return
                }
                
                if let pedData = pedData, let delegate = self.delegate {  // Ensure pedometer data and delegate exist.
                    DispatchQueue.main.async {
                        delegate.pedometerUpdated(pedData: pedData)  // Notify the delegate with the pedometer update.
                    }
                }
            }
        } else {
            print("Step counting is not available on this device.")  // Handle the case where step counting is unavailable.
        }
    }
    
    // Query the step count for yesterday and return it using a completion handler.
    func fetchYesterdaySteps(completion: @escaping (Int) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of today (midnight).
        guard let startOfToday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            completion(0)  // If the dates can't be calculated, return 0 steps.
            return
        }
        
        // Query the pedometer for step data between the start of yesterday and the start of today.
        pedometer.queryPedometerData(from: startOfYesterday, to: startOfToday) { (data, error) in
            if let error = error {
                print("Error fetching yesterday's steps: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            if let pedData = data {
                completion(Int(truncating: pedData.numberOfSteps))  // Return the number of steps taken yesterday.
            } else {
                completion(0)  // If there was an error, return 0 steps.
            }
        }
    }
}

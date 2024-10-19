//
//  ViewControllerA.swift
//  Lab3
//
//  Created by mingyun zhang on 10/19/24.
//
import UIKit
import CoreMotion

// ViewControllerA manages displaying step data, activity monitoring, and handling the daily goal.
class ViewControllerA: UIViewController, MotionDelegate {

    // Outlets for various UI elements to display steps, activity, and progress towards a goal.
    @IBOutlet weak var stepsTodayLabel: UILabel!
    @IBOutlet weak var stepsYesterdayLabel: UILabel!
    @IBOutlet weak var stepsRemainingLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var goalProgressView: UIProgressView!
    
    let motionModel = MotionModel()  // Instance of MotionModel, which handles step tracking and activity monitoring.
    let dailyGoalKey = "DailyGoal"   // Key for saving/loading the user's daily goal.
    let stepsTodayKey = "StepsToday" // Key for saving/loading the step count for today.
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        motionModel.delegate = self  // Set the delegate to self for receiving motion updates.
        motionModel.startPedometerMonitoring()  // Start monitoring the pedometer for step data.
        motionModel.startActivityMonitoring()   // Start monitoring the activity for the type of motion (walking, running, etc.).
        
        loadDailyGoal()  // Load and display the user's daily step goal.
        updateYesterdaySteps()  // Fetch and update yesterday's step count.
        let savedSteps = loadStepsToday()  // Load today's step count from persistent storage.
        stepsTodayLabel.text = "\(savedSteps) steps today"  // Display today's step count.
        updateRemainingSteps(steps: savedSteps)  // Update the remaining steps to meet today's goal.
        
        // Enlarge the height of the progress bar for better visibility.
        goalProgressView.transform = goalProgressView.transform.scaledBy(x: 1, y: 20)
    }

    // Action triggered when the user presses a button to set a new daily goal.
    @IBAction func setDailyGoal(_ sender: UIButton) {
        showGoalInputDialog()  // Show an input dialog to let the user set their step goal.
    }

    // Display an alert dialog that allows the user to enter a new daily step goal.
    func showGoalInputDialog() {
        let alert = UIAlertController(title: "Set Daily Goal", message: "Enter your daily step goal", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter step goal"  // Prompt the user to enter a step goal.
            textField.keyboardType = .numberPad  // Set the keyboard to only allow numbers.
        }
        
        // Action to confirm the user's input and set the new goal.
        let confirmAction = UIAlertAction(title: "Set", style: .default) { [unowned alert] _ in
            if let textField = alert.textFields?.first, let goal = Int(textField.text!) {
                let todaySteps = self.loadStepsToday()  // Load today's step count.
                if goal > todaySteps {  // Check if the new goal is greater than today's step count.
                    self.saveDailyGoal(goal: goal)  // Save the new goal.
                    self.updateRemainingSteps(steps: todaySteps)  // Update the remaining steps to reach the goal.
                } else {
                    // If the goal is less than or equal to today's step count, show a warning.
                    self.showInvalidGoalAlert()
                }
            }
        }
        
        alert.addAction(confirmAction)  // Add the confirm action to the alert.
        present(alert, animated: true, completion: nil)  // Present the alert to the user.
    }
    
    // Show an alert if the goal entered by the user is invalid (i.e., less than or equal to today's steps).
    func showInvalidGoalAlert() {
        let alert = UIAlertController(title: "Invalid Goal", message: "Your daily goal must be greater than today's steps!", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .default, handler: nil)  // Action to dismiss the alert.
        alert.addAction(okayAction)  // Add the OK action.
        present(alert, animated: true, completion: nil)  // Present the alert to the user.
    }

    // Save the daily goal to persistent storage using UserDefaults.
    func saveDailyGoal(goal: Int) {
        UserDefaults.standard.set(goal, forKey: dailyGoalKey)  // Save the goal under the "DailyGoal" key.
    }
    
    // Load the daily goal from UserDefaults and update the remaining steps to meet the goal.
    func loadDailyGoal() {
        let goal = UserDefaults.standard.integer(forKey: dailyGoalKey)  // Load the daily goal from storage.
        if goal > 0 {
            updateRemainingSteps(steps: loadStepsToday())  // Update the remaining steps if a goal is set.
        } else {
            goalProgressView.progress = 0.0  // Set progress to 0 if no goal is set.
            stepsRemainingLabel.text = "No goal set"  // Indicate that no goal has been set.
        }
    }

    // Save today's step count to persistent storage using UserDefaults.
    func saveStepsToday(steps: Int) {
        UserDefaults.standard.set(steps, forKey: stepsTodayKey)  // Save today's step count under the "StepsToday" key.
    }
    
    // Load today's step count from UserDefaults.
    func loadStepsToday() -> Int {
        return UserDefaults.standard.integer(forKey: stepsTodayKey)  // Return the stored step count for today.
    }
    
    // Update the label and progress bar with the remaining steps to reach the daily goal.
    func updateRemainingSteps(steps: Int) {
        let dailyGoal = UserDefaults.standard.integer(forKey: dailyGoalKey)  // Load the daily goal.
        if dailyGoal > 0 {
            let remainingSteps = max(dailyGoal - steps, 0)  // Calculate how many steps are left, ensuring it's non-negative.
            stepsRemainingLabel.text = "You need \(remainingSteps) more steps to reach \(dailyGoal)"  // Update the label with the remaining steps.
            goalProgressView.progress = Float(steps) / Float(dailyGoal)  // Update the progress bar based on the current progress.
        } else {
            stepsRemainingLabel.text = "No goal set"  // If no goal is set, update the label accordingly.
            goalProgressView.progress = 0.0  // Set progress to 0 if no goal is set.
        }
    }

    // Fetch and update yesterday's step count using the motion model.
    func updateYesterdaySteps() {
        motionModel.fetchYesterdaySteps { steps in  // Fetch yesterday's steps asynchronously.
            DispatchQueue.main.async {
                self.stepsYesterdayLabel.text = "\(steps) steps yesterday"  // Update the label with yesterday's step count.
            }
        }
    }
    
    // MARK: - MotionDelegate Methods
    
    // Method that is called when the activity is updated (e.g., walking, running, cycling).
    func activityUpdated(activity: CMMotionActivity) {
        var currentActivity = "Unknown🤔"  // Default to unknown activity.
        if activity.walking {
            currentActivity = "Walking🚶"  // If the user is walking, update the activity.
        } else if activity.running {
            currentActivity = "Running🏃"  // If the user is running, update the activity.
        } else if activity.cycling {
            currentActivity = "Cycling🚴"  // If the user is cycling, update the activity.
        } else if activity.automotive {
            currentActivity = "Driving🚗"  // If the user is driving, update the activity.
        } else if activity.stationary {
            currentActivity = "Still🤫"  // If the user is stationary, update the activity.
        }
        
        DispatchQueue.main.async {
            self.activityLabel.text = "Current activity: \(currentActivity)"  // Update the activity label on the main thread.
        }
    }
    
    // Method that is called when the pedometer data is updated (i.e., when steps are counted).
    func pedometerUpdated(pedData: CMPedometerData) {
        DispatchQueue.main.async {
            let steps = pedData.numberOfSteps  // Get the number of steps from the pedometer data.
            self.stepsTodayLabel.text = "\(steps) steps today"  // Update the label with today's step count.
            self.updateRemainingSteps(steps: Int(truncating: steps))  // Update the remaining steps based on the current count.
            self.saveStepsToday(steps: Int(truncating: steps))  // Save today's step count persistently.
        }
    }
}

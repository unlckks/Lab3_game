//
//  ViewControllerB.swift
//  Lab3
//
//  Created by mingyun zhang on 10/19/24.
//

import UIKit
import SpriteKit

// ViewControllerB manages the view where the game can be played if the step goal is met.
class ViewControllerB: UIViewController {

    @IBOutlet weak var skView: SKView!  // Outlet for the SpriteKit view where the game will be displayed.
    
    let motionModel = MotionModel()  // A model that handles step tracking (assuming this class exists).
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the properties of the SKView.
        configureSKView()
        
        // Check if the user's steps today meet the goal set by yesterday's steps.
        checkStepEligibility()
    }
    
    // Configures properties of the SKView, initially hiding it until the game is ready to load.
    func configureSKView() {
        skView.showsFPS = true  // Show frames per second in the view for debugging.
        skView.showsNodeCount = true  // Display the number of nodes in the scene.
        skView.ignoresSiblingOrder = true  // Optimize rendering by ignoring sibling node order.
        skView.isHidden = true  // The view is hidden by default, only shown if the game is allowed to start.
    }

    // Checks if the user can play the game by comparing today's steps to yesterday's goal.
    func checkStepEligibility() {
        motionModel.fetchYesterdaySteps { yesterdaySteps in  // Fetch yesterday's step count asynchronously.
            DispatchQueue.main.async {
                let todaySteps = UserDefaults.standard.integer(forKey: "StepsToday") // Retrieve today's step count from storage.
                
                if todaySteps >= yesterdaySteps {
                    // If today's steps meet or exceed yesterday's, allow the user to play the game.
                    self.showAlert(title: "Goal Met!", message: "Congratulations! You can play the game.", playGame: true)
                } else {
                    // If today's steps do not meet the goal, show an alert informing the user.
                    self.showAlert(title: "Goal Not Met", message: "You haven't reached your step goal today. The game is locked.", playGame: false)
                }
            }
        }
    }

    // Shows an alert to the user, either allowing them to play the game or return.
    func showAlert(title: String, message: String, playGame: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if playGame {
            // If the user can play, show an OK button to load the game.
            let okAction = UIAlertAction(title: "play", style: .default) { _ in
                self.loadGameScene()  // Load the game scene if they are eligible.
            }
            alertController.addAction(okAction)
        } else {
            // If the user cannot play, offer a Return option to go back to the previous screen.
            let backAction = UIAlertAction(title: " true", style: .default) { _ in
                self.goBack()  // Navigate back to the previous view controller.
            }
            alertController.addAction(backAction)
        }
        
        // Present the alert to the user.
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Loads the game scene and presents it inside the SKView.
    func loadGameScene() {
        let scene = GameScene(size: skView.bounds.size)  // Create a new game scene with the size of the SKView.
        scene.scaleMode = .resizeFill  // Adjust the scene to fill the available space in the view.
        skView.presentScene(scene)  // Present the scene in the SKView.
        skView.isHidden = false  // Make the SKView visible so the game can be played.
    }
    
    // Navigates back to the previous screen.
    func goBack() {
        self.navigationController?.popViewController(animated: true)  // Pop the current view controller off the navigation stack.
    }
}

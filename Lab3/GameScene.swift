//
//  GameScene.swift
//  Lab3
//
//  Created by mingyun zhang on 10/19/24.
//
import SpriteKit
import CoreMotion
import CoreGraphics
import UIKit

// GameScene manages the game mechanics where the player uses steps as currency to collect falling coins.
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game elements (bag and labels)
    let bag = SKSpriteNode(imageNamed: "bag")  // The player-controlled "bag" node to collect coins.
    let scoreLabel = SKLabelNode(fontNamed: "Arial")  // Label to display the score.
    let stepLabel = SKLabelNode(fontNamed: "Arial")  // Label to display the number of steps.

    // CoreMotion components for tracking movement and steps
    var motionManager = CMMotionManager()  // Manages accelerometer data for controlling the bag.
    var pedometer = CMPedometer()  // Pedometer to track step count.
    
    // Variable to keep track of steps with a didSet to update the step label.
    var stepCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.stepLabel.text = "Steps: \(self.stepCount)"  // Update the step label whenever stepCount changes.
            }
        }
    }
    
    // Tracks how many steps have been "spent" (consumed) in the game.
    var consumedSteps: Int {
        get {
            return UserDefaults.standard.integer(forKey: "consumedSteps")  // Retrieve consumed steps from persistent storage.
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "consumedSteps")  // Save consumed steps to persistent storage.
        }
    }
    
    // Tracks the player's score persistently.
    var savedScore: Int {
        get {
            return UserDefaults.standard.integer(forKey: "score")  // Retrieve saved score from persistent storage.
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "score")  // Save the score persistently.
        }
    }
    
    // Game variables
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"  // Update the score label whenever the score changes.
            savedScore = score  // Save the score persistently.
        }
    }
    
    var missedCoins = 0  // Tracks how many coins the player has missed.
    let maxMissedCoins = 5  // Max number of missed coins allowed before the game ends.
    let stepCostPerCoin = 10  // The cost in steps to collect one coin.
    
    // Define physics categories for collisions
    struct PhysicsCategory {
        static let None: UInt32 = 0
        static let Bag: UInt32 = 0b1  // Binary representation for the bag.
        static let Coin: UInt32 = 0b10  // Binary representation for coins.
    }
    
    // Called when the scene is presented by the view
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor.white  // Set the background color of the scene.
        
        // Set up the world's physics
        physicsWorld.gravity = CGVector(dx: 0, dy: -3)  // Apply gravity to objects in the world.
        physicsWorld.contactDelegate = self  // Set the scene as the contact delegate for collision detection.
        
        // Set up the bag node (player's object)
        bag.position = CGPoint(x: size.width / 2, y: 50)  // Place the bag near the bottom of the screen.
        bag.physicsBody = SKPhysicsBody(rectangleOf: bag.size)  // Add a rectangular physics body to the bag.
        bag.physicsBody?.isDynamic = true  // Allow the bag to move dynamically.
        bag.physicsBody?.affectedByGravity = false  // The bag is not affected by gravity.
        bag.physicsBody?.categoryBitMask = PhysicsCategory.Bag  // Set the bag's physics category.
        bag.physicsBody?.contactTestBitMask = PhysicsCategory.Coin  // The bag should detect collisions with coins.
        bag.physicsBody?.collisionBitMask = PhysicsCategory.None  // The bag doesn't collide with anything.
        addChild(bag)  // Add the bag to the scene.
        
        // Set up the score label
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = UIColor.black
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 40)  // Place the score label in the top right.
        addChild(scoreLabel)
        
        // Set up the step count label
        stepLabel.text = "Steps: 0"
        stepLabel.fontSize = 24
        stepLabel.fontColor = UIColor.black
        stepLabel.position = CGPoint(x: 100, y: size.height - 40)  // Place the step label in the top left.
        addChild(stepLabel)
        
        // Load the saved score from persistent storage.
        score = savedScore
        
        // Start receiving accelerometer data for controlling the bag.
        motionManager.startAccelerometerUpdates()
        
        // Start receiving pedometer updates for counting steps.
        startPedometerUpdates()
        
        // Spawn coins at regular intervals (1 second)
        let spawnAction = SKAction.run(spawnCoin)  // Action to spawn a coin.
        let waitAction = SKAction.wait(forDuration: 1.0)  // Wait for 1 second before the next spawn.
        let spawnSequence = SKAction.sequence([spawnAction, waitAction])  // Sequence of spawning and waiting.
        run(SKAction.repeatForever(spawnSequence))  // Continuously spawn coins.
    }
    
    // Called every frame to update the scene.
    override func update(_ currentTime: TimeInterval) {
        // Get accelerometer data and apply force to move the bag based on tilt.
        if let data = motionManager.accelerometerData {
            let xTilt = CGFloat(data.acceleration.x)  // Get the tilt in the x-axis from accelerometer data.
            bag.physicsBody?.velocity = CGVector(dx: xTilt * 1000, dy: 0)  // Move the bag horizontally based on tilt.
            
            // Prevent the bag from moving off the edges of the screen.
            if bag.position.x < 0 {
                bag.position.x = 0
            } else if bag.position.x > size.width {
                bag.position.x = size.width
            }
        }
    }
    
    // Function to spawn coins randomly.
    func spawnCoin() {
        let coin = SKSpriteNode(imageNamed: "coin")  // Create a new coin sprite.
        coin.size = CGSize(width: 40, height: 40)  // Set the size of the coin.
        coin.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)  // Place the coin at a random x position at the top.
        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2)  // Add a circular physics body to the coin.
        coin.physicsBody?.affectedByGravity = true  // Make the coin fall due to gravity.
        coin.physicsBody?.categoryBitMask = PhysicsCategory.Coin  // Set the coin's physics category.
        coin.physicsBody?.contactTestBitMask = PhysicsCategory.Bag  // Coins should detect collisions with the bag.
        coin.physicsBody?.collisionBitMask = PhysicsCategory.None  // Coins don't collide with anything.
        coin.physicsBody?.isDynamic = true  // Make the coin dynamic.
        addChild(coin)  // Add the coin to the scene.
        
        // Remove the coin if it falls off the screen (missed by the player).
        let removeCoinAction = SKAction.sequence([SKAction.wait(forDuration: 5), SKAction.run {
            if coin.parent != nil {
                self.missedCoins += 1  // Increment the missed coin counter.
                if self.missedCoins >= self.maxMissedCoins {  // End the game if too many coins are missed.
                    self.endGame()
                }
            }
            coin.removeFromParent()  // Remove the coin from the scene.
        }])
        coin.run(removeCoinAction)  // Run the removal action on the coin.
    }
    
    // Handle collisions between the bag and coins.
    func didBegin(_ contact: SKPhysicsContact) {
        var coinBody: SKPhysicsBody
        
        // Determine which body in the contact is the coin.
        if contact.bodyA.categoryBitMask == PhysicsCategory.Coin {
            coinBody = contact.bodyA
        } else {
            coinBody = contact.bodyB
        }
        
        // Check if the player has enough steps to collect the coin.
        if stepCount >= stepCostPerCoin {
            // Remove the coin from the scene.
            coinBody.node?.removeFromParent()
            
            // Increment the score.
            score += 1
            
            // Deduct steps as currency.
            stepCount -= stepCostPerCoin
            
            // Persist the consumed steps.
            consumedSteps += stepCostPerCoin
            
            // Play a sound effect (optional).
            run(SKAction.playSoundFileNamed("coin_collect.wav", waitForCompletion: false))
        } else {
            // Show a message indicating the player doesn't have enough steps.
            let alertLabel = SKLabelNode(fontNamed: "Arial")
            alertLabel.text = "Not enough steps!"
            alertLabel.fontSize = 24
            alertLabel.fontColor = UIColor.red
            alertLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Place the message in the center of the screen.
            addChild(alertLabel)
            
            // Fade out and remove the message after 2 seconds.
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            alertLabel.run(SKAction.sequence([fadeOut, SKAction.removeFromParent()]))
        }
    }
    
    // Start receiving pedometer updates.
    func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {  // Check if step counting is available on the device.
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())  // Start counting from midnight today.
            pedometer.startUpdates(from: startOfDay) { (data, error) in
                if let error = error {
                    print("Pedometer error: \(error.localizedDescription)")  // Print any pedometer errors.
                } else if let data = data {
                    DispatchQueue.main.async {
                        // Update the step count to reflect the total steps minus consumed steps.
                        self.stepCount = data.numberOfSteps.intValue - self.consumedSteps
                        print("Current steps: \(self.stepCount)")  // Debug log of the current steps.
                    }
                }
            }
        } else {
            print("Step counting is not available.")  // Handle the case where step counting isn't available.
        }
    }
    
    // End the game when the player misses too many coins.
    func endGame() {
        let gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.text = "Game Over"  // Display "Game Over" message.
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = UIColor.red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)  // Center the message on the screen.
        addChild(gameOverLabel)
        
        // Stop all actions in the scene (i.e., stop coin spawning).
        self.removeAllActions()
        
        // Reset consumed steps to 0.
        consumedSteps = 0
        
        // Reset the score to 0.
        savedScore = 0
    }
}

//
//  Playing.swift
//  BreakoutSpriteKitTutorial
//
//  Created by Michael Briscoe on 1/16/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import SpriteKit
import GameplayKit

class Playing: GKState {
    unowned let scene: GameScene

    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        let ball = scene.childNode(withName: BallCategoryName) as! SKSpriteNode
        
        // Add an impulse to the ball, to get it in motion
        ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: randomDirection()))
    }

    override func update(deltaTime seconds: TimeInterval) {
        let ball = scene.childNode(withName: BallCategoryName) as! SKSpriteNode
        
        // The max speed the ball will be allowed to go
        let maxSpeed: CGFloat = 400.0
        
        // Find the x and y velocity of the ball
        let xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        let ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        // Find the overall velocity of the ball
        let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        // If either x or y velocity is too low, give it a quick push
        if xSpeed <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: 0.0))
        }
        if ySpeed <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: randomDirection()))
        }
        
        // If the speed is too fast, add some linear damping to slow it down
        if speed > maxSpeed {
            ball.physicsBody!.linearDamping = 0.4
        } else {
            ball.physicsBody!.linearDamping = 0.0
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }

    func randomDirection() -> CGFloat {
        let speedFactor: CGFloat = 2.0
        
        // 50/50 return a positive or negative number; this is the direction the ball will begin moving in
        if scene.randomFloat(from: 0.0, to: 100.0) >= 50 {
            return -speedFactor
        } else {
            return speedFactor
        }
    }
}

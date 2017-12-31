//
//  GameScene.swift
//  Brickslapper
/**
 * Copyright (c) 2016 Peter Rao
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */ 

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var isFingerOnPaddle = false
  
    // Create the game state machine
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)
    ])
    
    // didSet observer; prepare the game over screen if gameWon is set outside of its initial declaration
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "YouWon" : "GameOver"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                                                    SKAction.scale(to: 1.0, duration: 0.25)])
            run(gameWon ? gameWonSound : gameOverSound)
            
            gameOver.run(actionSequence)
        }
    }
    
    // Initialize sounds
    let blipSound = SKAction.playSoundFileNamed("pongblip", waitForCompletion: false)
    let blipPaddleSound = SKAction.playSoundFileNamed("paddleBlip", waitForCompletion: false)
    let bambooBreakSound = SKAction.playSoundFileNamed("BambooBreak", waitForCompletion: false)
    let gameWonSound = SKAction.playSoundFileNamed("game-won", waitForCompletion: false)
    let gameOverSound = SKAction.playSoundFileNamed("game-over", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Create an edge-based body
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)

        // Set friction to 0, to ensure that the ball bounces 'perfectly'
        borderBody.friction = 0

        // Set this physics body for this node
        self.physicsBody = borderBody

        // Remove all gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        // Designate GameScene as a delegate in the physicsWorld
        physicsWorld.contactDelegate = self

        // Create a node for the ball
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
        
        // Create a rectangle that sits at the bottom and is as wide as the frame
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        
        // Create a new SpriteKit Node
        let bottom = SKNode()
        
        // Create the body and add it to the scene
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
        
        // Create a node for the paddle
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        
        // Set the categoryBitMasks for the elemnets on screen
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        // Add a contactBitMask to ball that tells it to do something when it touches the bottom, a block, the paddle, or a wall
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | PaddleCategory | BorderCategory
        
        // Create an SKNode to serve as the targetNode for the particle system
        let trailNode = SKNode()
        trailNode.zPosition = 1
        addChild(trailNode)
        
        // Create an SKEmitterNode from BallTrail
        let trail = SKEmitterNode(fileNamed: "BallTrail")!
        
        // Set the targetNode to the trailNode. This anchors the particles so that they leave a trail, otherwise they would follow the ball
        trail.targetNode = trailNode
        
        // Attach the SKEmitterNode to the ball by adding it as a child node.
        ball.addChild(trail)
        
        // Create block constants
        let numberOfBlocks = 8
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        
        // Calculate how far the blocks need to be from the edge of the screen
        let xOffset = (frame.width - totalBlocksWidth) / 2
        
        // Place the blocks
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block.png")
            
            // Place the blocks 80% up from the bottom of the screen, one after the other
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: frame.height * 0.8)
            block.zPosition = 2
            
            // Create the block's physics body
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            
            // Set the block's name its category, and add it to the scene
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            addChild(block)
        }
        
        // Create and add a node that will display the "main menu"
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        // Enter the WaitingForTap game state
        gameState.enter(WaitingForTap.self)
    }
  
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnPaddle = true
        case is Playing:
            // Get the touch, as well as it's location
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            
            // If there is a body at the touched location and the body is the paddle, then we set isFingerOnPaddle to true
            if let body = physicsWorld.body(at: touchLocation) {
                if body.node!.name == PaddleCategoryName {
                    isFingerOnPaddle = true
                }
            }
        case is GameOver:
            // Create a new scene and present it
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Check to make sure the player is touching the paddle
        if isFingerOnPaddle {
            // Get the touch location, as well as the previous touch location
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            
            // Get the node for the paddle, which we added in the scene editor
            let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
            
            // Take the current position and add the difference between the new and the previous touch locations
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            
            // Limit the paddle so that it will not go off the screen
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            
            // Move the paddle to its new location
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        // This will call the update function from the Playing state
        gameState.update(deltaTime: currentTime)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            // Set the body with the lower bitmask value to firstBody, and the other to secondBody
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            // Play a sound when the ball hits a wall
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
                run(blipSound)
            }
            
            // Play a sound when the ball hits the paddle
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
                run(blipPaddleSound)
            }
            
            // If firstBody is a ball and secondBody is the bottom, then the player has lost
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
                // Register a loss; setting gameWon here will trigger the didSet stuff
                gameState.enter(GameOver.self)
                gameWon = false
            }
            
            // If firstBody is a ball and secondBody is a block, then run the breakBlock function
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(node: secondBody.node!)
                
                // Check if the game has been won; set gameWon (and trigger the didSet) if the game has indeed been won
                if isGameWon() {
                    gameState.enter(GameOver.self)
                    gameWon = true
                }
            }
        }
    }
    
    func breakBlock(node: SKNode) {
        // Play a sound
        run(bambooBreakSound)
        
        // Create and place particles at the position of the parameter node
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        
        // zPosition 3 so that the particles will appear above the blocks, which each have a zPosition of 2
        particles.zPosition = 3
        addChild(particles)
        
        // Wait 1 second to let the animation finish, then remove the particles from the scene
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0),
                                         SKAction.removeFromParent()]))
        
        // Remove the block from the scene as well
        node.removeFromParent()
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
}

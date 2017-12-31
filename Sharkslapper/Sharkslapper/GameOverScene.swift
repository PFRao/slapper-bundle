//
//  GameOverScene.swift
//  Sharkslapper
//
//  Created by Peter Rao on 12/14/17.
//  Copyright © 2017 Peter Rao. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    init(size: CGSize, won:Bool) {
        
        super.init(size: size)
        
        // Set background color
        backgroundColor = SKColor.lightGray
        
        // Set the message for the player
        let message = won ? "You Won!" : "You Lose :["
        
        // Set properties for the label node
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // Wait three seconds, then...
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run() {
                // ... transition into a new scene!
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
        ]))
        
    }
    
    // This is required since we overrode the initialize on this scene, but it will never be used
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

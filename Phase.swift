//
//  Phase.swift
//  Evolution
//
//  Created by Matt on 10/22/14.
//  Copyright (c) 2014 Matt. All rights reserved.
//

import Foundation

protocol Phase {
    var name: String { get }
    func start(game: Game)
}

class StartGame: Phase {
    let name = "Start Game"
    func start(game: Game) {
        game.deck.shuffle()
        for player in game.players {
            player.addSpecies(true)
            player.isDone = true
        }
        game.firstPlayerIndex = Int(arc4random_uniform(UInt32(game.players.count)))
        game.activePlayerIndex = game.firstPlayerIndex
        game.endTurn()
    }
}

class DealCards: Phase {
    let name = "Deal Cards"
    func start(game: Game) {
        for player in game.players {
            player.drawCards(3 + player.species.count)
            player.isDone = true
        }
    }
}

class SelectFood: Phase {
    let name = "Select Food"
    func start(game: Game) {
    }
    
    //TODO: Change Card to a generic to support other phases
    //    func selections() -> ((Game, Player) -> [Card]) {
    //        func selectFoodCard(game: Game, player: Player) -> [Card] {
    //            return player.cards
    //        }
    //        return selectFoodCard
    //    }
    
    //    func action() -> ((Game, Card) -> ()) {
    //        func selectFoodAction
    //    }
}

class RevealFood: Phase {
    let name = "Reveal Food"
    func start(game: Game) {
        game.wateringHole.revealFood()
        game.revealTraits()
        
        //TODO: Process Leaf Traits before setting isDone
        for player in game.players {
            for species in player.species {
                species.resetLeafUsed()
            }
        }
        
        for player in game.players {
            //            player.isDone = true
        }
    }
}

class PlayCards: Phase {
    let name = "Play Cards"
    func start(game: Game) {
        
    }
}

class EndRound: Phase {
    let name = "End Round"
    func start(game: Game) {
        for player in game.players {
            player.isDone = true
        }
        // Change the starting player for the next round
        game.firstPlayerIndex = (game.firstPlayerIndex + 1) % game.players.count
        game.round++
    }
}

//class GameOver: Phase {
//    
//}

//
//  Action.swift
//  Evolution
//
//  Created by Matt on 10/22/14.
//  Copyright (c) 2014 Matt. All rights reserved.
//

import Foundation


protocol Action {
    var name: String { get }
    //    func perform(player: Player, source: GameElement, target: GameElement, parameters: [Parameter])
    func perform(player: Player, source: GameElement, target: GameElement)
    //    var description: String { get }
}

class EndTurn: Action {
    let name = "End Turn"
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        player.isDone = true
    }
}

class AddFood: Action {
    let name = "Add Food"
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is WateringHole {
            var card = source as Card
            player.removeCard(card)
            player.game.wateringHole.addCard(card)
            player.endTurn()
        }
    }
}

class NewSpecies: Action {
    let name = "New Species"
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is SpeciesSlot {
            player.discard(source as Card)
            player.addSpecies(target is RightSpeciesSlot ? true : false)
        }
    }
    
}

class IncreasePopulation: Action {
    let name = "Increase Population"
    var ability: Trait?
    init(ability: Trait? = nil) {
        self.ability = ability
    }

    func perform(player: Player, source: GameElement, target: GameElement) {
        if target is Species {
            var species = target as Species
            if species.increasePopulation() {
                if source is Card { player.discard(source as Card) }

            }
            // Leaf abilities like Fertile can only be used once
            if let trait = ability {
                species.leafUsed[trait] = true
            }
        }
    }
}

class IncreaseSize: Action {
    let name = "Increase Size"
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is Species {
            var species = target as Species
            if species.increaseSize() { player.discard(source as Card) }
        }
    }
}

class AddTrait: Action {
    var name = "Add Trait"
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is Species {
            var species = target as Species
            var card = source as Card
            if species.addCard(card) {
                player.removeCard(card)
                source.game.hiddenTraits.append(card)
            }
        }
    }
}

class ReplaceTrait: Action {
    var name = "Replace Trait"
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is Card {
            var oldCard = target as Card
            var newCard = source as Card
            if let species = oldCard.species {
                if species.replaceCard(oldCard, newCard: newCard) { player.removeCard(newCard) }
                source.game.hiddenTraits.append(newCard)
            }
        }
    }
}

class takePlantFood: Action {
    var name = "Eat Plant Food"
    var amount = 1
    var ability: Trait?
    init(amount: Int = 1, ability: Trait? = nil) {
        self.amount = amount
        self.ability = ability
    }
    
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Species {
            var species = source as Species
            species.eatPlant(amount, from: target)

// Leaf abilities like Long Neck can only be used once
            if let trait = ability {
                species.leafUsed[trait] = true
            }
        }
    }
}

// Additional parameters for an action
//class Parameter {}
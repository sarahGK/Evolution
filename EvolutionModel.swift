//
//  EvolutionModel.swift
//  Evolution
//
//  Created by Matt on 7/13/14.
//  Copyright (c) 2014 Matt. All rights reserved.
//

import Foundation

// Playground - noun: a place where people can play


import UIKit

//TODO: Use object identifier?
var globalId = 1
func getId() -> Int {
    globalId++
    return globalId
}

let maxPopulation = 6
let maxSize = 6

// Allow [Target: [Action]] Merging
func += <K,A> (inout left: [K:[A]], right: [K:[A]]) {
    for (k, v) in right {
        if left[k] == nil {
            left[k] = v
        } else {
            left[k] = left[k]! + right[k]!
        }
    }
}

class Game {
    var players: [Player]!
    //TODO: Revert these back from var to let
    var deck: Deck!
    var discardPile: DiscardPile!
    var wateringHole: WateringHole!
    var foodBank: FoodBank!
    var phase: Phase = StartGame()
    var activePlayerIndex = 0
    var firstPlayerIndex = 0
    var round = 1
    var maxTraits = 3
    var hiddenTraits = [Card]() // recently played, hidden traits
    var viewable = [GameElement]() // GameElements viewable (with double tap) by all players
    
    init(deckList: DeckList, playerNames: [String]) {
        deck = Deck(game: self, deckList: deckList)
        wateringHole = WateringHole(game: self)
        foodBank = FoodBank(game: self)
        discardPile = DiscardPile(game: self)
        viewable.append(wateringHole)
        viewable.append(discardPile)
        
        var tempPlayers = [Player]()
        for name in playerNames {
            var player = Player(name: name, game: self)
            viewable.append(player)
            tempPlayers.append(player)
        }
        players = tempPlayers
        
        if players.count == 2 {
            maxTraits = 2
        } else {
            maxTraits = 3
        }
    }
    
    func nextPlayer() -> Player {
        activePlayerIndex = (activePlayerIndex + 1) % players.count
        return activePlayer
    }
    
    var activePlayer: Player {
    get {
        return players[activePlayerIndex]
    }
    }
    
//    var gameElements: GameElement[] {
//    get {
//    }
//    }
    
//  Continue execution until user input is required
    func endTurn() {
        var startingIndex = activePlayerIndex
        activePlayer.isDone = true
        do {
            nextPlayer()
            if (activePlayerIndex == startingIndex) {
                nextPhase()
                executePhase()
            }
        } while (activePlayer.isDone == true)
    }
    
    func nextPhase() {
        for player in players {
            player.isDone = false
        }
        activePlayerIndex = firstPlayerIndex
        switch phase {
        case is StartGame: phase = DealCards()
        case is DealCards: phase = SelectFood()
        case is SelectFood: phase = PlayCards()
        case is PlayCards: phase = RevealFood()
        case is RevealFood: phase = EndRound()
        default: phase = DealCards()
        }
    }
    
    func executePhase() {
        phase.start(self)
    }
    
    func revealTraits() {
        for card in hiddenTraits {
            card.isHidden = false
        }
        hiddenTraits.removeAll(keepCapacity: false)
    }
}

// Anything that can be selected or targeted within a game
class GameElement: Hashable {
    unowned let game: Game
    var name = ""
    
// Unique identifier for GameElement
    let hashValue = getId()
    
    func description(player: Player) -> String {
        return name
    }
  
    init (game: Game) {
        self.game = game
    }

    // Can be used to target something; should have at least one legal target
//    func canUse(player: Player) -> Bool {
//        switch player.game.phase {
//        case is SelectFood: if self is Card { return true } else { return false }
//        default: return false
//        }
//    }
    
//    func canTarget(player: Player, source: GameElement) -> Bool {
//        return false
//    }
}

func ==(lhs: GameElement, rhs: GameElement) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class Card: GameElement {
    let food: Int
    let trait: Trait
    var species: Species?
    var owner: Player?
    var isHidden = true
    override func description(player: Player) -> String {
        var desc = ""
        if isHidden == false {
            desc += "\(name)\n\(trait.text)"
        } else {
            if player == owner {
                desc += "\(name) (hidden)\n\(trait.text)"
            } else {
                desc += "(hidden trait)"
            }
        }
        if species != nil { desc += "\n\(species!.name)" }
        return desc
    }
    
    init(trait:Trait, food:Int, game: Game) {
        self.food = food
        self.trait = trait
        super.init(game: game)
        name = "\(trait.name) \(food)"
    }
    
    func discard() {
        if let s = species { trait.detach(s) }
        owner = nil
        species = nil
        isHidden = false
        game.discardPile.addCard(self)
    }
}

//TODO: Remove GameElement if player can't be selected/targeted
class Player: GameElement {
    var species = [Species]()
    var cards = [Card]()
    var foodEaten = 0
    var isDone = false
    let leftSpeciesSlot: LeftSpeciesSlot
    let rightSpeciesSlot: RightSpeciesSlot
    var leafCards = [Card]()
    
    init(name: String, game: Game) {
        leftSpeciesSlot = LeftSpeciesSlot(game: game)
        rightSpeciesSlot = RightSpeciesSlot(game: game)
        super.init(game: game)
        self.name = name
    }
    
    override func description(player: Player) -> String {
        return "\(name)\nFood Eaten: \(foodEaten)\nCards: \(cards.count)\nIs Done: \(isDone)"
    }
    
    func drawCards(num: Int) {
        for card in game.deck.removeCards(num) {
            card.owner = self
            cards.append(card)
        }
    }

    // Create a new 1/1 species on either left or right of existing species
    func addSpecies(isLeftSpeciesSlot: Bool) {
        var newSpecies = Species(player: self)
        if isLeftSpeciesSlot { species.insert(newSpecies, atIndex: 0) }
        else { species.append(newSpecies) }
        game.viewable.append(newSpecies)
    }
    
    func speciesSlot(individual: Species) -> Int? {
        for slot in 0 ..< species.count {
            if species[slot] == individual { return slot }
        }
        return nil
    }

    func viewable() -> [GameElement] {
        return game.viewable + cards
    }
    
    func usable() -> [GameElement: [GameElement: [Action]]] {
        var usable = [GameElement: [GameElement: [Action]]]()
        
        switch game.phase {
        case is SelectFood:
            for card in cards {
                usable[card] = [game.wateringHole: [AddFood()]]
            }
        case is PlayCards:
            for card in cards {
                var selections = [GameElement: [Action]]()
                selections[leftSpeciesSlot] = [NewSpecies()]
                selections[rightSpeciesSlot] = [NewSpecies()]
                for individual in species {
                    var actions = [Action]()
                    if individual.population < maxPopulation { actions.append(IncreasePopulation()) }
                    if individual.size < maxSize { actions.append(IncreaseSize()) }
                    
                    if individual.canAddCard(card) { actions.append(AddTrait()) }
                    if actions.count > 0 { selections[individual] = actions }
                    
                    for oldCard in individual.cards {
                        if individual.canReplaceCard(oldCard, newCard: card) {
                            selections[oldCard] = [ReplaceTrait()]
                        }
                    }
                }
                usable[card] = selections
            }
        case is RevealFood:
            for individual in species {
                var selections = [GameElement: [Action]]()
                for (trait, hasUsed) in individual.leafUsed {
                    if hasUsed { continue }
                    if let leafFunc = individual.leafFunc[trait] {
                        //TODO: Merge selections
                        selections += leafFunc(individual)
                    }
                }
                if (selections.count > 0) { usable[individual] = selections }
            }
        default: break
        }
        
        if usable.count == 0 { isDone = true }
        
        return usable
    }
    
    func removeCard(card: Card) {
        if let index = find(cards,card) {
            cards.removeAtIndex(index)
        }
    }
    
    func discard(card: Card) {
        removeCard(card)
        card.discard()
    }
    
    func endTurn() {
        game.endTurn()
    }

// List of GameElements the player can select
//    func canSelect() -> [GameElement] {
//        var selectable: [GameElement] = game.players
////        selectable += cards
//        for card in cards {
//            selectable.append(card)
//        }
//        for individual in species {
//            selectable.append(individual)
//        }
//        return selectable
//    }
//    
//// Can be used to target something; should have at least one legal target
//     func canUse() -> [GameElement] {
//        if isDone { return [] }
//        switch self.game.phase {
//            case is SelectFood: return cards
//            default: return []
//        }
//    }
//
//// List of GameElements the player's selection can target
//    func canTarget(source: GameElement) -> [GameElement] {
//        var choices = [GameElement]()
//        return choices
//    }
    
//    func hasCard(card: Card) -> Bool {    }
}

class Deck: GameElement {
    var cards = [Card]()
    var deckList: DeckList
    
    func shuffle() {
        self.cards += game.discardPile.empty()
        
        var newcards = [Card]()
        while (cards.count > 0) {
            //var index = Int(rand()) % cards.count
            var index = Int(arc4random_uniform(UInt32(cards.count)))
            newcards.append(cards[index])
            cards.removeAtIndex(index)
        }
        cards = newcards
    }
    
    init(game: Game, deckList: DeckList) {
        self.deckList = deckList
        super.init(game: game)
        self.cards = deckList.getDeck(game)
    }
    
     override func description(player: Player) -> String {
        return "\(cards.count) Cards"
    }
    
    func removeCards(number: Int) -> [Card] {
        if (self.cards.count < number) {
            shuffle()
        }
        
        if (self.cards.count < number) {
            var draw = self.cards
            self.cards = []
            return draw
        }
        
        var draw = Array(self.cards[0..<number])
        self.cards[0..<number] = []
        
        return draw
    }
}

class DiscardPile: GameElement {
    var cards = [Card]()
    
    override init(game: Game) {
        super.init(game: game)
        name = "Discard Pile"
    }

    override func description(player: Player) -> String {
        return "\(cards.count) Cards"
    }

    func addCard(card:Card) {
        cards.append(card)
    }
    
    func empty() -> [Card] {
        var cards = self.cards
        self.cards = []
        return cards
    }
}

class Species: GameElement {
    unowned let owner: Player
    var population = 1
    var size = 1
    var foodEaten = 0
    var fatTissue: Int?
    var cards = [Card]()
    var traits: [Trait] {
        get { return map(cards) { $0.trait } }
    }
    // whether a leaf trait has been used during reveal Food or not
    var leafUsed = [Trait: Bool]()
    // function to determine selections for a leaf trait
    var leafFunc: [Trait: (Species) -> [GameElement: [Action]]] = [:]

    var namePrefix = "mini"
    var nameSuffix = "lack"
    override var name: String {
        get { return "\(population)/\(size) \(namePrefix)\(nameSuffix) \(hashValue)" }
        set {}
    }
    
    init(player: Player) {
        owner = player
        super.init(game: player.game)
    }
    
    func canAddCard(card: Card) -> Bool {
        if cards.count >= game.maxTraits { return false }
        if hasTrait(card.trait) { return false }
        return true
    }
    
//TODO: Handle plant vs. meat
    func canEat() -> Bool {
        if foodEaten < population { return true }
        if let fat = fatTissue {
            if fat < size { return true }
        }
        return false
    }
    
// Returns amount of food species can Eat
    func canEatAmount() -> Int {
        if foodEaten < population { return population - foodEaten }
        if let fat = fatTissue {
            if fat < size { return size - fat }
        }
        return 0
    }

    func canReplaceCard(oldCard: Card, newCard: Card) -> Bool {
        if !hasCard(oldCard) { return false }
        if hasTrait(newCard.trait) { return false }
        return true
    }
    
    func addCard(card: Card) -> Bool {
        if !canAddCard(card) { return false }
        card.species = self
        cards.append(card)
        card.trait.attach(self)
        return true
    }

    func replaceCard(oldCard: Card, newCard: Card) -> Bool {
        if !canReplaceCard(oldCard, newCard: newCard) { return false }
        cards[find(traits, oldCard.trait)!] = newCard
        newCard.species = self
        oldCard.discard()
        return true
    }

    func hasCard(card: Card) -> Bool {
        if find(cards, card) == nil { return false }
        return true
    }

    func hasTrait(trait: Trait) -> Bool {
        if find(traits, trait) == nil { return false }
        return true
    }
    
//    func findCard(trait: Trait) -> Card {
//        if find(traits, trait) == nil { return false }
//        return true
//    }
    
    func increaseSize() -> Bool {
        if size >= maxSize { return false }
        size++
        if size > 3 && namePrefix == "mini" { namePrefix = "mega" }
        return true
    }
    
    func increasePopulation() -> Bool {
        if population >= maxPopulation { return false }
        population++
        if population > 3 && nameSuffix == "lack" { nameSuffix = "peeps" }
        return true
    }
    
    func eatPlant(var amount: Int, var from: GameElement? = nil) {
        //TODO: Carnivores don't eat plant food
        if amount > canEatAmount() { amount = canEatAmount() }
        if from == nil { from = game.wateringHole }
        if from == game.wateringHole && amount > game.wateringHole.food { amount = game.wateringHole.food }
        if amount <= 0 { return }

        //TODO: Check for cooperation
        if from == game.wateringHole {
            game.wateringHole.removeFood(&amount)
        } else if from == game.foodBank {
            game.foodBank.removeFood(&amount)
        }
        
        if foodEaten < population {
            foodEaten += amount
        } else if fatTissue < size {
            fatTissue! += amount
        }
    }
    
//    func eatMeat(amount: Int) {
//    }
    
    // Notification revealFood has begun
    // Bool - was this used?
    // Method to determine valid source/target/action
    // Method to use Leaf
    // Method to remove
    func addLeaf(trait: Trait, leafFunc: Species -> [GameElement: [Action]]) {
        leafUsed[trait] = false
        self.leafFunc[trait] = leafFunc
    }
    
    func removeLeaf(trait: Trait) {
        leafUsed[trait] = nil
        leafFunc[trait] = nil
    }

    func resetLeafUsed() {
        for trait in leafUsed.keys {
            leafUsed[trait] = false
        }
    }
    
//    func leafSelections() -> [GameElement: [GameElement: [Action]]] {
//        var selections = [GameElement: [GameElement: [Action]]]()
//        for trait in leafUsed.keys {
//            if leafUsed[trait] != true { continue }
//            if let leafFunc = leafFunc[trait] {
//                //TODO: Merge selections
//                selections = leafFunc(self)
//            }
//        }
//        return selections
//    }

    override func description(player: Player) -> String {
        var desc = "\(namePrefix)\(nameSuffix)\nPopulation: \(population)\nBody Size: \(size)\nFood Eaten: \(foodEaten)"
        //TODO: Only show if not hidden
        if let fat = fatTissue { desc += " (\(fat) fat)" }
        desc += "\n\(owner.name)"
        if let slot = player.speciesSlot(self) { desc += " slot \(slot)" }
        
        for card in cards {
            if card.isHidden {
                if player == owner {
                    desc += "\n\(card.trait.name) (hidden)"
                } else {
                    desc += "\n(hidden trait)"
                }
            } else {
                desc += "\n\(card.trait.name)"
            }
        }
        return desc
    }
}

class WateringHole: GameElement {
    var food = 0
    var cards = [Card]()

    override init(game: Game) {
        super.init(game: game)
        name = "Watering Hole"
    }
    
    override func description(player: Player) -> String {
        return "Watering Hole\nCards: \(cards.count)\nFood: \(food)"
    }
    
    func addCard(card:Card) {
        cards.append(card)
    }
    
    func revealFood() {
        for card in cards {
            food += card.food;
            card.discard()
        }
        if (food < 0) { food = 0 }
        cards = []
    }
    
    // Try to take amount food from the watering
    // amount will be changed to actual amount taken
    func removeFood(inout amount: Int) {
        if amount <= food {
            food -= amount
        } else if food <= 0 {
            amount = 0
        } else {
            amount = food
            food = 0
        }
    }
}

class FoodBank: GameElement {
    override init(game: Game) {
        super.init(game: game)
        name = "Food Bank"
    }

    // Try to take amount food from the watering
    // amount will be changed to actual amount taken
    func removeFood(inout amount: Int) { }
}

class SpeciesSlot: GameElement { }

class LeftSpeciesSlot: SpeciesSlot {
    override init(game: Game) {
        super.init(game:game)
        name = "Left Species Slot"
    }
}

class RightSpeciesSlot: SpeciesSlot {
    override init(game: Game) {
        super.init(game:game)
        name = "Right Species Slot"
    }
}

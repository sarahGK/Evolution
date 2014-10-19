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

class Game {
    var players: [Player]!
    let deck: Deck!
    let discardPile: DiscardPile!
    let wateringHole: WateringHole!
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
        owner = nil
        species = nil
        isHidden = false
        game.discardPile.addCard(self)
    }
}

protocol Phase {
    func start(game: Game)
}

class StartGame: Phase {
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
    func start(game: Game) {
        for player in game.players {
            player.drawCards(3 + player.species.count)
            player.isDone = true
        }
    }
}

class SelectFood: Phase {
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
    func start(game: Game) {
        game.wateringHole.revealFood()
        game.revealTraits()

//TODO: Process Leaf Traits before setting isDone
        for player in game.players {
            player.isDone = true
        }
    }
}

class PlayCards: Phase {
    func start(game: Game) {
        
    }
}

class EndRound: Phase {
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

//TODO: Remove GameElement if player can't be selected/targeted
class Player: GameElement {
    var species = [Species]()
    var cards = [Card]()
    var foodEaten = 0
    var isDone = false
    let leftSpeciesSlot: LeftSpeciesSlot
    let rightSpeciesSlot: RightSpeciesSlot
    
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
                for trait in individual.traits {
                    
                }
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
    var cards = [Card]()
    var traits: [Trait] {
        get { return map(cards) { $0.trait } }
    }
//    var dtraits = [Trait: Bool]()
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

    func canReplaceCard(oldCard: Card, newCard: Card) -> Bool {
        if !hasCard(oldCard) { return false }
        if hasTrait(newCard.trait) { return false }
        return true
    }
    
    func addCard(card: Card) -> Bool {
        if !canAddCard(card) { return false }
        card.species = self
        cards.append(card)
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

   

    override func description(player: Player) -> String {
        var desc = "\(namePrefix)\(nameSuffix)\nPopulation: \(population)\nBody Size: \(size)\nFood Eaten: \(foodEaten)"
        
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
    
//    override var name: String {
//    get {
//        return "\(population)/\(size) \(name)"
//    }
//    }

//    init() {
//        super.init()
//        name = "\(population)/\(size) \(self.name)"
//    }
    //func canAttack() -> Species[] {}
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
    func perform(player: Player, source: GameElement, target: GameElement) {
        if source is Card && target is Species {
            var species = target as Species
            if species.increasePopulation() { player.discard(source as Card) }
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
            }
        }
    }
}

// Additional parameters for an action
//class Parameter {}
//
//  Traits.swift
//  Evolution
//
//  Created by Matt on 7/27/14.
//  Copyright (c) 2014 Matt. All rights reserved.
//

import Foundation

class Trait: Hashable {
    let hashValue: Int
    let name: String
    let text: String
    let attachFunc: (Species -> ())?
    let detachFunc: (Species -> ())?
//    var leaf: (

//    let hasLeaf: Bool

//    unowned let game: Game
//    
//    init(game: Game) {
//        self.game = game
//        super.init()
//    }
    
    init(id:Int, name:String, text:String, attach: (Species -> ())? = nil, detach: (Species -> ())? = nil) {
        self.hashValue = id
        self.name = name
        self.text = text
        attachFunc = attach
        detachFunc = detach
    }
    
    func attach(species: Species) {
        if let f = attachFunc { f(species) }
    }
    
    func detach(species: Species) {
        if let f = detachFunc { f(species) }
    }
}

func ==(lhs: Trait, rhs: Trait) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

let carnivoreTrait = Trait(
    id:   1,
    name: "Carnivore",
    text: "May attack and eat other species. Can never eat Plant Food."
)

let ambushTrait = Trait(
    id:   2,
    name: "Ambush",
    text: "Negates Warning Call when attacking."
)

let burrowingTrait = Trait(
    id:   3,
    name: "Burrowing",
    text: "This species cannot be attacked if it has food equal to its Population."
)

let climbingTrait = Trait(
    id:   4,
    name: "Climbing",
    text: "A Carnivore must have Climbing to attack this species."
)

let cooperationTrait = Trait(
    id:   5,
    name: "Cooperation",
    text: "When this species takes food, your species to the right takes 1 food from the same source."
)

let defensiveherdingTrait = Trait(
    id:   6,
    name: "Defensive Herding",
    text: "A Carnivore must be larger in Population and Body Size to attack this species."
)

let fattissueTrait = Trait(
    id:   7,
    name: "Fat Tissue",
    text: "This species can store food on this card up to its Body Size.",
    attach: fattissueAttach,
    detach: fattissueDetach
)

func fattissueSelectFunc(species: Species) -> [GameElement: [Action]] {
    if species.fatTissue > 0 && species.foodEaten < species.population {
        return [species: [TransferFatTissue()]]
    }
    return [:]
}

func fattissueAttach(species: Species) {
    species.fatTissue = 0
    species.addLeaf(fattissueTrait, fattissueSelectFunc)
}

func fattissueDetach(species: Species) {
    species.fatTissue = nil
    species.removeLeaf(fattissueTrait)
}

let fertileTrait = Trait(
    id:   8,
    name: "Fertile",
    text: "When the Food Cards are revealed, increase this species' Population by 1.",
    attach: fertileAttach,
    detach: fertileDetach
)

func fertileSelectFunc(species: Species) -> [GameElement: [Action]] {
    if species.population < maxPopulation {
        return [species: [IncreasePopulation(ability: fertileTrait)]]
    }
    return [:]
}

func fertileAttach(species: Species) {
    species.addLeaf(fertileTrait, fertileSelectFunc)
}

func fertileDetach(species: Species) {
    species.removeLeaf(fertileTrait)
}


let foragingTrait = Trait(
    id:   9,
    name: "Foraging",
    text: "Take 2 Plant Food from the Watering Hole instead of 1."
)

let hardshellTrait = Trait(
    id:   10,
    name: "Hard Shell",
    text: "+3 Body Size when determining if this species can be attacked."
)

let hornsTrait = Trait(
    id:   11,
    name: "Horns",
    text: "A Carnivore must decrease its Population by 1 when attacking this species."
)

let intelligenceTrait = Trait(
    id:   12,
    name: "Intelligence",
    text: "Discard a card from your hand. Take 2 Plant Food from the Food Bank. -OR- Negate any trait for 1 attack."
)

let longneckTrait = Trait(
    id:   13,
    name: "Long Neck",
    text: "When the Food Cards are revealed, take 1 Plant Food from the Food Bank.",
    attach: longneckAttach,
    detach: longneckDetach
)

func longneckSelectFunc(species: Species) -> [GameElement: [Action]] {
    if species.canEat() {
        return [species.game.foodBank: [takePlantFood(ability: longneckTrait)]]
    }
    return [:]
}

func longneckAttach(species: Species) {
    species.addLeaf(longneckTrait, longneckSelectFunc)
}

func longneckDetach(species: Species) {
    species.removeLeaf(longneckTrait)
}

let packhuntingTrait = Trait(
    id:   14,
    name: "Pack Hunting",
    text: "+3 Body Size when determining if this species can attack another species."
)

let scavengerTrait = Trait(
    id:   15,
    name: "Scavenger",
    text: "Take 1 Meat Food from the Food Bank when any species is attacked by a Carnivore."
)

let symbiosisTrait = Trait(
    id:   16,
    name: "Symbiosis",
    text: "This species cannot be attacked if your species to the right has a larger Body Size then this species."
)

let warningcallTrait = Trait(
    id:   17,
    name: "Warning Call",
    text: "A Carnivore must have Ambush to attack your species that are adjacent to this species."
)


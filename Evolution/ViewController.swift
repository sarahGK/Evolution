//
//  ViewController.swift
//  Evolution
//
//  Created by Matt on 7/13/14.
//  Copyright (c) 2014 Matt. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate {
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var targetTextView: UITextView!
    @IBOutlet weak var actionTextView: UITextView!
    @IBOutlet var playerLabel: UILabel!
    @IBOutlet var sourcePicker: UIPickerView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var endTurnButton: UIButton!
    
    var game = Game(deckList: standardDeck, playerNames: ["Sarah", "Matt"])
//TODO: Handle non-active players
    var player: Player {
        get {
            return game.activePlayer
        }
    }

    var sources = [GameElement]()
    var targets = [[GameElement]]()
    var actions = [[[Action]]]()
    
    @IBAction func actionTapped(sender: AnyObject) {
        if (action != nil && target != nil) {
            action!.perform(player, source: source, target: target!)
        }
        updateUI()
    }
    
//TODO: Disable End Turn when it's not allowed
    @IBAction func endTurnTapped(sender: AnyObject) {
        game.endTurn()
        updateUI()
    }
    
    @IBAction func nextPlayerButton(sender: AnyObject) {
        game.nextPlayer()
        sourcePicker.selectRow(0, inComponent: 0, animated: true)
        updateUI()
    }
    
// Sets sources, targets, and actions index to object mapping for use by picker
    func setPicker() {
        sources = [GameElement]()
        targets = [[GameElement]]()
        actions = [[[Action]]]()
        var (i,j) = (0,0)

        player.updateSelectable()
        for source in player.selectable.keys {
            j = 0
            sources.append(source)
            targets.append([])
            actions.append([[]])
            for target in player.selectable[source]!.keys {
                targets[i].append(target)
                actions[i].append([])
                if let actionList = player.selectable[source]![target] {
                    actions[i][j] = actionList
                }
                j++
            }
            i++
        }
    }
    
    var sourceIndex: Int  {
    get {
        return sourcePicker.selectedRowInComponent(0)
    }
    }
    
    var sourceCount: Int {
    get {
        return sources.count
    }
    }
    
    var source: GameElement {
    get {
//        return player.selectableElements[sourceIndex]
        return sources[sourceIndex]
    }
    }
    
    var targetIndex: Int?  {
    get {
        if targetCount > 0 { return sourcePicker.selectedRowInComponent(1) }
        return nil
    }
    }
    
    var targetCount: Int {
    get {
        return targets[sourceIndex].count
    }
    }
    
    var target: GameElement? {
    get {
        if targetIndex != nil { return targets[sourceIndex][targetIndex!] }
        return nil
    }
    }
    
    var actionIndex: Int?  {
    get {
        if actionCount > 0 { return sourcePicker.selectedRowInComponent(2) }
        return nil
    }
    }
    
    var actionCount: Int {
    get {
        if targetIndex != nil { return actions[sourceIndex][targetIndex!].count }
        return 0
//        return actions[sourceIndex][targetIndex!].count ?? 0
    }
    }

    var action: Action? {
    get {
        if targetIndex != nil && actionIndex != nil { return actions[sourceIndex][targetIndex!][actionIndex!] }
        return nil
//        return actions[sourceIndex][targetIndex!][actionIndex!] ?? nil
    }
    }
    
    func updateUI() {
        setPicker()
        sourcePicker.reloadAllComponents()
        
        if (!player.isDone && action != nil) {
            actionButton.enabled = true
            actionButton.setTitle(action!.name, forState: .Normal)
        } else {
            actionButton.enabled = false
        }

        playerLabel.text = player.name
        updateDescription()
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int
    {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView!, numberOfRowsInComponent component: Int) -> Int
    {
        if component == 0 { return sourceCount }
        if component == 1 { return targetCount }
        return actionCount
    }
    
    func pickerView(pickerView: UIPickerView!, titleForRow row: Int, forComponent component: Int) -> String
    {
        if component == 0 { return sources[row].name }
        if component == 1 && row < targetCount { return targets[sourceIndex][row].name }
        if component == 2 && row < actionCount { return actions[sourceIndex][targetIndex!][row].name }
        return ""
    }

    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int) {
//        if component == 0 {
//            sourcePicker.reloadAllComponents()
//            updateDescription()
//        }
        updateUI()
    }
    
    func updateDescription() {
        sourceTextView.text = sources[sourceIndex].description
        if (targetIndex != nil) {
            targetTextView.text = targets[sourceIndex][targetIndex!].description
            if (actionIndex != nil) {
                actionTextView.text = actions[sourceIndex][targetIndex!][actionIndex!].name
            } else {
                actionTextView.text = ""
            }
        } else {
            targetTextView.text = ""
            actionTextView.text = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        game.phase.start(game)
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


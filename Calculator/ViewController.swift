//
//  ViewController.swift
//  Calculator
//
//  Created by Christopher Miller on 11/2/15.
//  Copyright © 2015 Christopher Miller. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    @IBOutlet weak var expression: UILabel!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var display: UILabel!

    var brain = CalculatorBrain()
    var memoryMode: String?

    //
    // User Input
    //
    @IBAction func pressedDigit(sender: UIButton)
    {
        let digitString = sender.currentTitle!
        
        if memoryMode != nil
        {
            switch memoryMode!
            {
            case "M":
                brain.memoryAdd(Int(digitString)!)
                break;
            case "R":
                if let tree = brain.memoryRecall(Int(digitString)!)
                {
                    brain.setOperand(tree)
                    setDisplayText()
                }
                break;
            case "C":
                brain.memoryClear(Int(digitString)!)
                break;
            default:
                break;
            }
            memoryMode = nil
        }
        else
        {
            // send a preview to the brain
            brain.inputBufferAppend(digitString)

            // the brain has its own internal buffer string, use it.
            setDisplayText()
        }
    }

    @IBAction func pressedDot(sender: UIButton)
    {
        if memoryMode == nil
        {
            brain.inputBufferDot()
            setDisplayText()
        }
    }
    
    
    @IBAction func pressedNegate(sender: UIButton)
    {
        if memoryMode == nil
        {
            brain.inputBufferNegate()
            setDisplayText()
        }
    }
    
    
    @IBAction func pressedOperator(sender: UIButton)
    {
        if memoryMode == nil
        {
            // setOperand(display.text)

            let symbol = sender.currentTitle!
            brain.pressedOperator(symbol)
            setDisplayText()
        }
    }

    @IBAction func pressedEnter()
    {
        if memoryMode == nil
        {
            brain.pressedEnter()
            setDisplayText()
        }
    }

    @IBAction func pressedMemory(sender: UIButton)
    {
        if memoryMode == nil
        {
            let symbol = sender.currentTitle!
            switch symbol
            {
            case "M+":
                memoryMode = "M"
                break
            case "MR":
                memoryMode = "R"
                break
            case "MC":
                memoryMode = "C"
                break
            default:
                break
            }
        }
    }
    
    @IBAction func pressedDelete(sender: UIButton)
    {
        // hard reset memoryMode
        memoryMode = nil

        // for now let's just clear everything
        brain.pressedDelete()
        setDisplayText()
    }

    // ask the brain what's up
    func setDisplayText()
    {
        expression.text = brain.getExpression()
        result.text = brain.getResult()
        display.text = brain.getInputBuffer()
    }

    func setError(error: String)
    {
        // set error state
        result.text = error
    }
}

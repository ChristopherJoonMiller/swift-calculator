//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Christopher Miller on 11/5/15.
//  Copyright © 2015 Christopher Miller. All rights reserved.
//

import Foundation

enum Op: CustomStringConvertible
{
    case Operand(Double?)
    case UnaryOperator(String, Double -> Double?)
    case BinaryOperator(String, (Double, Double) -> Double?)
    
    var description: String
    {
        get
        {
            switch self
            {
            case .Operand(let operand):
                if let operand = operand
                {
                    return "\(operand)"
                }
                return "_"
            case .UnaryOperator(let oper, _):
                return oper
            case .BinaryOperator(let oper, _):
                return oper
            }
        }
    }
}

class ExpressionTree: CustomStringConvertible
{
    var description: String
    {
        get
        {
            if self.op != nil
            {
                switch self.op!
                {
                case .Operand(let operand):
                    if let operand = operand
                    {
                        if operand == floor(operand)
                        {
                            return "\(Int(operand))"
                        }
                        else
                        {
                            return "\(operand)"
                        }
                    }
                case .UnaryOperator(let oper, _):
                    if self.left == nil
                    {
                        return oper
                    }
                    return oper + "\(self.left!)"
                case .BinaryOperator(let oper, _):
                    if let op1 = self.left?.description
                    {
                        if let op2 = self.right?.description
                        {
                            return "(" + op1 + oper + op2 + ")"
                        }
                        return "(" + op1 + oper + "?)"
                    }
                    return "(?" + oper + "?)"
                }
            }
            return "_"
        }
    }

    var op: Op?
    var left: ExpressionTree?
    var right: ExpressionTree?

    init(op: Op?)
    {
        if op != nil
        {
            self.op = op
        }
    }
    
    // evaluate this tree and return up its value as a double if possible
    func evaluate() -> Double?
    {
        if self.op != nil
        {
            switch self.op!
            {
            case .Operand(let operand):
                return operand
            case .UnaryOperator(_, let operation):
                if let operand1 = left!.evaluate()
                {
                    return operation(operand1)
                }
            case .BinaryOperator(_, let operation):
                if let operand1 = left?.evaluate()
                {
                    if let operand2 = right?.evaluate()
                    {
                        return operation(operand2, operand1)
                    }
                }
            }
        }
        return nil
    }
    
    // set the current operand value to something else.
    func modifyOperand(newValue: Double) -> Double?
    {
        if let opType = self.op
        {
            switch opType
            {
            case .Operand:
                self.op = Op.Operand(newValue)
            default:
                break
            }
        }
        else
        {
            self.op = Op.Operand(newValue)
        }

        return self.evaluate()
    }
    
    // recursively find the "last editable operand" leaf in the tree with a right first search
    // if there are for some reason no operands yet to edit return nil
    func findEditableLeaf() -> ExpressionTree?
    {
        // if I'm an operand return myself
        if let opType = self.op
        {
            switch opType
            {
            case .Operand:
                return self
            default:
                break
            }
        }
        else
        {
            return self
        }

        if self.right != nil
        {
            return self.right?.findEditableLeaf()
        }

        else if self.left != nil
        {
            return self.left?.findEditableLeaf()
            
        }
        
        return nil
    }

    // add a double as an operand to the current node
    func addOperand(operand: Double) -> Double?
    {
        let operandTree = ExpressionTree(op: Op.Operand(operand))
        return addOperand(operandTree)
    }

    // allow for adding an entire tree as an operand
    func addOperand(operand: ExpressionTree) -> Double?
    {
        
        // this is a new tree... set it to be an operand!
        if self.op == nil
        {
            self.op = operand.op
            self.left = operand.left
            self.right = operand.right
            return self.evaluate()
        }
        else if self.left == nil
        {
            self.left = operand
            return self.left!.evaluate()
        }
        else if self.right == nil
        {
            self.right = operand
            return self.right!.evaluate()
        }
        else // too many operands? implode and reset
        {
            self.op = operand.op
            self.left = operand.left
            self.right = operand.right
            return self.evaluate()
        }
    }

    func addOperator(oper: Op?) -> String?
    {
        if self.op == nil && oper != nil
        {
            self.op = oper
            return "\(self.op!)"
        }
        return nil
    }
    
    func complete() -> Bool
    {
        if self.op != nil
        {
            switch self.op!
            {
            case .Operand:
                return true
            case .UnaryOperator:
                return self.left != nil
            case .BinaryOperator:
                return self.left != nil && self.right != nil
            }
        }
        return false
    }
}

class CalculatorBrain
{
    var opTree = ExpressionTree(op: nil) // create an expression tree original root node
    
    // keep a memory of up to 10 trees
    var memory = [ExpressionTree?](count: 10, repeatedValue: nil)
    
    var knownOperators = [String:Op]()
    
    var inputBuffer: String?
    {
        didSet
        {
            // try to get a double value out of me and append to the current editable node
            if inputBuffer != nil
            {
                if let operandDouble = Double(inputBuffer!)
                {
                    if let node = opTree.findEditableLeaf()
                    {
                        node.modifyOperand(operandDouble)
                    }
                }
            }
        }
    }

    init()
    {
//        self.knownOperators["-"] = Op.UnaryOperator("-") { -$0 }
        self.knownOperators["+"] = Op.BinaryOperator("+", +)
        self.knownOperators["−"] = Op.BinaryOperator("−") { $1 - $0 }
        self.knownOperators["×"] = Op.BinaryOperator("×", *)
        self.knownOperators["÷"] = Op.BinaryOperator("÷") { return $0 != 0 ? $1 / $0 : nil } // prevent a divide by zero
        self.inputBuffer = nil
    }

    // allow an expression tree to be set as an operand
    func setOperand(operand: ExpressionTree) -> Double?
    {
        return opTree.addOperand(operand)
    }

    func pressedOperator(symbol: String) -> String?
    {
        inputBufferClear()

        // create a Unary Operator
        if let oper = knownOperators[symbol]
        {
            // determine if we're creating a new tree
            if opTree.op != nil
            {
                // if the tree is already evaluatable we can add an operator
                if let _ = opTree.evaluate()
                {
                    let newRoot = ExpressionTree(op: oper)
                    newRoot.addOperand(opTree)
                    opTree = newRoot
                    
                }
            }
            else
            {
                return opTree.addOperator(oper)
            }
        }
        return nil
    }
    
    func memoryAdd(slot: Int)
    {
        if opTree.complete()
        {
            memory[slot] = opTree
            print("M\(slot): Added \(opTree)")
            return
        }
        print("M\(slot): Added none")
    }
    
    func memoryRecall(slot: Int) -> ExpressionTree?
    {
        if let tree = memory[slot]
        {
            print("M\(slot): Found \(tree)")
            return tree
        }
        print("M\(slot): Found none")
        return nil
    }
    
    func memoryClear(slot: Int)
    {
        if let _ = memory[slot]
        {
            memory[slot] = nil
        }
        print("M\(slot): Cleared")
    }

    func pressedEnter()
    {
        inputBufferClear()
    }
    
    func pressedDelete()
    {
        // set opTree to a new tree altogether
        // this preserves old trees in memory
        opTree = ExpressionTree(op: nil)
        inputBufferClear()
    }

    //
    // DISPLAY funcs
    //
    func getExpression() -> String
    {
        let exp = opTree.description
        print("Expression: " + exp)
        return exp
    }
    
    func getResult() -> String
    {
        if let result = opTree.evaluate()
        {
            if result == floor(result)
            {
                return "\(Int(result))"
            }
            else
            {
                return "\(result)"
            }
        }
        return "_"
    }
    
    //
    // INPUT BUFFER funcs
    //
    func getInputBuffer() -> String
    {
        return inputBuffer == nil ? "_" : inputBuffer!
    }
    
    func inputBufferPrepend(c: String) -> String?
    {
        if inputBuffer == nil
        {
            inputBuffer = c
        }
        else
        {
            inputBuffer = c + inputBuffer!
        }
        return inputBuffer
    }
    func inputBufferAppend(c: String) -> String?
    {
        if inputBuffer == nil
        {
            // we need to create a new operand now!
            if let doubleValue = Double(c)
            {
                opTree.addOperand(doubleValue)
            }
            else
            {
                opTree.addOperand(ExpressionTree(op: Op.Operand(nil))) // just in case
            }
            inputBuffer = c
        }
        else
        {
            inputBuffer = inputBuffer! + c
        }
        return inputBuffer
    }
    func inputBufferRemove(c: String) -> String?
    {
        if inputBuffer != nil
        {
            inputBuffer = inputBuffer!.stringByReplacingOccurrencesOfString(c, withString: "")
        }
        return inputBuffer
    }
    func inputBufferDot() -> String?
    {
        if inputBuffer != nil && inputBuffer!.containsString(".")
        {
            return nil
        }
        inputBufferAppend(".")
        return inputBuffer
    }
    func inputBufferNegate() -> String?
    {
        if inputBuffer != nil && inputBuffer!.containsString("-")
        {
            inputBufferRemove("-")
        }
        else
        {
            inputBufferPrepend("-")
        }
        return inputBuffer
    }
    func inputBufferClear() -> String?
    {
        inputBuffer = nil
        return inputBuffer
    }
}
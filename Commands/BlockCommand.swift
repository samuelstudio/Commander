//
//  BlockCommand.swift
//  Commander
//
//  Created by Matthias Tretter on 02/04/2017.
//
//

import Foundation


/// A command that can execute a block
public final class BlockCommand {

    public typealias Block = (Void) -> Void

    fileprivate let executionBlock: Block
    fileprivate let inverseExecutionBlock: Block

    // (from Command) - Swift doesn't allow to move Properties to extensions (yet)
    public let isAsynchronous: Bool
    public let isMutating: Bool
    public var state: State = .ready

    // MARK: - Lifecycle

    public init(block: @escaping Block, inverseBlock: @escaping Block, isAsynchronous: Bool = false, isMutating: Bool = true) {
        self.executionBlock = block
        self.inverseExecutionBlock = inverseBlock
        self.isAsynchronous = isAsynchronous
        self.isMutating = isMutating
    }
}

// MARK: - Command

extension BlockCommand: Command {

    public func invoke() {
        self.state = .executing
        self.executionBlock()
        // finish() must be called explicitly for asynchronous tasks
        if self.isAsynchronous == false {
            self.finish()
        }
    }

    public func inversed() -> Command {
        return BlockCommand(block: self.inverseExecutionBlock,
                            inverseBlock: self.executionBlock,
                            isAsynchronous: self.isAsynchronous,
                            isMutating: self.isMutating)
    }
}
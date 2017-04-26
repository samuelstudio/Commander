/// Simple playground to test an API that we can use for operation-based actions
/// to modify objects.
///
/// TODO:
/// - [ ] Asynchronous Commands (Futures?)
/// - [ ] Cancelable Commands (Result<T>?)

import Foundation


func main() {
    testBasics()
    testLayout()
    testValidation()
}

private func testBasics() {
    let commander = CommandDispatcher(validator: AppValidator(appMode: AppMode(mode: .full)))

    let shape = Shape()
    let move = MoveCommand(moveable: shape, offset: CGVector(dx: 10.0, dy: 5.0))

    // test preconditions
    expect(shape.center == .zero)
    expect(shape.title == "")

    // test move
    commander.invoke(command: move)
    expect(shape.center == CGPoint(x: 10.0, y: 5.0))
    expect(commander.commands.count == 1)
    expect(commander.undoneCommands.count == 0)

    commander.invoke(command: move)
    expect(shape.center == CGPoint(x: 20.0, y: 10.0))
    expect(commander.commands.count == 2)
    expect(commander.undoneCommands.count == 0)

    // test undo
    try! commander.undo()
    expect(shape.center == CGPoint(x: 10.0, y: 5.0))
    expect(commander.commands.count == 1)
    expect(commander.undoneCommands.count == 1)

    // test redo
    try! commander.redo()
    expect(shape.center == CGPoint(x: 20.0, y: 10.0))
    expect(commander.commands.count == 2)
    expect(commander.undoneCommands.count == 0)

    // test grouping
    let groupedIdentityMove = GroupCommand(commands: [move, move.inversed()])
    commander.invoke(command: groupedIdentityMove)
    expect(shape.center == CGPoint(x: 20.0, y: 10.0))
    expect(commander.commands.count == 3)
    expect(commander.undoneCommands.count == 0)

    let groupedDoubleMove = GroupCommand(commands: [move, move])
    commander.invoke(command: groupedDoubleMove.inversed())
    expect(shape.center == .zero)
    expect(commander.commands.count == 4)
    expect(commander.undoneCommands.count == 0)

    // test undo loop
    while !commander.commands.isEmpty { try! commander.undo() }
    expect(shape.center == .zero)
    expect(commander.commands.count == 0)
    expect(commander.undoneCommands.count == 4)

    // test undo/redo counts
    try! commander.redo(numberOfCommands: 4)
    expect(shape.center == .zero)
    expect(commander.commands.count == 4)
    expect(commander.undoneCommands.count == 0)

    try! commander.undo(numberOfCommands: 4)
    expect(shape.center == .zero)
    expect(commander.commands.count == 0)
    expect(commander.undoneCommands.count == 4)

    // test title setting
    let updateTitle = UpdateTitleCommand(displayable: shape, title: "A Shape")
    commander.invoke(command: updateTitle)
    expect(shape.center == .zero)
    expect(shape.title == "A Shape")
    expect(commander.commands.count == 1)
    expect(commander.undoneCommands.count == 0)

    let updateTitle2 = UpdateTitleCommand(displayable: shape, title: "A New Shape")
    commander.invoke(command: updateTitle2)
    expect(shape.title == "A New Shape")
    try! commander.undo()
    expect(shape.title == "A Shape")
}

private func testLayout() {
    let commander = CommandDispatcher(validator: AppValidator(appMode: AppMode(mode: .full)))

    let shapes = [Shape(), Shape(), Shape(), Shape(), Shape(), Shape(), Shape(), Shape(), Shape(), Shape()]
    for (index, shape) in zip(shapes.indices, shapes) {
        shape.title = "#\(index)"
        expect(shape.center == .zero, description: "Verifying Inital state for layout")
    }

    let layoutCommand = LayoutCommand(moveables: shapes, target: .zero)
    commander.invoke(command: layoutCommand)

    Thread.sleep(forTimeInterval: 1.0)

    for (index, shape) in zip(shapes.indices, shapes) {
        expect(shape.center.x == CGFloat(index * 100), description: "Verifying x for shape \(shape)")
        expect(shape.center.y == CGFloat(index * 10), description: "Verifying y for shape \(shape)")
    }

    try! commander.undo()

    Thread.sleep(forTimeInterval: 1.0)

    for shape in shapes {
        expect(shape.center == .zero, description: "Verifying center after undo")
    }
}

private func testValidation() {
    let commander = CommandDispatcher(validator: AppValidator(appMode: AppMode(mode: .readOnly)))

    let shape = Shape()
    let updateCommand = UpdateTitleCommand(displayable: shape, title: "New Title")

    expect(shape.title == "", description: "Verifiying initial title of shape")
    commander.invoke(command: updateCommand)
    expect(shape.title == "", description: "Verifiying title of shape after forbidden command")
    expect(updateCommand.state == .forbidden, description: "Verifiying state of forbidden command")
}

@discardableResult
private func expect(_ expectation: @autoclosure (Void) -> Bool, description: String = "") -> String {
    let succeeded = expectation()
    var output = succeeded ? "✅" : "❌"
    if !description.isEmpty {
        output += " - \(description)"
    }

    if succeeded == false {

    }

    print(output)
    return output
}

main()

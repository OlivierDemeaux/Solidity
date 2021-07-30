const { assert } = require("chai")
const chai = require("chai")
chai.use(require("chai-as-promised"))

const expect = chai.expect

const ToDoList = artifacts.require("ToDo")

contract("toDoList", (accounts) => {
    let toDoList
    beforeEach(async () => {
        toDoList = await ToDoList.new({from: accounts[0]})
    })

    describe("should create a toDo", async () => {
        it("should create 2 new todos and return the todo list", async () => {

            const message1 = 'clean my room'
            let logs = (await toDoList.createToDo(message1)).logs
            assert.equal(logs[0].event, 'toDoCreated')
            assert.equal(logs[0].args.owner, accounts[0])
            assert.equal(logs[0].args.message, message1)
            assert.equal(logs[0].args.id.toNumber(), 0)

            const message2 = 'walk the dog'
            logs = (await toDoList.createToDo(message2)).logs
            assert.equal(logs[0].event, 'toDoCreated')
            assert.equal(logs[0].args.owner, accounts[0])
            assert.equal(logs[0].args.message, message2)
            assert.equal(logs[0].args.id.toNumber(), 1)

            //check the string return of todos
            let myToDos = await toDoList.getMyToDos()
            assert.equal(myToDos, message1 + ', ' + message2)

            //check that account[0] created 2 todos
            let created = await toDoList.counter(accounts[0])
            let count = created.toNumber()
            assert.equal(count, 2)
        })

        it("create a todo and mark it completed", async () => {
            const message = 'clean my room'
            await toDoList.createToDo(message)
            let created = await toDoList.counter(accounts[0])
            let count = created.toNumber()
            assert.equal(count, 1)

            //check toDo id 0 is create but not completed
            let myToDo = await toDoList.getToDo(0)
            assert.equal(myToDo.message, message)
            assert.equal(myToDo.done, false)

            //complete toDo id 0
            let logs = (await toDoList.finishedToDo(0)).logs
            assert.equal(logs[0].event, 'toDoFinished')
            assert.equal(logs[0].args.owner, accounts[0])
            assert.equal(logs[0].args.message, message)
            assert.equal(logs[0].args.id.toNumber(), 0)

            //check toDo id 0 is completed
            myToDo = await toDoList.getToDo(0)
            assert.equal(myToDo.message, message)
            assert.equal(myToDo.done, true)

        })

    })




})
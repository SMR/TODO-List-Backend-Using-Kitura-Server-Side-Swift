
import Foundation
import Kitura
import HeliumLogger
import SQLite
import SwiftyJSON

// extending the collection

extension Sequence where Iterator.Element : Serializable {
    
    func serialize() -> [[String:Any]] {
        
        return self.map{ $0.serialize() }
    }
}

protocol Serializable {
    func serialize() -> [String:Any]
}

class Task : Serializable {
    
    var title :String
    
    init?(row :SQLite.Result.Row) {
        
        let dictionary = row.data
        
        guard let title = dictionary["title"]
        
        else {
            return nil
        }
        
        self.title = title
    }
    
    func serialize() -> [String:Any] {
        return [
            "title":title
        ]
    }
    
}

let databaseName = "todolistDB.sqlite"

let router = Router()
HeliumLogger.use()


// setup the database file 
guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
    fatalError( "Unable to get the document directory path")
}

let databasePath = path.appendingFormat("/%@", databaseName)

if !FileManager.default.fileExists(atPath: databasePath) {
    fatalError("\(databaseName) file does not exist in the documents directory!")
}

let sqlite = try SQLite(path: databasePath)

// BodyParser is required to parse JSON requests
router.post(middleware: BodyParser())

// deleting a task
router.post("/task/delete") { request, response, _ in
    
    guard let body = request.body,
        let json = body.asJSON else {
            try response.status(.badRequest).end()
            return
    }
    
    let id = json["id"].intValue
    let sql = String(format: "delete from tasks where id = %d", id)
    
    _ = try sqlite.execute(sql)
    
}

// get the task by id 
router.get("task/:id") { request, response, next in
    
    guard let id = Int(request.parameters["id"]!) else {
        try response.status(.badRequest).end()
        return
    }
    
    let sql = String(format: "select id, title from tasks where id = %d", id)
    
    let result = try sqlite.execute(sql)
    
    guard let row = result.first else {
        try response.status(.badRequest).end()
        return
    }
    
    if let task = Task(row: row) {
        
        let result = ["result":JSON(task.serialize())]
        response.send(json: JSON(result))
    }
    
    next()
}

// creating a new task
router.post("/task") { request, response, _ in
    
    guard let body = request.body,
          let json = body.asJSON
    else {
        try response.status(.badRequest).end()
        return
    }
    
    let name = json["title"].stringValue
    
    let sql = String(format: "insert into tasks(title) values('%@')", name)

    _ = try sqlite.execute(sql)
    
    guard let id = sqlite.lastId else {
        try response.status(.internalServerError).end()
        return
    }
    
    let result = ["result":["success":true,"id":id]]
    try response.send(json: result).end()
}

// retrieving all the tasks
router.get("/tasks/all") { request, response, next in
    
    let result = try sqlite.execute("select * from tasks;")
    let tasks = result.flatMap(Task.init)
    
    response.send(json :JSON(["tasks":tasks.serialize()]))
    next()
}


Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

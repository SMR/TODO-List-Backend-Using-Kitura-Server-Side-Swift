//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class Task {
    
    var id :Int?
    var title :String
    
    init(title :String) {
        self.title = title
    }
    
    init(dictionary :[String:Any]) {
        
        guard let title = dictionary["title"] as? String,
              let id = dictionary["id"] as? Int
        else {
            fatalError("Parameters missing!")
        }
        
        self.title = title
        self.id = id
    }
}

class TasksTableViewController : UITableViewController, UITextFieldDelegate {
    
    var tasks = [Task]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Tasks"
        populateTasks()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tasks.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 60))
        
        let textfield = UITextField(frame: headerView.frame)
        textfield.placeholder = "Enter task name"
        textfield.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        textfield.leftViewMode = .always
        textfield.delegate = self
        
        headerView.addSubview(textfield)
        
        return headerView
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        addTask(title :textField.text!)
        textField.text = ""
        return textField.resignFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        let task = self.tasks[indexPath.row]
        cell.textLabel?.text = task.title
        return cell
    }
    
    private func addTask(title :String) {
        
        let url = URL(string :"http://localhost:8090/task")!
        
        let task = Task(title: title)
        task.title = title
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["title":task.title], options: [])
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            
        }.resume()
        
    }
    
    private func populateTasks() {
        
        let url = URL(string :"http://localhost:8090/tasks/all")!
        
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            
            let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
            
            guard let dictionaries = json["tasks"] as? [[String:Any]] else {
                return
            }
            
            
            self.tasks = dictionaries.map(Task.init)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            
        }.resume()
        
    }
}

let navigationController = UINavigationController()

let tasksTVC = TasksTableViewController()
tasksTVC.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
navigationController.pushViewController(tasksTVC, animated: false)

PlaygroundPage.current.liveView = navigationController
PlaygroundPage.current.needsIndefiniteExecution = true


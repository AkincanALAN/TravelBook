//
//  ListViewController.swift
//  TravelBook
//
//  Created by Akıncan ALAN on 7/27/24.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var selectedTitle = [String]()
    var selectedId = [UUID]()
    
    var chosenTitle = ""
    var chosenTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTitle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = selectedTitle[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = selectedTitle[indexPath.row]
        chosenTitleId = selectedId[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    @objc func addButtonClicked() {
        chosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destination = segue.destination as! ViewController
            destination.selectedTitle = chosenTitle
            destination.selectedId = chosenTitleId
        }
        
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
                let idString = selectedId[indexPath.row].uuidString
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                do {
                    let results = try context.fetch(fetchRequest)
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == selectedId[indexPath.row] {
                                context.delete(result)
                                selectedTitle.remove(at: indexPath.row)
                                selectedId.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                } catch {
                                    print("error")
                                }
                                break
                            }
                        }
                    }
                } catch {
                    print("error")
                }
            }
        }
    
    
    @objc func getData() {
        
        selectedId.removeAll()
        selectedTitle.removeAll()
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                
                for result in results as! [NSManagedObject] {
                    if let titleValue = result.value(forKey: "title") as? String {
                        self.selectedTitle.append(titleValue)
                    }
                    
                    if let idValue = result.value(forKey: "id") as? UUID {
                        self.selectedId.append(idValue)
                    }
                    
                    tableView.reloadData()
                }
            }
            print("fetch success")
        } catch {
            print("fetch error")
        }
    }
    
}

//
//  FileSelectionViewController.swift
//  iGpxViewer
//
//  Created by Charles Vercauteren on 10/02/2024.
//

import UIKit

protocol FileSelectionDelegate {
    
    func pathSelected(is name: URL)
}

class FileSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var info: UILabel!
    @IBOutlet var fileListTable: UITableView!
    
    var searchPath: FileManager.SearchPathDirectory = .documentDirectory
    var searchDomain: FileManager.SearchPathDomainMask = .allDomainsMask

    var dir: URL?
    var selectedPath: URL?
    var contentStr = ""
    var dirContent = [String]()
    
    var delegate: FileSelectionDelegate?
    var selectedFile = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fileListTable.delegate = self
        fileListTable.dataSource = self

        do {
            dir = try FileManager.default.url(for: searchPath, in: searchDomain, appropriateFor: nil, create: true)
            dirContent = try FileManager.default.contentsOfDirectory(atPath: dir!.path())
            fileListTable.reloadData()
        }
        catch let error as NSError {
            info.text = "Fout lezen map: \(error)"
        }
    }
    
    @IBAction func cursor(_ sender: Any) {
    }
    @IBAction func openBtnPushed(_ sender: Any) {
        if selectedPath != nil {
            delegate?.pathSelected(is: selectedPath!)
            dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedFile = dirContent[indexPath.row]
        selectedPath = dir?.appendingPathComponent(selectedFile)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dirContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = self.dirContent[indexPath.row]
        
        return cell
    }

}

//
//  ViewController+UITableViewDelegate.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/9.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import MetalVideoProcess

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //selected
        if tableView == self.mainTableView {
            let item = self.mainResources[indexPath.row]
            self.mainSelectedItem = item
            currentPostion = item.transformFilter?.translation ?? Position(0.0, 0.0)
            self.mainEditButton.isEnabled = true
            self.mainDeleteButton.isEnabled = true
            self.subEditButton.isEnabled = false
            self.subDeleteButton.isEnabled = false
            self.subSelectedItem = nil
            guard let subIndex = self.subTableView.indexPathForSelectedRow else {
                return
            }
            self.subTableView.deselectRow(at: subIndex, animated: true)
            
        } else {
            let item = self.subResources[indexPath.row]
            self.subSelectedItem = item
            currentPostion = item.transformFilter?.translation ?? Position(0.0, 0.0)
            self.mainEditButton.isEnabled = false
            self.mainDeleteButton.isEnabled = false
            self.subEditButton.isEnabled = true
            self.subDeleteButton.isEnabled = true
            self.mainSelectedItem = nil
            guard let mainIndex = self.mainTableView.indexPathForSelectedRow else {
                return
            }
            self.mainTableView.deselectRow(at: mainIndex, animated: true)
        }
    }
}

extension ViewController: TableViewDraggerDelegate {
    func dragger(_ dragger: TableViewDragger, moveDraggingAt indexPath: IndexPath, newIndexPath: IndexPath) -> Bool {
        if dragger == self.mainDragger! {
            let item = self.mainResources[indexPath.row]
            self.mainResources.remove(at: indexPath.row)
            self.mainResources.insert(item, at: newIndexPath.row)
            mainTableView.moveRow(at: indexPath, to: newIndexPath)
        } else {
            let item = self.subResources[indexPath.row]
            self.subResources.remove(at: indexPath.row)
            self.subResources.insert(item, at: newIndexPath.row)
            subTableView.moveRow(at: indexPath, to: newIndexPath)
        }
        
        
        
        return true
    }
    
    func dragger(_ dragger: TableViewDragger, didEndDraggingAt indexPath: IndexPath) {
        dragger.tableView?.reloadData()
    }
    
    func dragger(_ dragger: TableViewDragger, willEndDraggingAt indexPath: IndexPath) {
        self.rebuildPipeline()
    }
}

extension ViewController: TableViewDraggerDataSource {
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.mainTableView == tableView {
            return self.mainResources.count
        } else {
            return self.subResources.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.mainTableView == tableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "mainCell", for: indexPath) as? ResourceItemTableViewCell else {
                return UITableViewCell()
            }
            let item = self.mainResources[indexPath.row]
            cell.textLabel?.text = NSString(format: "t:%d s:%@ d:%@", item.trackID, item.startTimeText, item.durationText) as String
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "pipCell", for: indexPath) as? ResourceItemTableViewCell else {
                return UITableViewCell()
            }
            let item = self.subResources[indexPath.row]
            cell.textLabel?.text = NSString(format: "t:%d s:%@ d:%@", item.trackID, item.startTimeText, item.durationText) as String
            return cell
        }
    }
    
    
}



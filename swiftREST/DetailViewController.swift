//
//  DetailViewController.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/21/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import UIKit
import SafariServices
import BRYXBanner

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var isStarred: Bool?
    var alertController: UIAlertController?
    var errorBanner: Banner?
    
    var gist: Gist? {
        didSet {
            // only reload if we change gists
            if oldValue?.id == gist?.id {
                return
            }
            configureView()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let _ = isStarred {
                return 3
            }
            return 2
        } else {
            return gist?.files.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch (indexPath.section, indexPath.row, isStarred) {
        case (0, 0, _):
            cell.textLabel?.text = gist?.gistDescription
        case (0, 1, _):
            cell.textLabel?.text = gist?.owner?.login
        case (0, 2, .none):
            cell.textLabel?.text = ""
        case (0, 2, .some(true)):
            cell.textLabel?.text = "Unstar"
        case (0, 2, .some(false)):
            cell.textLabel?.text = "Star"
        default:
            // TODO: show filename
            let file = gist?.orderedFiles[indexPath.row]
            cell.textLabel?.text = file?.name
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "About"
        } else {
            return "Files"
        }
    }
    
    func starThisGist() {
        guard let gistId = gist?.id else {
            return
        }
        GitHubAPIManager.shared.starGist(gistId) { (error) in
            if let error = error {
                print(error)
                self.isStarred = nil
                let errorMessage: String?
                switch error {
                case BackendError.authLost:
                    errorMessage = error.localizedDescription
                default:
                    errorMessage = "Sorry, your gist couldn't be starred. " +
                    "Maybe GitHub is down or you don't have an internet connection."
                break
                }
                if let errorMessage = errorMessage {
                    self.alertController = UIAlertController(title: "Could not star gist",
                                                             message: errorMessage,
                                                             preferredStyle: .alert)
                    // add ok button
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    self.alertController?.addAction(okAction)
                    self.present(self.alertController!, animated: true, completion: nil)
                    return
            } else {
                self.isStarred = true
            }
            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            }
        }
    }
    
    func unstarThisGist() {
        guard let gistId = gist?.id else {
            return
        }
        GitHubAPIManager.shared.unstarGist(gistId) { (error) in
            if let error = error {
                print(error)
                self.isStarred = nil
                let errorMessage: String?
                switch error {
                case BackendError.authLost:
                    errorMessage = error.localizedDescription
                default:
                    errorMessage = "Sorry, your gist couldn't be unstarred. " +
                    "Maybe GitHub is down or you don't have an internet connection."
                    break
                }
                if let errorMessage = errorMessage {
                    self.alertController = UIAlertController(title: "Could not unstar gist",
                                                             message: errorMessage,
                                                             preferredStyle: .alert)
                    // add ok button
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    self.alertController?.addAction(okAction)
                    self.present(self.alertController!, animated: true, completion: nil)
                    return
            } else {
                self.isStarred = true
            }
            self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row, isStarred) {
        case (0, 2, .some(true)):
            unstarThisGist()
        case (0, 2, .some(false)):
            starThisGist()
        case (1, _, _):
            guard let file = gist?.orderedFiles[indexPath.row] else {
                return
            }
//            let url = file.details.url
//            let safariViewController = SFSafariViewController(url: url)
//            safariViewController.title = file.name
//            self.navigationController?.pushViewController(safariViewController, animated: true)
            
            // TODO: show web page to start oauth
//            let url = file.details.url
            guard let url = file.details.url else { return }
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.title = file.name
            present(safariViewController, animated: true, completion: nil)
        default: break
        }
    }
    
    
    
    @IBOutlet weak var tableView: UITableView!
    
    func configureView() {
        if let _ = self.gist {
            fetchStarredStatus()
        }
        
        if let detailView = self.tableView {
            detailView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    func showNotConnectedBanner(title: String, message: String) {
        // show not connected error & tell em to try again when they do have a connection
        self.errorBanner = Banner(title: title,
                                  subtitle: message,
                                  image: nil,
                                  backgroundColor: UIColor.orange)
        self.errorBanner?.dismissesOnSwipe = true
        self.errorBanner?.show(duration: nil)
    }
    
    func fetchStarredStatus() {
        guard let gistId = gist?.id else {
            return
        }
        GitHubAPIManager.shared.isGistStarred(gistId) { (result) in
            guard result.error == nil else {
                print(result.error!)
                switch result.error! {
                case BackendError.authLost:
                    self.alertController = UIAlertController(title: "Could not get starred status", message: result.error!.localizedDescription, preferredStyle: .alert)
                    // add OK button
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    self.alertController?.addAction(okAction)
                    self.present(self.alertController!, animated: true, completion: nil)
                    return
                    case BackendError.network(let innerError as NSError):
                        if innerError.domain != NSURLErrorDomain {
                            return
                        }
                        if innerError.code == NSURLErrorNotConnectedToInternet {
                            self.showNotConnectedBanner(title: "Could not get starred status",
                                                        message: "Sorry, couldn't find out whether you starred this gist. "
                                                            + "Maybe GitHub is down or you don't have an internet connection.")
                        }
                        return
                        
                default: return
                }
            }
            if let status = result.value, self.isStarred == nil {
                self.isStarred = status
                // TODO: update display
                self.tableView?.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            }
        }
    }


}


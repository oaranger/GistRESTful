//
//  MasterViewController.swift
//  swiftREST
//
//  Created by Binh Huynh on 11/21/18.
//  Copyright © 2018 Binh Huynh. All rights reserved.
//

import UIKit
import PINRemoteImage
import SafariServices
import Alamofire
import BRYXBanner

class MasterViewController: UITableViewController, LoginViewDelegate, SFSafariViewControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var gists: [Gist] = []
    var nextPageURLString: String?
    var isLoading = false
    var dateFormatter = DateFormatter()
    var safariViewController: SFSafariViewController?
    var errorBanner: Banner?
    @IBOutlet weak var gistsSegmentedControl: UISegmentedControl!
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        gists = []
        tableView.reloadData()
        // only show add button for my gists
        if (gistsSegmentedControl.selectedSegmentIndex == 2) {
            self.navigationItem.leftBarButtonItem = self.editButtonItem
            let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
            self.navigationItem.rightBarButtonItem = addButton
        } else {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
        }
        loadGists(urlToLoad: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        navigationItem.leftBarButtonItem = editButtonItem

//        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
//        navigationItem.rightBarButtonItem = addButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }
    
    func showNotConnectedBanner() {
        // show not connected error & tell them to try again when they do have a connection
        if let existingBanner = self.errorBanner {
            existingBanner.dismiss()
        }
        self.errorBanner = Banner(title: "No Internet connection", subtitle: "Could not load gists." + " Try again when you are connected to the internet", image: nil, backgroundColor: .red)
        self.errorBanner?.dismissesOnSwipe = true
        self.errorBanner?.show(duration: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        // add refresh control
        if self.refreshControl == nil {
            self.refreshControl =  UIRefreshControl()
            self.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
            self.dateFormatter.dateStyle = .short
            self.dateFormatter.timeStyle = .long
        }
        super.viewWillAppear(animated)
    }
    
    @objc
    func refresh(sender: Any) {
        GitHubAPIManager.shared.isLoadingOAuthToken = false
        nextPageURLString = nil
        GitHubAPIManager.shared.clearCache()
//        loadGists(urlToLoad: nil)
        loadInitialData()
    }

    @objc
    func insertNewObject(_ sender: Any) {
//        let alert = UIAlertController(title: "Not implemented", message: "cant create new gists yet, will implement later", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
        let createVC = CreateGistViewController(nibName: nil, bundle: nil)
        self.navigationController?.pushViewController(createVC, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !GitHubAPIManager.shared.isLoadingOAuthToken {
            loadInitialData()
        }
    }
    
    func showOAuthLoginView() {
        GitHubAPIManager.shared.isLoadingOAuthToken = true
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
            assert(false, "Missednamed view controller")
            return
        }
        loginVC.delegate = self
        self.present(loginVC, animated: true, completion: nil)
    }
    
    func didTapLoginButton() {
        print("didTapLoginButton-MasterVC")
        self.dismiss(animated: false) {
            guard let authURL = GitHubAPIManager.shared.URLToStartOAuth2Login() else {
                let error = BackendError.authCouldNot(reason: "Could not obtain and Oauth token")
                GitHubAPIManager.shared.OAuthTokenCompletionHandler?(error)
                return
            }
            // TODO: show web page to start oauth
            self.safariViewController = SFSafariViewController(url: authURL)
            self.safariViewController?.delegate = self
            guard let webViewController = self.safariViewController else {
                return
            }
            
            self.present(webViewController, animated: true, completion: nil)
        }
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if (!didLoadSuccessfully) {
            controller.dismiss(animated: true, completion: nil)
            GitHubAPIManager.shared.isAPIOnline { (isOnline) in
                if !isOnline {
                    print("Error: API Offline")
                    let innerError = NSError(domain: NSURLErrorDomain,
                                                code: NSURLErrorNotConnectedToInternet,
                                                userInfo: [NSLocalizedDescriptionKey:
                                                    "No Internet Connection or GitHub is Offline",
                                                           NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
                    let error = BackendError.network(error: innerError)
                    GitHubAPIManager.shared.OAuthTokenCompletionHandler?(error)
                    
                }
            }
        }
    }
    
    func loadInitialData() {
        isLoading = true
        GitHubAPIManager.shared.OAuthTokenCompletionHandler = { error in
            guard error == nil else {
                print(error!)
                self.isLoading = false
                // TODO: handle error
                switch error! {
                case BackendError.network(let innerError as NSError):
                    print("debugPrint - BackendError in loadInittialData")
                    if innerError.domain != NSURLErrorDomain {
                        print("debugPrint - error domain not NSURLErrorDomain")
                        break
                    }
                    if innerError.code == NSURLErrorNotConnectedToInternet {
                        self.showNotConnectedBanner()
                        return
                    }
                default:
                    break
                }

                self.showOAuthLoginView()
                return
            }
            
            if let _ = self.safariViewController {
                self.dismiss(animated: false) {}
            }
            self.loadGists(urlToLoad: nil)
        }
        
        if (!GitHubAPIManager.shared.hasOAuthToken()) {
            print("showing OAuthLoginView")
            showOAuthLoginView()
            return
        }
//        GitHubAPIManager.shared.printMyStarredGistsWithOAuth2()
        loadGists(urlToLoad: nil)
    }
    
    func showOfflineSaveFailedBanner() {
        if let existingBanner = self.errorBanner {
            existingBanner.dismiss()
        }
        self.errorBanner = Banner(title: "Could not save gists to view offline",
                                  subtitle: "Your iOS device is almost out of free space.\n" +
            "You will only be able to see gists when you have an internet connection.",
                                  image: nil,
                                  backgroundColor: UIColor.orange)
        self.errorBanner?.dismissesOnSwipe = true
        self.errorBanner?.show(duration: nil)
    }
    
    func loadGists(urlToLoad: String? ) {
        self.isLoading = true
        let completionHandler: (Result<[Gist]>, String?) -> Void = { (result, nextPage) in
            self.isLoading = false
            self.nextPageURLString = nextPage
            guard result.error == nil else {
                self.handleLoadGistsError(result.error!)
                return
            }
            // tell reresh control it can stop showing up now
            if self.refreshControl != nil, self.refreshControl!.isRefreshing {
                self.refreshControl?.endRefreshing()
            }
            
            if let fetchedGists = result.value {
                if urlToLoad == nil {
                    self.gists = []
                }
                self.gists += fetchedGists
                let path: PersistenceManager.Path = [.Public, .Starred, .MyGists][self.gistsSegmentedControl.selectedSegmentIndex]
                let success = PersistenceManager.save(self.gists, path: path)
                if !success {
                    self.showOfflineSaveFailedBanner()
                }
            }
            
            // update "last Updated" title for refresh control
            let now = Date()
            let updateString = "Last Updated at " + self.dateFormatter.string(from: now)
            self.refreshControl?.attributedTitle = NSAttributedString(string: updateString)
            
            
            self.tableView.reloadData()
            
        }
        switch gistsSegmentedControl.selectedSegmentIndex {
        case 0:
            GitHubAPIManager.shared.fetchPublicGists(pageToLoad: urlToLoad, completionHandler: completionHandler)
        case 1:
            GitHubAPIManager.shared.fetchMyStarredGists(pageToLoad: urlToLoad, completionHandler: completionHandler)
        case 2:
            GitHubAPIManager.shared.fetchMyGists(pageToLoad: urlToLoad, completionHandler: completionHandler)
        default:
            print(" got an index that I didnt expect for selectedSegmentIndex")
        }
    }
    
    func handleLoadGistsError(_ error: Error) {
        print(error)
        nextPageURLString = nil
        isLoading = false
        switch error {
        case BackendError.authLost:
            self.showOAuthLoginView()
            return
        case BackendError.network(error: let innerError as NSError):
            // check the domain
            print("debugPrint - BackendError in handleLoadGistsError")
            if innerError.domain != NSURLErrorDomain {
                break
            }
            // check the code
            if innerError.code == NSURLErrorNotConnectedToInternet {
                print("debugPrint - BackendError/HandleLoadGistsError/innerError")
                // TODO:
                let path: PersistenceManager.Path = [.Public, .Starred, .MyGists][self.gistsSegmentedControl.selectedSegmentIndex]
                if let archived: [Gist] = PersistenceManager.load(path: path) {
                    self.gists = archived
                } else {
                    self.gists = []
                }
                self.tableView.reloadData()
                showNotConnectedBanner()
                return
            }
        default: break
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let gist = gists[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.gist = gist
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let gist = gists[indexPath.row]
        cell.textLabel?.text = gist.gistDescription
        cell.detailTextLabel?.text = gist.owner?.login

        cell.imageView?.image = nil
        if let url = gist.owner?.avatarURL {
            cell.imageView?.pin_setImage(from: url, placeholderImage: UIImage(named: "photo"), completion: { (result) in
                if let cellToUpdate = self.tableView?.cellForRow(at: indexPath) {
                    cellToUpdate.setNeedsLayout()
                }
            })
            
        } else {
            cell.imageView?.image = UIImage(named: "photo")
        }
        
        if !isLoading {
            let rowsLoaded = gists.count
            let rowsRemaining = rowsLoaded - indexPath.row
            let rowsToLoadFromBottom = 5
            if rowsRemaining <= rowsToLoadFromBottom {
                if let nextPage = nextPageURLString {
                    self.loadGists(urlToLoad: nextPage)
                }
            }
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        // only allow editing my gists
        return gistsSegmentedControl.selectedSegmentIndex == 2
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let gistToDelete = gists[indexPath.row]
            // remove from array of gists
            gists.remove(at: indexPath.row)
            // remove table view row
            tableView.deleteRows(at: [indexPath], with: .fade)
            // delete from API
            if let idToDelete = gistToDelete.id {
                GitHubAPIManager.shared.deleteGist(idToDelete) { (error) in
                    if let error = error {
                        print(error)
                        self.gists.insert(gistToDelete, at: indexPath.row)
                        tableView.insertRows(at: [indexPath], with: .right)
                        // tell them it didnt work
                        let alertController = UIAlertController(title: "Could not delete gist", message: "Sorry, your gist could not be deleted. Maybe github is down or you dont have an internet connection", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}




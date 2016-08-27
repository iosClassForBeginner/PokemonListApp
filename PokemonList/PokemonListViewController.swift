//
//  PokemonListViewController.swift
//  PokemonList
//
//  Created by Fangchen Huang on 2016-08-16.
//  Copyright © 2016 Paul H. All rights reserved.
//

import UIKit
import WebKit

class PokemonListViewController: UITableViewController {
    
    @IBOutlet var emptyTableView: UIView!
    
    private var pokemons = [String]()
    private var selectedPokemonIndexes = [Int]()
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchResult = [String:[String]]()

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets up Search Controller
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true // dismisses search bar when screen transitions
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Hides tool bar
        navigationController?.toolbarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadTable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set up Refresh Control in `viewDidAppear` to work with the correct frames
        if self.refreshControl == nil {
            self.refreshControl = UIRefreshControl()
            if let refreshControl = self.refreshControl {
                refreshControl.addTarget(self,
                                         action: #selector(PokemonListViewController.resetTable),
                                         forControlEvents: .ValueChanged)
                refreshControl.attributedTitle = NSAttributedString(string: "Catching Pokemon...")
            }
        }
    }
}

// MARK: - Private methods
private extension PokemonListViewController {
    
    @objc func resetTable() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.pokemons = Utils.pokemons
            self.reloadTable()
            
            self.refreshControl?.endRefreshing()
        }
    }
    
    func reloadTable() {
        tableView.reloadData()
        
        tableView.tableFooterView = pokemons.isEmpty ? emptyTableView : nil
        tableView.separatorStyle = pokemons.isEmpty ? .None : .SingleLine
        
        searchController.searchBar.hidden = pokemons.isEmpty
    }
    
    var searchResultKeys: [String] {
        return Array(searchResult.keys).sort()
    }
    
    var searchResultValues: [[String]] {
        return Array(searchResult.values)
    }
    
    func searchResultValue(for key: String) -> [String]? {
        return searchResult[key]
    }
}

// MARK: - Actions
private extension PokemonListViewController {
    
    @objc @IBAction func tappedEditButton(sender: AnyObject) {
        self.editing = !editing

        resetEditButton()
    }
    
    func resetEditButton() {
        if editing {
            // Replacing the title text of UIBarButton doesn't do the trick - had to replace the entire button
            let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(PokemonListViewController.tappedEditButton(_:)))
            navigationItem.rightBarButtonItem = doneButton
            
            navigationController?.setToolbarHidden(false, animated: true)
        }
        else {
            let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(PokemonListViewController.tappedEditButton(_:)))
            navigationItem.rightBarButtonItem = editButton
            
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    @IBAction func tappedTrashButton(sender: AnyObject) {
        selectedPokemonIndexes.forEach { (index) in
            pokemons.removeAtIndex(index)
        }
        
        let indexPaths = selectedPokemonIndexes.map { NSIndexPath(forItem: $0, inSection: 0) }
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        // Resets selected item array
        selectedPokemonIndexes = []
    }
}

// MARK: - Table view data source
extension PokemonListViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isSearchInProgress {
            return searchResult.count
        }
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchInProgress {
            let key = searchResultKeys[section]
            guard let rows = searchResultValue(for: key) else { return 0 }
            
            return rows.count
        }
        
        return pokemons.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PokemonCell", forIndexPath: indexPath)
        
        let imageView = cell.viewWithTag(1) as? UIImageView
        let nameLabel = cell.viewWithTag(2) as? UILabel
        
        var name: String?
        if isSearchInProgress {
            let key = searchResultKeys[indexPath.section]
            if let rows = searchResultValue(for: key) {
                name = rows[indexPath.row]
            }
        }
        else {
            name = pokemons[indexPath.row]
        }
        nameLabel?.text = name ?? ""
        
        imageView?.image = nil
        let santizedName = Utils.santizePokemonName(name)
        let imageUrl = NSURL(string: "https://img.pokemondb.net/artwork/\(santizedName).jpg")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            guard let url = imageUrl,
                let data = NSData(contentsOfURL: url)
                else { return }
            dispatch_async(dispatch_get_main_queue(), {
                imageView?.image = UIImage(data: data)
            });
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard !editing else {
            selectedPokemonIndexes.append(indexPath.row)
            return
        }
        
        let urlPrefix = "https://pokemondb.net/pokedex/"
        
        var pokemonName: String?
        if isSearchInProgress {
            let key = searchResultKeys[indexPath.section]
            if let rows = searchResultValue(for: key) {
                pokemonName = rows[indexPath.row]
            }
        }
        else {
            pokemonName = pokemons[indexPath.row]
        }
        
        let urlString = urlPrefix + Utils.santizePokemonName(pokemonName)
        
        guard let url = NSURL(string: urlString) else { return }
        
        let webView = WKWebView()
        webView.loadRequest(NSURLRequest(URL: url))
        
        let webViewController = UIViewController()
        webViewController.title = pokemonName
        webViewController.view.addSubview(webView)
        webView.frame = webViewController.view.bounds
        
        navigationController?.pushViewController(webViewController, animated: true)
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        guard editing else { return }
        
        if let index = selectedPokemonIndexes.indexOf(indexPath.row) {
            selectedPokemonIndexes.removeAtIndex(index)
        }
    }
}

// MARK: - Swipe-to-action
extension PokemonListViewController {
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return isSearchInProgress ? false : true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let release = UITableViewRowAction(style: .Normal, title: "Release") { (action, indexPath) in
            self.pokemons.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        release.backgroundColor = UIColor.redColor()
        
        let transfer = UITableViewRowAction(style: .Default, title: "Transfer") { (action, indexPath) in
            self.pokemons.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        transfer.backgroundColor = UIColor.lightGrayColor()
        
        return [release, transfer]
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Has to implement this method to enable swiping
    }
}

// MARK: - Search bar
extension PokemonListViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchResult = Utils.indexedArray(from: pokemons)
        
        if let searchText = searchController.searchBar.text where searchText != "" {
            let filtered = pokemons.filter { $0.lowercaseString.containsString(searchText.lowercaseString) }
            searchResult = Utils.indexedArray(from: filtered)
        }
        
        editing = false
        resetEditButton()
        tableView.reloadData()
    }
    
    var isSearchInProgress: Bool {
        return searchController.active
    }
}

// MARK: - Indexes
extension PokemonListViewController {
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchInProgress {
            return searchResultKeys[section]
        }
        
        return nil
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if isSearchInProgress {
            return searchResultKeys
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return searchResultKeys.indexOf(title)!
    }
}

// MARK: - Re-order rows
extension PokemonListViewController {
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return editing
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let pokemon = pokemons[sourceIndexPath.row]
        
        pokemons.removeAtIndex(sourceIndexPath.row)
        pokemons.insert(pokemon, atIndex: destinationIndexPath.row)
    }
}

// MARK: - Cell animation
extension PokemonListViewController {
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let view = cell.contentView
        view.layer.opacity = 0.2
        
        let scaleTransform = CGAffineTransformMakeScale(1.0, 1.2)
        let customTransform = CGAffineTransformTranslate(scaleTransform, 10, 0)
        view.transform = customTransform
        
        UIView.animateWithDuration(0.5) {
            view.layer.opacity = 1
            view.transform = CGAffineTransformIdentity
        }
    }
}

// MARK: - Shake Detection
extension PokemonListViewController {
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            FLEXManager.sharedManager().showExplorer()
        }
    }
}

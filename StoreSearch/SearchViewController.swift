//
//  ViewController.swift
//  StoreSearch
//
//  Created by Mustafa Paslı on 26.10.2020.
//  Copyright © 2020 Mustafa Paslı. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
  struct TableView {
    struct CellIdentifiers {
      static let searchResultCell = "SearchResultCell"
      static let nothingFoundCell = "NothingFoundCell"
      static let loadingCell = "LoadingCell"
    }
  }

  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  
  private let search = Search()
  
  var landscapeVC: LandscapeViewController?
    
  override func viewDidLoad() {
    super.viewDidLoad()

    var cellNib = UINib(nibName: TableView.CellIdentifiers.searchResultCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: "SearchResultCell")
    
    cellNib = UINib(nibName: TableView.CellIdentifiers.nothingFoundCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.nothingFoundCell)
    
    cellNib = UINib(nibName: TableView.CellIdentifiers.loadingCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.loadingCell)
    
    searchBar.becomeFirstResponder()
    
    let segmentColor = UIColor(red: 10/255, green: 80/255, blue: 80/255, alpha: 1)
    let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    let normalTextAttributes = [NSAttributedString.Key.foregroundColor: segmentColor]
    segmentedControl.selectedSegmentTintColor = segmentColor
    
    segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
    segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .highlighted)
      
  }
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    switch newCollection.verticalSizeClass {
    case .compact:
      showLandscape(with: coordinator)
    case .regular, .unspecified:
      hideLandscape(with: coordinator)
    @unknown default:
      fatalError()
    }
  }
  //MARK:- Helper Methods
  
  func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    //1
    guard landscapeVC == nil else { return }
    //2
    landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as?
    LandscapeViewController
    
    if let controller = landscapeVC {
      controller.search = search
      //3
      controller.view.frame = view.bounds
      //4
      view.addSubview(controller.view)
      addChild(controller)
      //
      coordinator.animate(alongsideTransition: { _ in
        controller.view.alpha = 1
        self.searchBar.resignFirstResponder()
      }, completion: { _ in
        controller.didMove(toParent: self)
      })
      
    }
  }
  
  func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    if let controller = landscapeVC {
      controller.willMove(toParent: nil)
      //
      coordinator.animate(alongsideTransition: { _ in
        controller.view.alpha = 0
        if self.presentedViewController != nil {
          self.dismiss(animated: true, completion: nil)
        }
      
      }, completion: { _ in
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        self.landscapeVC = nil
      })
    }
  }
    
    @IBAction func segmentedChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing he iTunes Store."
                                        + "Please tre again.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
  
    if segue.identifier == "ShowDetail" {
      if case .results(let list) = search.state {
        let detailViewController = segue.destination as! DetailViewController
        let indexPath = sender as! IndexPath
        let searchResult = list[indexPath.row]
        detailViewController.searchResult = searchResult
      }
    }
  }
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
  
  func performSearch(){
    
    if let category = Search.Category(
      rawValue: segmentedControl.selectedSegmentIndex) {
      search.performSearch(for: searchBar.text!,
                           category: category, complation:
        {success in
      if !success {
        self.showNetworkError()
      }
      self.tableView.reloadData()
      self.landscapeVC?.searchResultReceived()
          
    })
    
    tableView.reloadData()
    searchBar.resignFirstResponder()
    }
    
  }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
   
}

extension SearchViewController : UITableViewDelegate, UITableViewDataSource {
    
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
    switch search.state {
    case .notSearchedYet:
      return 0
    case .loading:
      return 1
    case .noResults:
      return 1
    case .results(let list):
      return list.count
    }
  }
    
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  
    switch search.state {
    case .notSearchedYet:
      fatalError("Should never get here")
    case .loading:
      let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.loadingCell,
                                               for: indexPath)
      let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
      spinner.startAnimating()
      return cell
    case .noResults:
      return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.nothingFoundCell,
                                           for: indexPath)
    case .results(let list):
      let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.searchResultCell,
                                               for: indexPath) as! SearchResultCell
      let searchResult = list[indexPath.row]
      cell.configure(for: searchResult)
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
    
    performSegue(withIdentifier: "ShowDetail", sender: indexPath)
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    switch search.state {
    case .notSearchedYet, .loading, .noResults:
      return nil
    case .results:
      return indexPath
    }
  }
    
}


//
//  MoviesViewController.swift
//
//
//  Created by hoaqt on 8/26/15.
//
//

import UIKit
import AFNetworking

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate{
    @IBOutlet weak var moviesTab: UITabBarItem!
    @IBOutlet weak var dvdsTab: UITabBarItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var moviesCollectionView: UICollectionView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var networkProblemView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var collectionRefreshControl: UIRefreshControl!
    
    //the keyword for searching
    var keyword:String?
    
    let moviesURL = "https://gist.githubusercontent.com/timothy1ee/d1778ca5b944ed974db0/raw/489d812c7ceeec0ac15ab77bf7c47849f2d1eb2b/gistfile1.json"
    
    //the current url, movies or dvds
    var currentURL = ""
    
    let dvdsURL = "https://gist.githubusercontent.com/timothy1ee/e41513a57049e21bc6cf/raw/b490e79be2d21818f28614ec933d5d8f467f0a66/gistfile1.json"
    
    override func viewDidAppear(animated: Bool) {
        var nav = self.navigationController?.navigationBar
        nav?.barStyle = UIBarStyle.Black
        nav?.tintColor = UIColor.yellowColor()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData(moviesURL)
        tabBar.selectedItem = moviesTab
        segmentControl.selectedSegmentIndex = 1
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        collectionRefreshControl = UIRefreshControl()
        collectionRefreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        moviesCollectionView.insertSubview(collectionRefreshControl, atIndex: 0)
        tabBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        moviesCollectionView.delegate = self
        moviesCollectionView.dataSource = self
    }
    
    @IBAction func listGridSegmentChanged(sender: AnyObject) {
        switch segmentControl.selectedSegmentIndex{
        case 0:
            moviesCollectionView.hidden = true
            tableView.hidden = false
        case 1:
            tableView.hidden = true
            moviesCollectionView.hidden = false
        default:
            break;
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        keyword = searchText.lowercaseString
        if (keyword == ""){
            keyword = nil
        }
        reloadData(currentURL)
    }
    
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        //set keyword to empty - view all the list
        keyword = nil
        searchBar.text = ""
        if item.tag == 1{
            reloadData(moviesURL)
        }
        if item.tag == 2{
            reloadData(dvdsURL)
        }
    }
    
    func reloadData(urlString: String){
        currentURL = urlString
        let hud = AMTumblrHud(frame: CGRectMake(((self.view.frame.size.width - 55) * 0.5), ((self.view.frame.size.height - 20) * 0.5), 55, 22))
        
        hud.hudColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        self.view.addSubview(hud)
        
        hud.showAnimated(true)
        self.networkProblemView.hidden = true
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { ( NSURLResponse, data: NSData!, error: NSError!) -> Void in
            if data == nil {
                self.networkProblemView.hidden = false
            }
            else{
                let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                if let json = json {
                    self.loadDataWithFiltering(json)
                }
                
            }
            self.tableView.reloadData()
            self.moviesCollectionView.reloadData()
            hud.hide()
        }
    }
    
    func loadDataWithFiltering(json: NSDictionary){
        self.movies = [NSDictionary]()
        if let arrayMovies = json["movies"] as? [NSDictionary]{
            for (var i = 0; i<arrayMovies.count;i++){
                let movie = (arrayMovies[i]["title"] as? String)!.lowercaseString as NSString
                if self.keyword == nil || movie.containsString(self.keyword!) == true{
                    self.movies?.append(arrayMovies[i])
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        moviesCollectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = moviesCollectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionViewCell
        
        let movie = movies![indexPath.row]
        
        cell.movieTitle.text = movie["title"] as? String
        let url = NSURL(string: movie.valueForKeyPath("posters.thumbnail") as! String)!
        cell.movieThumbnail.setImageWithURL(url)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getMoviesCount()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return getMoviesCount()
    }
    
    func getMoviesCount() -> Int {
        if let movies = movies {
            return movies.count
        }
        else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = movies![indexPath.row]
        
        cell.titleLabel.text = movie["title"] as? String
        cell.synopsisLabel.text = movie["synopsis"] as? String
        
        let url = NSURL(string: movie.valueForKeyPath("posters.thumbnail") as! String)!
        cell.posterView.setImageWithURL(url)
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor(red: 50, green: 50, blue: 0, alpha: 0.75)
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let tableCell = sender as? UITableViewCell{
        let tableCell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(tableCell)!
        
        let movie = movies![indexPath.row]
        
        let movieDetailsViewController = segue.destinationViewController as! MovieDetailsViewController
        movieDetailsViewController.movie = movie
        }
        else if let collectionCell = sender as? UICollectionViewCell{
            let collectionCell = sender as! UICollectionViewCell
            let indexPath = moviesCollectionView.indexPathForCell(collectionCell)!
            
            let movie = movies![indexPath.row]
            
            let movieDetailsViewController = segue.destinationViewController as! MovieDetailsViewController
            movieDetailsViewController.movie = movie
        }
    }
    
    func delay(delay:Double, closure:()->()){
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
        
    }
    
    func onRefresh(){
        delay(2, closure: {
            self.reloadData(self.currentURL)
            self.refreshControl.endRefreshing()
            self.collectionRefreshControl.endRefreshing()
        })
    }
    
}

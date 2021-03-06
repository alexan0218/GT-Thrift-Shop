//
//  FavoriteViewController.swift
//  GTThriftShop
//
//  Created by Mengyang Shi on 11/29/16.
//  Copyright © 2016 Triple6. All rights reserved.
//

import UIKit

class FavoriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var products = [Product]()
    var selected: Product?
    var userId: Int!
    var favoritedProducts = [Product]()
    var userDefaults = UserDefaults.standard
    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadFavoriteIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(obtainAllProductsFromServer), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing🤣")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        favoritedProducts.removeAll()
        
        loadProductsFromLocal()
        obtainFavoriteProductsFromServer()
        
        tableView.reloadData()
        
        
    }
    
    //Mark: helper methods
    
    func loadProductsFromLocal() {
        if let decoded = userDefaults.object(forKey: "products") as? Data {
            products = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Product]
        } else {
            notifyFailure(info: "Please connect to Internet!")
            //actually might need to manually grab data from server again here. Need opinions
        }
        
        userId = userDefaults.integer(forKey: "userId")
        
    }
    
    func obtainFavoriteProductsFromServer() {
        if products.count <= 0 {
            notifyFailure(info: "No products downloaded! Try again!")
            return
        }
        
        loadFavoriteIndicator.startAnimating()
        let url = URL(string: "http://ec2-34-196-222-211.compute-1.amazonaws.com/favorites/all/\(userId!)")
        
        var request = URLRequest(url:url! as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                DispatchQueue.main.async(execute: {
                    self.notifyFailure(info: "There might be some connection issue. Please try again!")
                });
                
                return
            }
            
            // You can print out response object
            print("******* response = \(response!)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("****** response data = \(responseString!)")
            if let httpResponse = response as? HTTPURLResponse {
                print("***** statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    do {
                        self.favoritedProducts.removeAll()
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                        let array = json["favoritePids"] as! [Int]
                        
                        // Loop through objects
                        for pid in array {
                            //do safe check
                            if !self.products.contains(where: {$0.pid! == pid}) {
                                DispatchQueue.main.async(execute: {
                                    print("unavailable products")
                                    self.notifyFailure(info: "please reload your products")
                                });
                                return
                            }
                            let favProduct = self.findProductByPid(pid: pid)
                            if !(favProduct?.isSold)! {
                                self.favoritedProducts.append(favProduct!)
                            }
                        }
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                    
                    
                    DispatchQueue.main.async(execute: {
                        self.loadFavoriteIndicator.stopAnimating()
                        self.tableView.reloadData()
                    });
                } else if httpResponse.statusCode == 400 {
                    DispatchQueue.main.async(execute: {
                        self.loadFavoriteIndicator.stopAnimating()
                        self.tableView.reloadData()
                    });
                } else if httpResponse.statusCode == 404 {
                    DispatchQueue.main.async(execute: {
                        self.notifyFailure(info: "Cannot connect to Internet!")
                    });
                }
                else {
                    DispatchQueue.main.async(execute: {
                        self.notifyFailure(info: "There might be some connection issue. Please try again!")
                    });
                    
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.notifyFailure(info: "There might be some connection issue. Please try again!")
                });
            }
        }
        
        task.resume()
    }
    
    func findProductByPid(pid: Int) -> Product? {
        for product in products {
            if product.pid! == pid {
                return product
            }
        }
        return nil
    }
    
    func obtainAllProductsFromServer() {
        let url = URL(string: "http://ec2-34-196-222-211.compute-1.amazonaws.com/products")
        
        var request = URLRequest(url:url! as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                DispatchQueue.main.async(execute: {
                    self.notifyFailure(info: "There might be some connection issue. Please try again!")
                });
                
                return
            }
            
            // You can print out response object
            print("******* response = \(response!)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("****** response data = \(responseString!)")
            if let httpResponse = response as? HTTPURLResponse {
                print("***** statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    do {
                        self.products.removeAll()
                        
                        
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Any>
                        let array = json["products"] as! [Dictionary<String, Any>]
                        // Loop through objects
                        for dict in array {
                            guard let name = dict["pName"] as? String,
                                let price = dict["pPrice"] as? String,
                                let info = dict["pInfo"] as? String,
                                let pid = dict["pid"] as? Int,
                                let postTime = dict["postTime"] as? String,
                                let usedTime = dict["usedTime"] as? String,
                                let userId = dict["userId"] as? Int,
                                let userName = dict["nickname"] as? String,
                                let imageUrls = dict["images"] as? [String],
                                let isSold = dict["isSold"] as? Bool
                                else{
                                    self.notifyFailure(info: "cannot unarchive data from server")
                                    return
                            }
                            //                            print("image list --> \(dict["iamges"])")
                            //                            var imageUrls = [String]()
                            //                            imageUrls.append("https://s3-us-west-2.amazonaws.com/gtthriftshopproducts/2/TI841.jpg")
                            let newProduct = Product(name: name, price: price, info: info, pid: pid, postTime: postTime, usedTime: usedTime, userId: userId, userName: userName, imageUrls: imageUrls, isSold: isSold)
                            self.products.append(newProduct)
                        }
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                    
                    
                    DispatchQueue.main.async(execute: {
                        self.obtainFavoriteProductsFromServer()
                        self.refreshControl.endRefreshing()
                    });
                } else if httpResponse.statusCode == 404 {
                    DispatchQueue.main.async(execute: {
                        self.notifyFailure(info: "Cannot connect to Internet!")
                    });
                }
                else {
                    DispatchQueue.main.async(execute: {
                        self.notifyFailure(info: "There might be some connection issue. Please try again!")
                    });
                    
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.notifyFailure(info: "There might be some connection issue. Please try again!")
                });
            }
        }
        
        task.resume()
    }
    
    func notifyFailure(info: String) {
        self.sendAlart(info: info)
        self.loadFavoriteIndicator.stopAnimating()
        self.refreshControl.endRefreshing()
    }
    
    func sendAlart(info: String) {
        let alertController = UIAlertController(title: "Hey!", message: info, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func unwindFromDetailVCtoFavoriteVC(segue: UIStoryboardSegue) {
        if segue.source is ItemDetailViewController {
            print("unwind from detail VC")
        }
    }
    
    //Mark: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritedProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "favoriteItemCell"
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let currentProduct = favoritedProducts[indexPath.row]
        // Fetches the banks for the data source layout.
        let itemImage = cell.contentView.viewWithTag(5) as! UIImageView
        itemImage.layer.cornerRadius = itemImage.frame.width/2
        itemImage.clipsToBounds = true
        
        let itemNameLabel = cell.contentView.viewWithTag(1) as! UILabel
        let yearUsedLabel = cell.contentView.viewWithTag(2) as! UILabel
        let priceLabel = cell.contentView.viewWithTag(3) as! UILabel
        let sellerLabel = cell.contentView.viewWithTag(4) as! UILabel
        
        if currentProduct.imageUrls.count <= 0 {
            itemImage.image = #imageLiteral(resourceName: "No Camera Filled-100")
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("\(currentProduct.pid!)-photo1.jpeg")
            let filePath = fileURL.path
            if FileManager.default.fileExists(atPath: filePath) {
                itemImage.image = UIImage(contentsOfFile: filePath)
            } else {
                DispatchQueue.main.async(execute: {
                    
                    if let imageData: NSData = NSData(contentsOf: URL(string: currentProduct.imageUrls.first!)!) {
                        do {
                            let image = UIImage(data: imageData as Data)
                            itemImage.image = image
                            
                            try UIImageJPEGRepresentation(image!, 1)?.write(to: fileURL)
                        } catch let error as NSError {
                            print("fuk boi--> \(error)")
                        }

                    } else {
                        itemImage.image = #imageLiteral(resourceName: "No Camera Filled-100")
                    }
                })
            }


        }
        itemImage.clipsToBounds = true

        
        itemNameLabel.text = currentProduct.name
        yearUsedLabel.text = "Used for \(currentProduct.usedTime!)"
        priceLabel.text = currentProduct.price
        sellerLabel.text = "Seller: \(currentProduct.userName!)"
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selected = favoritedProducts[indexPath.row]
        performSegue(withIdentifier: "getItemDetailsFromFavorite", sender: nil)
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getItemDetailsFromFavorite"{
            let destination = segue.destination as! ItemDetailViewController
            print(selected!.description)
            destination.product = selected!
            destination.sourceVCName = "favoriteVC"
        }
        
    }
}

//
//  TransactionHistoryTableViewController.swift
//  GTThriftShop
//
//  Created by Mengyang Shi on 3/9/17.
//  Copyright © 2017 Triple6. All rights reserved.
//

import UIKit

class TransactionHistoryTableViewController: UITableViewController {

    var products = [Product]()
    var selected: Product?
    var selectedIsRated: Bool?
    //New
    var selectedTranId: Int?
    
    var userId: Int!
    //var myTransactions = [(Int, Product, Int, Bool)]()
    var myTransactions = [(Int, Product, Int, Bool, Int, String, String)]()
    var userDefaults = UserDefaults.standard
    var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.color = .blue
//        tableView.backgroundView = activityIndicatorView

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.tableView.bounds
        let backImageView = UIImageView(image: UIImage(named: "iOS-9-Wallpaper"))
        backImageView.addSubview(blurEffectView)
        self.tableView.backgroundView = backImageView
        self.tableView.backgroundView?.addSubview(activityIndicatorView)
        
        self.tableView.refreshControl?.addTarget(self, action: #selector(loadMyTransactions), for: .valueChanged)
        self.tableView.refreshControl?.attributedTitle = NSAttributedString(string: "Refreshing🤣")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.isHidden = false
        
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        
        activityIndicatorView.startAnimating()
        
        loadProductsFromLocal()
        loadMyTransactions()
        
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
    
    func loadMyTransactions() {
        
        let url = URL(string: "http://ec2-34-196-222-211.compute-1.amazonaws.com/transactions/getAll/\(userId!)")
        
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
                        self.myTransactions.removeAll()
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String,Any>
                        let array = json["transactions"] as! [Dictionary<String, Any>]
                        // Loop through objects
                        for dict in array {
                            guard let buyerID = dict["buyerID"] as? Int,
                                let sellerID = dict["sellerID"] as? Int,
                                let pid = dict["pid"] as? Int,
                                let isRatedString = dict["isRated"] as? Int,
                                //New
                                let tranID = dict["tranId"] as? Int,
                                let buyerName = dict["buyerName"] as? String,
                                let sellerName = dict["sellerName"] as? String
                                else{
                                    self.notifyFailure(info: "cannot unarchive data from server")
                                    return
                            }
                            let product = self.findProductByPid(pid: pid)
                            var isRated = false
                            if isRatedString == 1 {
                                isRated = true
                            }
                            self.myTransactions.append((sellerID, product!, buyerID, isRated, tranID, buyerName, sellerName))
                        }
                        
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                    
                    
                    DispatchQueue.main.async(execute: {
                        //deal with star here
                        self.initialSort()
                        self.tableView.reloadData()
                        self.activityIndicatorView.stopAnimating()
                        self.tableView.refreshControl?.endRefreshing()
                    });
                }  else if httpResponse.statusCode == 400 {
                    DispatchQueue.main.async(execute: {
                        self.notifyFailure(info: "You don't have any transaction history!")
//                        self.backToUserProfileVC(self)
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
    
    func initialSort() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss z"
        self.myTransactions.sort(by: {dateFormatter.date(from: $0.1.postTime)! > dateFormatter.date(from: $1.1.postTime)!})
    }
    
    func findProductByPid(pid: Int) -> Product? {
        for product in products {
            if product.pid! == pid {
                return product
            }
        }
        return nil
    }
    
    func notifyFailure(info: String) {
        self.sendAlart(info: info)
        self.activityIndicatorView.stopAnimating()
        self.tableView.refreshControl?.endRefreshing()
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
    
    @IBAction func unwindFromDetailVCtoTransactionVC(segue: UIStoryboardSegue) {
        if segue.source is ItemDetailViewController {
            print("unwind from detail VC")
        }
    }
    
    
    @IBAction func backToUserProfileVC(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToUserProfileFromTransaction", sender: self)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return myTransactions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "transactionItemCell"
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let currentTransaction = myTransactions[indexPath.row]
        let currentProduct = currentTransaction.1
        let seller = currentTransaction.0
        let buyer = currentTransaction.2
        let isRated = currentTransaction.3
        let buyerName = currentTransaction.5
        let sellerName = currentTransaction.6
        // Fetches the banks for the data source layout.
        let itemImage = cell.contentView.viewWithTag(5) as! UIImageView
        itemImage.layer.cornerRadius = itemImage.frame.width/2

        let productLabel = cell.contentView.viewWithTag(2) as! UILabel
        let sellerLabel = cell.contentView.viewWithTag(1) as! UILabel
        let buyerLabel = cell.contentView.viewWithTag(3) as! UILabel
        
        let isRatedLabel = cell.contentView.viewWithTag(7) as! UILabel
        
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
                            print("error--> \(error)")
                        }
                        
                    } else {
                        itemImage.image = #imageLiteral(resourceName: "No Camera Filled-100")
                    }
                })
            }
            itemImage.clipsToBounds = true
        }
        
        
        productLabel.text = currentProduct.name
        if userId == seller {
            sellerLabel.text = "You"
            buyerLabel.text = "to " + buyerName
        } else if userId == buyer {
            sellerLabel.text = sellerName
            buyerLabel.text = "to you"
        } else {
            sellerLabel.text = sellerName
            buyerLabel.text = "to " + buyerName
        }
        
        if isRated {
            isRatedLabel.text = "rated"
            isRatedLabel.textColor = .blue
        } else {
            isRatedLabel.text = "unrated"
            isRatedLabel.textColor = .red
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selected = myTransactions[indexPath.row].1
        selectedIsRated = myTransactions[indexPath.row].3
        //New
        selectedTranId = myTransactions[indexPath.row].4
        performSegue(withIdentifier: "getItemDetailsFromTransactionHistory", sender: nil)
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getItemDetailsFromTransactionHistory"{
            let destination = segue.destination as! ItemDetailViewController
            print(selected!.description)
            destination.product = selected!
            destination.isRated = selectedIsRated!
            destination.sourceVCName = "transactionVC"
            //New
            destination.tranId = selectedTranId!


        }
        
    }

   
}

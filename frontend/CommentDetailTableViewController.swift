//
//  CommentDetailTableViewController.swift
//  GTThriftShop
//
//  Created by Mengyang Shi on 3/9/17.
//  Copyright © 2017 Triple6. All rights reserved.
//

import UIKit

class CommentDetailTableViewController: UITableViewController {

    var userId: Int!
    var product: Product!
    var tranId: Int!
    var buyerId: Int!
    var buyerName: String!
    var commentContent: String!
    var postTime: String!
    var rate: Int!
    
    @IBOutlet weak var productImageView: UIImageView!
    
    @IBOutlet weak var sellerNameLabel: UILabel!
    
    @IBOutlet weak var productNameLabel: UILabel!
    
    @IBOutlet weak var postTimeLabel: UILabel!
    
    @IBOutlet weak var commentTextView: UITextView!
    
    @IBOutlet weak var buyerNameLabel: UILabel!
    
    @IBOutlet var stars: [UIImageView]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.tableView.bounds
        let backImageView = UIImageView(image: UIImage(named: "iOS-9-Wallpaper"))
        backImageView.addSubview(blurEffectView)
        self.tableView.backgroundView = backImageView
        
        productImageView.layer.cornerRadius = productImageView.frame.width/2
        productImageView.clipsToBounds = true
        
        userId = UserDefaults.standard.integer(forKey: "userId")
        
        if userId == product.userId! {
            sellerNameLabel.text = "You"
            buyerNameLabel.text = "to " + buyerName
        } else if userId == buyerId! {
            sellerNameLabel.text = product.userName
            buyerNameLabel.text = "you"
        } else {
            sellerNameLabel.text = product.userName
            buyerNameLabel.text = "to " + buyerName
        }
        productNameLabel.text = product.name
        //time format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        let postDate = dateFormatter.date(from: postTime)
        dateFormatter.dateFormat = "MMM dd yyyy, HH:mm"
        let goodDate = dateFormatter.string(from: postDate!)
        postTimeLabel.text = goodDate
        
        commentTextView.text = "   " + commentContent
        
        if product.imageUrls.count <= 0 {
            productImageView.image = #imageLiteral(resourceName: "No Camera Filled-100")
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("\(product.pid!)-photo1.jpeg")
            let filePath = fileURL.path
            if FileManager.default.fileExists(atPath: filePath) {
                productImageView.image = UIImage(contentsOfFile: filePath)
            } else {
                DispatchQueue.main.async(execute: {
                    
                    if let imageData: NSData = NSData(contentsOf: URL(string: self.product.imageUrls.first!)!) {
                        do {
                            let image = UIImage(data: imageData as Data)
                            self.productImageView.image = image
                            
                            try UIImageJPEGRepresentation(image!, 1)?.write(to: fileURL)
                        } catch let error as NSError {
                            print("fuk boi--> \(error)")
                        }
                        
                    } else {
                        self.productImageView.image = #imageLiteral(resourceName: "No Camera Filled-100")
                    }
                })
            }
            productImageView.clipsToBounds = true
        }
        displayRateInStars()
    }
    
    func displayRateInStars() {
        if rate < 1 {
            for i in 0...4 {
                stars[i].image = #imageLiteral(resourceName: "Rating-100")
            }
            return
        }
        for i in 0...rate-1 {
            stars[i].image = #imageLiteral(resourceName: "Rating Filled-100")
        }
        if rate > 4 {
            return
        }
        for i in rate...4 {
            stars[i].image = #imageLiteral(resourceName: "Rating-100")
        }
    }

    
    @IBAction func unwindToPreviousPage(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToMyCommentVC", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  CategoryViewController.swift
//  Ecommerce
//
//  Created by Neethu Sadasivan on 13/11/17.
//  Copyright © 2017 Neethu Sadasivan. All rights reserved.
//

import UIKit
import CoreData

class CategoryController: UIViewController, APIControllerProtocol {

    lazy var fetchedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Category.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "categoryID", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self as? NSFetchedResultsControllerDelegate
        return frc
    }()
    
    let api = APIController()
    let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    let context = CoreDataStack.sharedInstance.persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addActivityIndicator()
        api.delegate = self
        fetchData()

    }
    
    func addActivityIndicator() {
        myActivityIndicator.center = view.center
        myActivityIndicator.activityIndicatorViewStyle = .whiteLarge
        //myActivityIndicator.color = UIColor.lightGray
        myActivityIndicator.hidesWhenStopped = true
        view.addSubview(myActivityIndicator)
    }
    
    func fetchData() {
        do {
            try self.fetchedhResultController.performFetch()
            print("Fetched data count = \(self.fetchedhResultController.sections?[0].numberOfObjects)")
        } catch let error  {
            print("Error = \(error)")
        }
        
        myActivityIndicator.startAnimating()
        DispatchQueue.main.async {
            self.api.fetchJSONData(urlString: "https://stark-spire-93433.herokuapp.com/json")
        }
    }
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    private func createCategoryEntityFrom(dictionary: [String: Any]) -> NSManagedObject? {
        
        if let categoryEntity = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category {
            guard let categoryID = dictionary["id"] as? Int16 else {
                return nil
            }
            categoryEntity.categoryID = categoryID
            categoryEntity.categoryName = dictionary["name"] as? String
            if let products = dictionary["products"] as? [[String: Any]] {
                for product in products {
                    let productEntity = createProductEntityFrom(dictionary: product, category: categoryEntity)
                    categoryEntity.products = NSSet(object: productEntity as! Product)
                }
            }
            if let childCategories = dictionary["child_categories"] as? [Int] {
                for subCategory in childCategories {
                    let subCategoryEntity = createSubCategoryEntityFrom(subCategoryId: subCategory, category: categoryEntity)
                    categoryEntity.subcategories = NSSet(object: subCategoryEntity as! Category)
                }

            }
            return categoryEntity
        }
        return nil
    }
    
    private func createProductEntityFrom(dictionary: [String: Any], category: NSManagedObject) -> NSManagedObject? {
        
        if let productEntity = NSEntityDescription.insertNewObject(forEntityName: "Product", into: context) as? Product {
            
            guard let productID = dictionary["id"] as? Int16 else {
                return nil
            }
            productEntity.productID = productID
            productEntity.productName = dictionary["name"] as? String
            productEntity.dateAdded = dictionary["date_added"] as? String
            if let tax = dictionary["tax"] as? [String: Any] {
                productEntity.taxName = tax["name"] as? String
                productEntity.taxValue = (tax["value"] as? Float)!
            }
            if let variants = dictionary["variants"] as? [[String: Any]] {
                for variant in variants {
                    let variantEntity = createVariantEntityFrom(dictionary: variant, product: productEntity)
                    productEntity.variants = NSSet(object: variantEntity as! Variant)
                    
                }
                
            }
            return productEntity
        }
        return nil
        
    }
    
    private func createVariantEntityFrom(dictionary: [String: Any], product: NSManagedObject) -> NSManagedObject? {
        print("variant dictionary = \(dictionary)")
        if let variantEntity = NSEntityDescription.insertNewObject(forEntityName: "Variant", into: context) as? Variant {
            guard let variantID = dictionary["id"] as? Int16 else {
                return nil
            }
            variantEntity.variantID = variantID
            variantEntity.variantColor = dictionary["color"] as? String
            if let variantSize = dictionary["size"] as? Int16  {
                variantEntity.variantSize = variantSize
            }
            if let variantPrize = dictionary["price"] as? Int32  {
                variantEntity.variantPrize = variantPrize
            }
            
            return variantEntity
        }
        return nil
    }
    
    private func createSubCategoryEntityFrom(subCategoryId: Int, category: NSManagedObject) -> NSManagedObject? {
        if let subcategoryEntity = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as? Category {
            subcategoryEntity.categoryID = Int16(subCategoryId)
            //subcategoryEntity.categoryName = dictionary["name"] as? String
            return subcategoryEntity
        }
        return nil
    }
    
    private func createRankingEntityFrom(dictionary: [String: Any]) -> NSManagedObject? {
        
        if let rankEntity = NSEntityDescription.insertNewObject(forEntityName: "Ranking", into: context) as? Ranking {
            
            rankEntity.rankingName = dictionary["ranking"] as? String
            if let products = dictionary["products"] as? [[String: Any]] {
                for product in products {
                    let productRankEntity = createProductRankingEntityFrom(dictionary: product, ranking: rankEntity)
                    rankEntity.productrankings = NSSet(object: productRankEntity as! ProductRanking)
                }
            }
            return rankEntity
        }
        return nil
    }
    
    func createProductRankingEntityFrom(dictionary: [String: Any], ranking: NSManagedObject) -> NSManagedObject? {
        if let prodRankEntity = NSEntityDescription.insertNewObject(forEntityName: "ProductRanking", into: context) as? ProductRanking {
            if let prodRankId = dictionary["id"] as? Int16 {
                prodRankEntity.prodID = prodRankId
            }
            
            if let viewCount = dictionary["view_count"] as? Int64 {
                prodRankEntity.viewCount = viewCount
            }
            return prodRankEntity
        }
        return nil
    }
    
    private func saveInCategoryDataWith(array: [[String: Any]]) {
        _ = array.map{self.createCategoryEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    private func saveInRankingDataWith(array: [[String: Any]]) {
        _ = array.map{self.createRankingEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    private func clearData() {
        
        do {
            let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
            let categoryFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Category.self))
            let rankingFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Ranking.self))
            let productFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Product.self))
            do {
                let objectsCategory  = try context.fetch(categoryFetchRequest) as? [NSManagedObject]
                _ = objectsCategory.map{$0.map{context.delete($0)}}
                let objectsRanking  = try context.fetch(rankingFetchRequest) as? [NSManagedObject]
                _ = objectsRanking.map{$0.map{context.delete($0)}}
                let objectsProduct  = try context.fetch(productFetchRequest) as? [NSManagedObject]
                _ = objectsProduct.map{$0.map{context.delete($0)}}
                CoreDataStack.sharedInstance.saveContext()
            } catch let error {
                print("ERROR DELETING CATEGORY: \(error)")
            }
        }
        
    }
    
    func didReceiveAPIResults(_ results: Dictionary<String, Any>) {
        
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.myActivityIndicator.stopAnimating()
        }

        print("results====\(results)")
        guard let jsonData = results["json_data"] as? [String: Any] else {
            DispatchQueue.main.async {
                if let error = results["error"] as? String {
                    self.showAlertWith(title: "Error", message: error)
                }
            }
            return
        }
        self.clearData()
        guard let categories = jsonData["categories"] as? [[String: Any]] else {
            return
        }
        saveInCategoryDataWith(array: categories)
        guard let rankings = jsonData["rankings"] as? [[String: Any]] else {
            return
        }
        saveInRankingDataWith(array: rankings)
        
    }

}

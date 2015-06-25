//
//  UserListController.swift
//  Shopping List
//
//  Created by Diego Haz on 5/28/15.
//  Copyright (c) 2015 Matheus Falcão. All rights reserved.
//

import UIKit
import MessageUI


class UserListController: GAITrackedViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITextFieldDelegate, ItemViewCellDelegate {
    
    var reusableView: UserListView?
    var collectionView: UICollectionView?
    var list: List?
    var products = [Product]()
    var isNew = false
    
    var mail_sender: MailSender! = MailSender()
    
    var shareController: ShareController!
    
    var autoComplete: AutoCompleteController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "User List"

        // Reusable View
        reusableView = NSBundle.mainBundle().loadNibNamed("UserListView", owner: self, options: [:])[0] as? UserListView
        view = reusableView

        
        // Collection View
        collectionView = reusableView?.collectionView
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerNib(UINib(nibName: "ItemViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemCell")
        
        // Text Field
        reusableView?.newItemTextField.delegate = self
        
        // Navigation
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share"), style: UIBarButtonItemStyle.Plain, target: self, action: "share:")
        
        let title = TitleTextField(frame: CGRectMake(0, 0, 180, 32))
        title.text = self.list?.name
        title.delegate = self
        navigationItem.titleView = title
        
        if isNew {
            reusableView?.newItemTextField.becomeFirstResponder()
        }
        
        reusableView?.newItemTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "methodOfReceivedNotification:", name:"addSearchedProductToList", object: nil)
        

    }
    
    
    func textFieldDidChange(textField: UITextField) {
        
        if autoComplete == nil{
        autoComplete = AutoCompleteController(frame: CGRectMake(0,self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.height - 7.5,self.view.frame.width, self.view.frame.height))
        autoComplete.wordChanged(textField.text)
        self.view.addSubview(autoComplete)
            println("adicionou a tableview")
        }

        if count(textField.text) == 0 {
            autoComplete.removeFromSuperview()
            autoComplete = nil
        }
    
    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        
        trackScreen("UserLists")
        
        if list != nil {
            DAORemoto.sharedInstance.allProductsOfList(list!, callback: { (arrayProducts : [Product]) -> Void in
                self.products = arrayProducts
                self.collectionView?.reloadData()
            })
        }
    }
    

    
    func share(sender: UIBarButtonItem){

        shareController = ShareController()
        shareController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        shareController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        shareController.list = list

        self.presentViewController(shareController, animated: true, completion: nil)

    }
    
    func doneItem(cell: ItemViewCell) {
        let indexPath = collectionView!.indexPathForCell(cell)
        
        DAORemoto.sharedInstance.deleteProductFromList(products[indexPath!.row], list: self.list!)
        trackEvent("Lists Operations", action: "Remove Product From List", label: products[indexPath!.row].name, value: 10)
        
        products.removeAtIndex(indexPath!.row)
        collectionView!.reloadData()
    }
    
    func removeItem(cell: ItemViewCell) {
        let indexPath = collectionView!.indexPathForCell(cell)
        
        DAORemoto.sharedInstance.deleteProductFromList(products[indexPath!.row], list: self.list!)
        
        products.removeAtIndex(indexPath!.row)
        collectionView!.reloadData()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if !textField.isEqual(reusableView?.newItemTextField) {
            let title = (self.navigationItem.titleView as! TitleTextField).text
            DAORemoto.sharedInstance.changeNameOfList(title, list: self.list!)
            trackEvent("Lists Operations", action: "Edit List Name", label: title, value: 10)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        autoComplete.removeFromSuperview()
        autoComplete = nil
        if textField.isEqual(reusableView?.newItemTextField) {
            let product = Product()
            product.name = textField.text
            textField.text = ""
            
            DAORemoto.sharedInstance.addProductToList(product.name, list: self.list!)
            trackEvent("Lists Operations", action: "Add New Product to List", label: product.name, value: 10)

            products.insert(product, atIndex: 0)
            collectionView!.reloadData()
            collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
            
            return true
        } else {
            let title = (self.navigationItem.titleView as! TitleTextField).text
            DAORemoto.sharedInstance.changeNameOfList(title, list: self.list!)
            trackEvent("Lists Operations", action: "Edit List Name", label: title, value: 10)

            return true
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSize(width: self.view.bounds.width, height: 48)
        
        return size
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ItemCell", forIndexPath: indexPath) as! ItemViewCell
        let product = self.products[indexPath.row]
        
        cell.delegate = self
        cell.label.text = product.name
        
        return cell
    }
    
    
    func methodOfReceivedNotification(notification: NSNotification){
        println("notification funfaando")
        let product = Product()
        product.name = notification.object as! String
        
        DAORemoto.sharedInstance.addProductToList(product.name, list: self.list!)
        trackEvent("Lists Operations", action: "Add New Product to List", label: product.name, value: 10)

        
        products.insert(product, atIndex: 0)
        collectionView!.reloadData()
        collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
    }
    
}

//
//  DAO.swift
//  Shopping List
//
//  Created by Matheus Falcão on 25/05/15.
//  Copyright (c) 2015 Matheus Falcão. All rights reserved.
//

import Foundation

private let _dao = DAORemoto()

class DAORemoto {
    
    class var sharedInstance: DAORemoto {
        return _dao
    }
    
    private init() {
    }
    
    
    //Lists:
    
    /**Função que salva um nova lista:*/
    func saveNewList(list : List) -> List{
        
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/")
        
        var tags = []
        var products = []
        var users = []
        
        var info = ["searchName": FunctionsDAO.sharedInstance.normaliza(list.name),"name": "\(list.name)", "products": products, "tags": tags, "users": users]

        var listRef = myRootRef.childByAppendingPath("list")
        
        //Gerando o ID e colocando na lista:
        var infoAdd = listRef.childByAutoId()
        list.id = infoAdd.key
        
        //Salvando a nova Lista no CoreData:
        DAOLocal.sharedInstance.save()
        
        //Salvando no FireBase:
        infoAdd.setValue(info, withCompletionBlock: { ((NSError!, Firebase!)) in
            //Adicionando essa lista ao usuário logado
            var user : User
            user = DAOLocal.sharedInstance.readUser()
            FunctionsDAO.sharedInstance.createRelationUserList(user, list:list)
        })
        
        
        return list
        
    }
    
    
    /**Função que retorna todas as listas de um usuário:*/
    func allListOfUser(callback: [List] -> Void) {
        
        var user : User = DAOLocal.sharedInstance.readUser()
    
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/user/\(user.id)/lists")
        
        var arrayList : [List] = []
        
        myRootRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot: FDataSnapshot!) -> Void in
        
            var key = snapshot.key

            FunctionsDAO.sharedInstance.searchListFromID(key, callback: { (list) in

                arrayList.insert(list, atIndex: 0)
                callback(arrayList)
                
            })
        
        })
        
        var myRootRef2 = Firebase(url:"https://luminous-heat-6986.firebaseio.com/user/\(user.id)/lists")
        
        myRootRef2.observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot: FDataSnapshot!) -> Void in
            
            var key = snapshot.key
            
            FunctionsDAO.sharedInstance.searchListFromID(key, callback: { (list) in
                
                var i = 0
                for x in arrayList {
                    if( x.id == list.id ){
                        break;
                    }
                    i++;
                }
                
                arrayList.removeAtIndex(i)
                callback(arrayList)
                
            })
            
        })
        
    }
    
    
    /**Funçao que adiciona produto em uma lista:*/
    func addProductToList(name : String, list : List, callback: (List) -> Void) {
        
        FunctionsDAO.sharedInstance.searchProductFromName(name, callback: { (product : Product) in
            
            var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)")
            
            myRootRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
                
                if( snapshot.exists() == true ){
                    var refProd = myRootRef.childByAppendingPath("products")
                    var prod = ["\(product.id)": true]
                    refProd.updateChildValues(prod)
                } else {
                    print("lista não existe \n")
                }
                
            })
            
            callback(DAOLocal.sharedInstance.addProduct(product, list: list))
            
        })
        
    }
    
    /**Função que deleta um produto de uma lista*/
    func deleteProductFromList(product : Product, list: List) {
        
        FunctionsDAO.sharedInstance.searchProductFromName(product.name, callback: { products in
        
            var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)/products/\(products.id)")
            
            myRootRef.removeValue()
            
            list.removeProduct(product)
            
        })
        
    }
    
    /**Função que muda o nome de uma lista*/
    func changeNameOfList(name : String, list: List) {
     
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)")
        
        myRootRef.observeEventType(FEventType.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
            
            if( snapshot.exists() == true ){
                var dic = snapshot.value as! NSDictionary
                
                dic.setValue(name, forKey: "name")
                
                myRootRef.setValue(dic)
                
            }
            
        })
        
    }
    
    /**Função que deleta uma lista*/
    func deleteList(list : List){
        
        var user : User = DAOLocal.sharedInstance.readUser()
        
        var myUserRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/user/\(user.id)/lists/\(list.id)")
        
        myUserRef.removeValue()
        
        var myListRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)")
        
        myListRef.removeValue()
        
    }
    
    
    //Products:
    
    /**Função que salva um novo produto:*/
    func saveNewProduct(product : Product) -> Product{
        
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/")
        
        var info = ["searchName": FunctionsDAO.sharedInstance.normaliza(product.name),"name": "\(product.name)", "brand": "\(product.brand)", "cubage": "\(product.cubage)"]
        
        var listRef = myRootRef.childByAppendingPath("product")
        
        //Gerando o ID e colocando na lista:
        var infoAdd = listRef.childByAutoId()
        product.id = infoAdd.key
        
        //Salvando no FireBase:
        infoAdd.setValue(info)
        
        return product
        
    }

    /**Função que retorna todos os produtos de uma lista, e isso inclui uma atualização quando tem mais de um usuário na mesma lista*/
    func allProductsOfList(list : List, callback: ([Product]) -> Void ) {
        
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)/products")
        
        var products : [Product] = []

        myRootRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot : FDataSnapshot!) -> Void in
            
            var key = snapshot.key 
            
            FunctionsDAO.sharedInstance.searchProductFromID(key, callback: { (product : Product) -> Void in
                products.insert(product, atIndex: 0)
                callback(products)
            })
            
        })
        
        var myRootRef2 = Firebase(url:"https://luminous-heat-6986.firebaseio.com/list/\(list.id)/products")
        
        myRootRef2.observeEventType(FEventType.ChildRemoved, withBlock: { (snapshot : FDataSnapshot!) -> Void in
            
            var key = snapshot.key
            
            FunctionsDAO.sharedInstance.searchProductFromID(key, callback: { (product : Product) -> Void in
                var i = 0
                for x in products {
                    if( x.name == product.name ){
                        break;
                    }
                    i++;
                }
                products.removeAtIndex(i)
                callback(products)
            })
            
        })
        
    }
    
    //Relacão User e List
    
    /**Funcão que adiciona um amigo a uma lista*/
    func addFriendToList(idFB : String, list : List) {
        
        FunctionsDAO.sharedInstance.searchIDFromIDFB(idFB, callback: { (id : String) in
            
            var user : User = User()
            
            user.id = id
            
            FunctionsDAO.sharedInstance.createRelationUserList(user, list: list)
            
        })
        
    }
    
    //Suggestions:
    
    /**Função que retorna todas as listas de um usuário:*/
    func suggestionsLists(callback: [List] -> Void) {
        
        var myRootRef = Firebase(url:"https://luminous-heat-6986.firebaseio.com/suggestion")
        
        myRootRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot: FDataSnapshot!) -> Void in
            
            var arrayList : [List] = []
            
            if( snapshot.exists() == true ){
                
                var dic = snapshot.value as! NSDictionary
                
                var keys = dic.allKeys
                for x in keys {
                    FunctionsDAO.sharedInstance.searchListFromID(x as! String, callback:  { (lis : List) in
                                
                        arrayList.append(lis)
                                
                        if( keys.count == arrayList.count ){
                            callback(arrayList)
                        }
                                
                    })
                    
                }
                
            }
            
        })
        
    }
    
    
    
    
    
    
    
    
}
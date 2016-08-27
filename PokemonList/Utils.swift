//
//  Utils.swift
//  PokemonList
//
//  Created by Fangchen Huang on 2016-08-17.
//  Copyright © 2016 Paul H. All rights reserved.
//

import Foundation

class Utils {
    static var pokemons: [String] {
        var array = [String]()
        
        if let filepath = NSBundle.mainBundle().pathForResource("pokemons", ofType: "plist"),
            let content = NSArray(contentsOfFile: filepath) as? [String] {
            array += content
        }
        
        return array
    }
    
    class func indexedArray(from array: [String]) -> [String:[String]] {
        var dict = [String:[String]]()
        
        array.forEach { (element) in
            guard let char = element.characters.first else { return }
            
            let key = String(char).uppercaseString
            if let subArray = dict[key] {
                dict[key] = subArray + [element]
            }
            else {
                dict[key] = [element]
            }
        }
        
        return dict
    }
    
    class func santizePokemonName(name: String?) -> String {
        guard let rawName = name else { return "" }
        
        return rawName.lowercaseString
            .stringByReplacingOccurrencesOfString(". ", withString: "-")
            .stringByReplacingOccurrencesOfString("'", withString: "")
            .stringByReplacingOccurrencesOfString("♀", withString: "-f")
            .stringByReplacingOccurrencesOfString("♂", withString: "-m")
    }
}

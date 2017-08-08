//
//  main.swift
//  darcy
//
//  Created by jakeluck on 8/3/17.
//  Copyright © 2017 freetime. All rights reserved.
//

import Foundation


// optimized version to keep just range
func s4(input: String) -> [NSRange] {
    let options: NSLinguisticTagger.Options =
        [.omitWhitespace, .omitWords, .joinNames]
    
    let scheme = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let tagger = NSLinguisticTagger(tagSchemes: scheme, options: Int(options.rawValue))
    
    
    tagger.string = input
    let range = NSRange(location: 0, length: input.utf16.count)
    var current_sentence: String = ""
    var result : [NSRange] = []
    
    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass,options: options) {
        tag, tokenRange, sentenceRange, stop in
        let sentence = (input as NSString).substring(with: sentenceRange)
        if sentence != current_sentence {
            //print("\(token) \(tag):  \(sentence)")
            result.append(sentenceRange)
        }
        current_sentence = sentence
    }
    return result
}

func remove_sentences(number: Int, infile: String, outfile: String, lessfile: String) {
    guard let full = try? String(contentsOfFile: infile, encoding: .ascii) else {
        print("read \(infile) failed")
        return
    }
    var parsed = s4(input: full)
    
    var locations : [Int]  = []
    
    guard parsed.count > number else {
        print("data sample smaller than extract size")
        return
    }
    
    // using longer sentences skips over poorly formatted input containing
    // linebreaks, such as Emma
    while locations.count < number {
        let r = Int(arc4random_uniform(UInt32(parsed.count)))
        if !locations.contains(r) && parsed[r].length > 30 {
            locations.append(r)
        }
    }
    
    // remove from back to front
    let reverse = locations.sorted(by: >)
    let lessfull = NSMutableString(string: full)
    var extracted : [String] = []
    for i in 0..<reverse.count {
        let nsrange = parsed[reverse[i]]
        let sentence = (lessfull as NSString).substring(with: nsrange)
        extracted.append(sentence)
        lessfull.deleteCharacters(in: nsrange)
        //print(s)
    }
    
    let less = extracted.reversed().joined(separator: "\r\n")
    
    do {
        try lessfull.write(toFile: outfile, atomically: true, encoding: String.Encoding.utf8.rawValue)
    } catch {
        print("write \(outfile) failed")
        return
    }
    
    do {
        try less.write(toFile: lessfile, atomically: true, encoding: .utf8)
    } catch {
        print("write \(lessfile) failed")
        return
    }
    
}

func gen_filenames(name: String) -> (String, String) {
    return (name.appending("_less.utf8"), name.appending("_extra.utf8"))
}


var units_to_drop : Int
var filename: String

//print(CommandLine.arguments)

switch CommandLine.argc {
case 2:
    filename = CommandLine.arguments[1]
    units_to_drop = 500
case 3:
    filename = CommandLine.arguments[1]
    units_to_drop = Int(CommandLine.arguments[2])!
default:
    print("Usage: darcy <filename> [number]")
    print("   creates <filename_less.utf8> and <filename_extra.utf8>\n")
    exit(EXIT_FAILURE)
}

let (out, less) = gen_filenames(name: filename)
remove_sentences(number: units_to_drop, infile: filename, outfile: out, lessfile: less)



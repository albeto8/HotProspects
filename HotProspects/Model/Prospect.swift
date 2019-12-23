//
//  Prospect.swift
//  HotProspects
//
//  Created by Mario Alberto Barragan Espinosa on 12/20/19.
//  Copyright © 2019 Mario Alberto Barragan Espinosa. All rights reserved.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
    let date = Date()
}

class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    
    static let saveKey = "SavedData"

    init() {
      /*
        if let data = UserDefaults.standard.data(forKey: Self.saveKey) {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                self.people = decoded
                return
            }
        }
 */
       let filename = FileManager.getDocumentsDirectory().appendingPathComponent(Prospects.saveKey)
        do {
            let data = try Data(contentsOf: filename)
            people = try JSONDecoder().decode([Prospect].self, from: data)
        } catch {
            print("Unable to load saved data.")
            self.people = []
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: Self.saveKey)
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        //save()
        saveData()
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }

    func saveData() {
        do {
          let filename = FileManager.getDocumentsDirectory().appendingPathComponent(Self.saveKey)
            let data = try JSONEncoder().encode(self.people)
            try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Unable to save data.")
        }
    }
}


extension FileManager {
  static func getDocumentsDirectory() -> URL {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      return paths[0]
  }
}

//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Mario Alberto Barragan Espinosa on 12/20/19.
//  Copyright © 2019 Mario Alberto Barragan Espinosa. All rights reserved.
//

import SwiftUI
import UserNotifications
import CodeScanner

enum FilterType {
    case none, contacted, uncontacted
}

enum SortedType {
    case name, date
}

struct ProspectsView: View {
    let filter: FilterType

    @EnvironmentObject var prospects: Prospects
    
    @State private var isShowingScanner = false
    @State private var isSortedBy =  SortedType.name

    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }

    var filteredProspects: [Prospect] {
        var currentProspects = prospects.people
        switch filter {
        case .none:
            currentProspects = prospects.people
        case .contacted:
            currentProspects = prospects.people.filter { $0.isContacted }
        case .uncontacted:
            currentProspects = prospects.people.filter { !$0.isContacted }
        }
        if self.isSortedBy == .name {
          return currentProspects.sorted(by: { $0.name < $1.name })
        }
          return currentProspects.sorted(by: { $0.date > $1.date })
    }
  
    var body: some View {
        NavigationView {
            List {
              ForEach(filteredProspects) { prospect in
                  HStack {
                      VStack(alignment: .leading) {
                          Text(prospect.name)
                              .font(.headline)
                          Text(prospect.emailAddress)
                              .foregroundColor(.secondary)
                      }
                    Spacer()
                      prospect.isContacted ? Image(systemName: "person.crop.circle.fill.badge.checkmark") : Image(systemName: "person.crop.circle.badge.xmark")
                    }
                    .contextMenu {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted" ) {
                            self.prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind Me") {
                                self.addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
                .navigationBarTitle(title)
              .navigationBarItems(leading: Button(action: {
                    self.isShowingScanner = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                },
                trailing: Button(action: {
                    if self.isSortedBy  == .name {
                      self.isSortedBy = .date
                    } else {
                      self.isSortedBy = .name
                    }
                  }) {
                    Text("Sort by \(self.isSortedBy == .name ? "date" : "name")")
                  })
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "Ario Hudson\npaul@hackingwithswift.com", completion: self.handleScan)
                }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
       self.isShowingScanner = false
        // more code to come
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }

            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]

            self.prospects.add(person)
        case .failure(let error):
            print("Scanning failed")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
            //let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
    
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}

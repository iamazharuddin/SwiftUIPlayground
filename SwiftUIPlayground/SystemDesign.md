# Create the markdown file with the same content

content = """# 📘 System Design Notes (iOS / Swift)

---

## 🔹 SOLID Principles

- **S — Single Responsibility Principle**
- **O — Open/Closed Principle**
- **L — Liskov Substitution Principle**  
  https://medium.com/better-programming/solid-swift-by-examples-part-three-675672c1ec20
- **I — Interface Segregation Principle**
- **D — Dependency Inversion Principle**  
  - High-level & low-level modules depend on **abstractions**  
  - Achieved via **protocols (interfaces)**

---

## 🔹 Design Patterns

Reference:
https://www.geeksforgeeks.org/system-design/design-patterns-cheat-sheet-when-to-use-which-design-pattern/
https://blog.stackademic.com/adapter-design-pattern-in-ios-9e008ec29414
### 1. Composite Pattern
- Retry logic
- Tree structure handling  
https://medium.com/@stanleytraub/ios-design-patterns-composite-the-coolest-design-pattern-youve-never-heard-of-7037a3a67f5d

### 2. Observer Pattern
- Publisher → Subscriber
- Used in notifications / reactive flows  
https://www.geeksforgeeks.org/system-design/observer-pattern-set-1-introduction/

### 3. Delegate Pattern
- One-to-one communication
- Common in UIKit

---

## 🔹 Core Topics Checklist

### 1. Chaining API Requests
- Combine
- async/await
- Completion handlers
- GCD / OperationQueue

---

### 2. Token Refresh
- async/await (Actor-based)
- Combine pipeline

https://www.donnywals.com/building-a-concurrency-proof-token-refresh-flow-in-combine/
https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/

---

### 4. File Download
https://developer.apple.com/documentation/foundation/downloading-files-in-the-background

---

### 6. Concurrency (GCD)

https://www.freecodecamp.org/news/ios-concurrency/
https://medium.com/@dmytro_chumakov/dispatchsemaphore-in-swift-1b03a90ff94f

---

### 8. Notification System
https://medium.com/better-programming/ios-implementing-a-custom-notification-center-manually-in-the-most-efficient-way-e6b86a4bee80

---

### 9. Testing
https://medium.com/adessoturkey/unit-testing-in-swift-c1607da61e13
https://www.avanderlee.com/swift/unit-tests-best-practices/
https://www.donnywals.com/getting-started-with-unit-testing-on-ios-part-1/

---

### 10. Memory Management
https://www.donnywals.com/using-xcodes-memory-graph-to-find-memory-leaks/
https://www.donnywals.com/finding-slow-code-with-instruments/

---

### 11. Real-time Communication
https://medium.com/@asharsaleem4/long-polling-vs-server-sent-events-vs-websockets-a-comprehensive-guide-fb27c8e610d0

---

### 12. Networking Layer
https://medium.com/icommunity/building-a-generic-network-layer-for-ios-apps-5469d11324f0
https://www.donnywals.com/category/networking/
https://www.donnywals.com/architecting-a-robust-networking-layer-with-protocols/

---

### 13. App Architecture
https://medium.com/@anujiosdeveloper/heres-a-deep-dive-ios-architecture-interview-question-set-ideal-for-mid-to-senior-ios-developers-df24eabf365e

---

### 14. Error Handling
https://www.donnywals.com/error-handling-in-swift-with-do-catch/

---

### 15. Structured Concurrency
https://www.donnywals.com/category/swift-concurrency/

---

### 16. Combine
https://www.donnywals.com/category/combine/
https://medium.com/@lucaspedrazoli/a-handy-list-of-swift-combine-operators-e7b5d640761c

---

## 🔹 SwiftUI
1. iOS 17 Observable 
https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/
https://www.donnywals.com/observable-in-swiftui-explained/

---

## 🔹 Clean Architecture Series
https://www.youtube.com/watch?v=CkylrfKvf1A&list=PLyjgjmI1UzlSWtjAMPOt03L7InkCRlGzb&index=6


## 🔹 Git
1. Three Way Merge 
https://blog.git-init.com/the-magic-of-3-way-merge/

2. Merge vs Rebase 
https://www.atlassian.com/git/tutorials/merging-vs-rebasing
https://www.datacamp.com/blog/git-merge-vs-git-rebase?utm_cid=19589720824&utm_aid=152984013774&utm_campaign=230119_1-ps-other~dsa-tofu~all_2-b2c_3-apac_4-prc_5-na_6-na_7-le_8-pdsh-go_9-nb-e_10-na_11-na&utm_loc=9198695-&utm_mtd=-c&utm_kw=&utm_source=google&utm_medium=paid_search&utm_content=ps-other~apac-en~dsa~tofu~blog~git&gad_source=1&gad_campaignid=19589720824&gbraid=0AAAAADQ9WsE2bl4VvxqNvsh9yrPsbQBdR&gclid=Cj0KCQjwy_fOBhC6ARIsAHKFB79geGDIGhdTY7QBxtTKR_LV6NulXjKRlnSJR3jpr46CNYYn-ofE0FMaAt1lEALw_wcB


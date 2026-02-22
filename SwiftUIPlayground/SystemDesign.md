# System Design Notes

## SOLID Principles

- **Single Responsibility Principle**
- **Open/Close Principle**
- **Liskov Substitution Principle**
  - [SOLID Swift by Examples — Part Three](https://medium.com/better-programming/solid-swift-by-examples-part-three-675672c1ec20)
- **Interface Segregation Principle** — to avoid Liskov Substitution Principle violations
- **Dependency Inversion Principle**
  - Dependency gets inverted with the help of interface
  - Instead of high-level module directly depending on low-level module — both depend on abstraction

---

## Design Patterns
https://www.geeksforgeeks.org/system-design/design-patterns-cheat-sheet-when-to-use-which-design-pattern/

### Composite Pattern

- Can implement retry logic with help of this pattern
- [iOS Design Patterns: Composite](https://medium.com/@stanleytraub/ios-design-patterns-composite-the-coolest-design-pattern-youve-never-heard-of-7037a3a67f5d)

### Observer Pattern
https://www.geeksforgeeks.org/system-design/observer-pattern-set-1-introduction/

### Delegate Pattern

---

## Topics Checklist

### 1. Chaining Multiple API Requests

- a. With the help of Combine
- b. With the help of async/await
- c. Completion handler
- d. Using Grand Central Dispatch or Operation Queue

### 2. Refresh Token

- a. Using async/await
- b. Using Combine

### 3. Photo Upload

- Background Task, Multipart upload, Retry

### 4. Video/PDF Downloader

- Background, Resume

### 5. Analytics

- Event batching

### 6. Dispatch Group Implementation

### 7. NotificationCenter Implementation

### 8. Write Test Cases

### 9. Memory Graph Analysis / ARC

### 10. Websocket / SSE / Polling
https://medium.com/@asharsaleem4/long-polling-vs-server-sent-events-vs-websockets-a-comprehensive-guide-fb27c8e610d0

- Real-time sync

### 11. Generic Networking

### 12. App Diagram Implementation

- Facebook Feed, Download Manager, My Own App, Offline-first app

### 13. App Architecture

- MVC, MVVM, MVI, MVP and TCA (Trade-offs)

### 14. Error Handling

- Retry, Backoff

### 15. Grand Central Dispatch

- Dispatch Semaphore
- Dispatch Group
- DispatchWorkItem
- Async Barrier
- Sync vs Async
- Serial vs Concurrent

**Article:** [iOS Concurrency]
https://www.freecodecamp.org/news/ios-concurrency/
https://medium.com/@dmytro_chumakov/dispatchsemaphore-in-swift-1b03a90ff94f

**NSLock and Actor** 
https://medium.com/@govindaraokondala/from-nslock-to-actors-navigating-swifts-concurrency-tools-for-thread-safety-798534b7a02e

### 16. Structured Concurrency

### 17. Combine

### 18. Operation Queue

### 19. Dispatch Group Usage

### 20. Real-World Problem
File Download
File upload
Offline Video Player
Offline First App


- Used serial queue to serialize the task

---

## Clean Architecture Series

- [YouTube Playlist]
(https://www.youtube.com/watch?v=CkylrfKvf1A&list=PLyjgjmI1UzlSWtjAMPOt03L7InkCRlGzb&index=6)



## Kafka, Webhook
A webhook = another server sending an HTTP request to your server.
Kafka decouples webhook ingestion from processing, enabling fast acknowledgement, durability, and horizontal scaling.

A webhook is when another server automatically sends an HTTP request to your server to notify you about an event. Instead of your app repeatedly asking an API for updates (polling), the external service calls your API endpoint itself when something happens. In a normal API flow, you request data from them (GET → Stripe API), but with a webhook, they send data to you (POST → yourserver.com/webhook). In short: webhook = event notification pushed to your server via HTTP POST.



#Swift UI
## ObservableObject, Combine Subject, ObservedObject, StateObject, State, Binding, Bindable 
    - https://www.avanderlee.com/swiftui/observable-macro-performance-increase-observableobject/
    - https://www.donnywals.com/observable-in-swiftui-explained/
## Animation 
## Common Crashes
## Memory Graph Analysis Xcode

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

### Composite Pattern

- Can implement retry logic with help of this pattern
- [iOS Design Patterns: Composite](https://medium.com/@stanleytraub/ios-design-patterns-composite-the-coolest-design-pattern-youve-never-heard-of-7037a3a67f5d)

### Observer Pattern

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

**Article:** [iOS Concurrency](https://www.freecodecamp.org/news/ios-concurrency/)

### 16. Structured Concurrency

### 17. Combine

### 18. Operation Queue

### 19. Dispatch Group Usage

### 20. Real-World Problem

- Used serial queue to serialize the task

---

## Clean Architecture Series

- [YouTube Playlist](https://www.youtube.com/watch?v=CkylrfKvf1A&list=PLyjgjmI1UzlSWtjAMPOt03L7InkCRlGzb&index=6)

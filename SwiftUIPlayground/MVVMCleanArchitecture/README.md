# MVVM Clean Architecture Example

This folder demonstrates MVVM (Model-View-ViewModel) architecture combined with Clean Architecture principles in SwiftUI.

## Architecture Overview

```
MVVMCleanArchitecture/
├── Domain/              # Business Logic Layer (No dependencies)
│   ├── Entities/        # Core business models
│   ├── UseCases/        # Business rules and operations
│   └── Repositories/    # Repository protocols (interfaces)
│
├── Data/                # Data Layer (Depends on Domain)
│   ├── Repositories/    # Repository implementations
│   └── DataSources/     # API, Database, Cache implementations
│
└── Presentation/        # UI Layer (Depends on Domain)
    ├── ViewModels/      # Presentation logic
    └── Views/           # SwiftUI views
```

## Dependency Flow

```
View → ViewModel → UseCase → Repository (Protocol) ← Repository (Impl) ← DataSource
```

**Key Rule**: Dependencies point inward. Outer layers depend on inner layers, never the reverse.

## Layer Responsibilities

### Domain Layer
- **Entities**: Pure data models representing business concepts
- **Use Cases**: Encapsulate business logic and rules
- **Repository Protocols**: Define contracts for data access (no implementation)

### Data Layer
- **Repository Implementations**: Implement domain repository protocols
- **Data Sources**: Handle actual data fetching (API, Database, Cache, Mock)

### Presentation Layer
- **ViewModels**: Transform domain data for UI, handle user interactions
- **Views**: SwiftUI components that bind to ViewModels

## Benefits

1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Clear separation of concerns
3. **Flexibility**: Easy to swap implementations (e.g., Mock → API)
4. **Scalability**: Add features without affecting other layers
5. **Reusability**: Domain logic is platform-agnostic

## Usage Example

```swift
// 1. Setup dependencies (usually in App or Dependency Injection container)
let dataSource: UserDataSource = MockUserDataSource()
let repository: UserRepository = UserRepositoryImpl(dataSource: dataSource)
let fetchUsersUseCase = FetchUsersUseCase(repository: repository)
let createUserUseCase = CreateUserUseCase(repository: repository)

// 2. Create ViewModel
let viewModel = UserListViewModel(
    fetchUsersUseCase: fetchUsersUseCase,
    createUserUseCase: createUserUseCase
)

// 3. Use in View
UserListView(viewModel: viewModel)
```

## Testing Strategy

- **Domain Layer**: Test Use Cases with mock repositories
- **Data Layer**: Test Repository implementations with mock data sources
- **Presentation Layer**: Test ViewModels with mock use cases

## Next Steps

To use a real API instead of mock data:
1. Create `APIUserDataSource` implementing `UserDataSource`
2. Replace `MockUserDataSource()` with `APIUserDataSource()` in dependency setup
3. No changes needed in Domain or Presentation layers!




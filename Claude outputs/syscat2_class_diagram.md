```mermaid
classDiagram
    %% Core Architecture Layers
    class DomainLayer["🏛️ Domain Layer"]
    class InfrastructureLayer["🔧 Infrastructure Layer"]
    class PresentationLayer["🎨 Presentation Layer"]
    
    %% Assistant Feature
    namespace Assistant {
        class AssistantMessage {
            -String id
            -AssistantMessageRole role
            -String text
            -DateTime createdAt
            -List~AssistantActionSuggestion~ actionSuggestions
            -List~AssistantUrlSource~ urlSources
            +factory AssistantMessage.user()
            +factory AssistantMessage.agent()
        }
        
        class AssistantContext {
            -String currentPage
            -Map~String, dynamic~ metadata
        }
        
        class AssistantActionSuggestion {
            -String actionType
            -String description
            -Map~String, dynamic~ parameters
        }
        
        class AssistantUrlSource {
            -String url
            -String title
            -String excerpt
        }
        
        class AssistantRepository["«abstract»\nAssistantRepository"] {
            ask(context, history, question): Future~AssistantMessage~
        }
        
        class AskAssistant {
            -AssistantRepository repository
            +call(): Future~AssistantMessage~
        }
        
        class AssistantCubit {
            -AskAssistant askAssistant
            +ask(question)
            +clearHistory()
        }
    }
    
    %% Task Builder Feature
    namespace TaskBuilder {
        class Task {
            -String id
            -String name
            -String description
            -List~WorkflowNode~ nodes
            -List~WorkflowEdge~ edges
            -DateTime createdAt
        }
        
        class WorkflowNode {
            -String id
            -String type
            -NodeConfig config
            -Map~String, dynamic~ position
        }
        
        class WorkflowEdge {
            -String id
            -String sourceNodeId
            -String targetNodeId
            -String condition
        }
        
        class NodeConfig["«abstract»\nNodeConfig"] {
            +validate(): bool
        }
        
        class PromptNodeConfig {
            -String prompt
            -List~String~ variables
            -String modelId
        }
        
        class ScriptNodeConfig {
            -String code
            -String language
        }
        
        class HumanApprovalNodeConfig {
            -String approvalText
            -List~String~ assignees
        }
        
        class ForEachNodeConfig {
            -String itemsVariableName
            -String itemVariableName
        }
        
        class SendChannelMessageNodeConfig {
            -String channelId
            -String messageTemplate
        }
        
        class TaskRun {
            -String taskId
            -String executionId
            -List~WorkflowNodeExecution~ nodeExecutions
            -DateTime startedAt
            -DateTime completedAt
        }
    }
    
    %% Settings Feature
    namespace Settings {
        class AIModelSettings {
            -String defaultModelId
            -AIProvider provider
            -APIKey apiKey
            -Map~String, dynamic~ parameters
        }
        
        class AIProvider {
            -String name
            -String apiEndpoint
            -List~String~ supportedModels
        }
        
        class APIKey {
            -String keyId
            -String encryptedValue
            -DateTime createdAt
            -DateTime expiresAt
        }
    }
    
    %% User & Authentication
    namespace Auth {
        class User {
            -String id
            -String email
            -String displayName
            -DateTime createdAt
            -List~String~ roles
        }
        
        class AuthRepository["«abstract»\nAuthRepository"] {
            +signIn(email, password): Future~User~
            +signUp(email, password): Future~User~
            +signOut(): Future~void~
        }
    }
    
    %% Teams Feature
    namespace Teams {
        class Team {
            -String id
            -String name
            -String description
            -List~String~ memberIds
            -DateTime createdAt
        }
        
        class TeamMember {
            -String id
            -String userId
            -String teamId
            -String role
        }
    }
    
    %% Skills Feature
    namespace Skills {
        class Skill {
            -String id
            -String name
            -String description
            -String code
            -List~SkillParameter~ parameters
            -DateTime createdAt
        }
        
        class SkillParameter {
            -String name
            -String type
            -bool required
            -String defaultValue
        }
    }
    
    %% Knowledge Base
    namespace KnowledgeBase {
        class KnowledgeDocument {
            -String id
            -String title
            -String content
            -List~String~ tags
            -DateTime createdAt
            -String ownerId
        }
    }
    
    %% Communication
    namespace Communication {
        class Message {
            -String id
            -String channelId
            -String senderId
            -String text
            -List~String~ attachmentIds
            -DateTime sentAt
        }
        
        class Channel {
            -String id
            -String name
            -String description
            -List~String~ memberIds
            -bool isPrivate
        }
    }
    
    %% Language Models
    namespace LanguageModels {
        class LanguageModel {
            -String id
            -String name
            -String provider
            -String version
            -List~String~ capabilities
        }
    }
    
    %% Relationships
    AssistantMessage --> AssistantActionSuggestion
    AssistantMessage --> AssistantUrlSource
    AssistantRepository --> AssistantMessage
    AssistantRepository --> AssistantContext
    AskAssistant --> AssistantRepository
    AssistantCubit --> AskAssistant
    
    Task --> WorkflowNode
    Task --> WorkflowEdge
    WorkflowNode --> NodeConfig
    PromptNodeConfig --|> NodeConfig
    ScriptNodeConfig --|> NodeConfig
    HumanApprovalNodeConfig --|> NodeConfig
    ForEachNodeConfig --|> NodeConfig
    SendChannelMessageNodeConfig --|> NodeConfig
    TaskRun --> Task
    
    AIModelSettings --> AIProvider
    AIModelSettings --> APIKey
    
    Team --> TeamMember
    TeamMember --> User
    
    Skill --> SkillParameter
    
    Message --> Channel
    Channel --> User
    
    PromptNodeConfig --> LanguageModel
    
    %% Layer Dependencies
    DomainLayer --|> "uses"
    InfrastructureLayer --|> DomainLayer
    PresentationLayer --|> "uses" InfrastructureLayer
```

## Projektstruktur - Übersicht

Das Projekt **syscat2** ist eine Flutter PWA mit **18 Features** und Clean Architecture:

### Features:
1. **Assistant** - KI-gestützter Assistent mit Chat-Funktionalität
2. **Task Builder** - Workflow-basierter Task Designer
3. **Auth** - Authentifizierung & Autorisierung
4. **Settings** - Konfiguration & AI-Modeleinstellungen
5. **Teams** - Team-Management
6. **Skills** - Wiederverwendbare Fähigkeiten
7. **Knowledge Base** - Dokumentenverwaltung
8. **Communication** - Messaging & Channels
9. **Employees** - Mitarbeiterverwaltung
10. **Language Models** - LLM-Integration
11. **Licensing** - Lizenzmanagement
12. **Notifications** - Benachrichtigungen
13. **Schedule** - Zeitplanung
14. **Activity** - Aktivitätsverlauf
15. **Files** - Dateiverwaltung
16. **User** - Benutzerprofil
17. **Licensing** - Lizenzierung
18. **Und weitere...**

### Architektur-Pattern:
```
┌─────────────────────────────────────┐
│   Presentation Layer (Cubits)       │
│   - UI State Management             │
│   - User Interactions               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Infrastructure Layer                │
│  - Repositories                      │
│  - Data Sources                      │
│  - Models                            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer                       │
│   - Entities                         │
│   - Use Cases                        │
│   - Abstract Repositories            │
└─────────────────────────────────────┘
```

### Wichtige Entitäten:
- **AssistantMessage** - Chat-Nachrichten mit Actions & Sources
- **Task** - Workflow mit Nodes und Edges
- **WorkflowNode** - Verschiedene Node-Typen (Prompt, Script, Approval, etc.)
- **User** - Benutzerprofile mit Rollen
- **Team** - Team-Organisation
- **Skill** - Wiederverwendbare Code-Snippets
- **KnowledgeDocument** - Dokumentbase für den Assistant

import base64
import zlib
import urllib.request
import os

def generate_kroki(text, output_file):
    compressed = zlib.compress(text.encode('utf-8'), 9)
    encoded = base64.urlsafe_b64encode(compressed).decode('utf-8')
    url = f"https://kroki.io/mermaid/png/{encoded}"
    urllib.request.urlretrieve(url, output_file)
    print(f"Generated {output_file}")

architecture_diagram = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
graph TD
    classDef server fill:#4a69bd,stroke:#fff,stroke-width:2px,color:#fff,rx:10,ry:10
    classDef sdui fill:#38ada9,stroke:#fff,stroke-width:2px,color:#fff,rx:5,ry:5
    classDef flutter fill:#0a3d62,stroke:#00a8ff,stroke-width:3px,color:#fff,shape:hexagon

    API([Backend API / Service])
    
    subgraph "sdui_core Package"
        Transport[SduiTransport]
        Parser[SduiParser (Isolate)]
        Cache[(SduiCache)]
        Differ{SduiDiffer}
        Registry[SduiWidgetRegistry]
        Actions[SduiActionMiddleware]
    end
    
    UI{{Flutter Native Widget Tree}}
    
    API -->|JSON Payload| Transport
    Transport --> Parser
    Parser <-->|Read / Write| Cache
    Parser --> Differ
    Differ -->|id & version match| Registry
    Registry -->|Render Nodes| UI
    
    UI -.->|User Tap / Interaction| Actions
    Actions -.->|Dispatch Analytics / Fetch| Transport
    
    class API server
    class Transport,Parser,Cache,Differ,Registry,Actions sdui
    class UI flutter
"""

comparison_diagram = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart LR
    classDef legacy fill:#eb2f06,stroke:#fff,stroke-width:2px,color:#fff,rx:10,ry:10
    classDef sdui fill:#78e08f,stroke:#fff,stroke-width:2px,color:#0a3d62,rx:10,ry:10

    subgraph Legacy Native Release
        direction LR
        Code[Native App Code] --> Store[Wait: App Store Review]
        Store --> Dow[Wait: Users Download]
        Dow --> View1((View Updated UI))
    end
    
    subgraph sdui_core Release
        direction LR
        JSON[Server JSON Config] --> Deploy[Deploy API Instantly]
        Deploy --> View2((All Users View Updated UI))
    end

    class Code,Store,Dow legacy
    class JSON,Deploy sdui
"""

generate_kroki(architecture_diagram, "assets/architecture.png")
generate_kroki(comparison_diagram, "assets/comparison.png")

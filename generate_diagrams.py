import subprocess
import tempfile
import os

def generate_kroki(text, output_file):
    """Render a Mermaid diagram to PNG using the local mmdc CLI."""
    with tempfile.NamedTemporaryFile(suffix=".mmd", mode="w", delete=False) as f:
        f.write(text.strip())
        tmp = f.name
    try:
        result = subprocess.run(
            ["mmdc", "-i", tmp, "-o", output_file, "--backgroundColor", "transparent"],
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode == 0:
            print(f"Generated {output_file}")
        else:
            print(f"ERROR generating {output_file}:\n{result.stderr[:400]}")
    finally:
        os.unlink(tmp)

# ---------------------------------------------------------------------------
# 1. Architecture — existing
# ---------------------------------------------------------------------------

architecture_diagram = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
graph TD
    classDef server fill:#4a69bd,stroke:#fff,stroke-width:2px,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,stroke-width:2px,color:#fff
    classDef flutter fill:#0a3d62,stroke:#00a8ff,stroke-width:3px,color:#fff

    API([Backend API])

    subgraph sdui_core
        Transport[SduiTransport]
        Parser[SduiParser isolate]
        Cache[(SduiCache)]
        Differ{SduiDiffer}
        Registry[SduiWidgetRegistry]
        Actions[SduiActionRegistry]
    end

    UI{{Flutter Native Widget Tree}}

    API -->|JSON Payload| Transport
    Transport --> Parser
    Parser <-->|stale-while-revalidate| Cache
    Parser --> Differ
    Differ -->|id + version| Registry
    Registry -->|render| UI
    UI -.->|tap / gesture| Actions
    Actions -.->|dispatch| Transport

    class API server
    class Transport,Parser,Cache,Differ,Registry,Actions sdui
    class UI flutter
"""

# ---------------------------------------------------------------------------
# 2. Comparison — existing
# ---------------------------------------------------------------------------

comparison_diagram = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart LR
    classDef legacy fill:#eb2f06,stroke:#fff,stroke-width:2px,color:#fff
    classDef sdui fill:#78e08f,stroke:#fff,stroke-width:2px,color:#0a3d62

    subgraph Traditional Release
        direction LR
        Code[Code change] --> Build[Build + CI]
        Build --> Review[App Store Review]
        Review --> Wait[Users Download]
        Wait --> View1((UI Updated))
    end

    subgraph sdui_core Release
        direction LR
        JSON[Edit server JSON] --> Deploy[Deploy API]
        Deploy --> View2((All Users See It))
    end

    class Code,Build,Review,Wait legacy
    class JSON,Deploy sdui
"""

# ---------------------------------------------------------------------------
# 3. SduiScreen lifecycle state machine
# ---------------------------------------------------------------------------

lifecycle_diagram = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
stateDiagram-v2
    [*] --> loading: app opens
    loading --> loadingWithCache: cache hit
    loading --> success: fetch ok
    loading --> error: fetch failed, no cache
    loading --> empty: fetch ok, empty tree
    loadingWithCache --> success: fresh fetch ok
    loadingWithCache --> errorWithCache: fetch failed
    success --> refreshing: pull-to-refresh or interval
    refreshing --> success: fetch ok
    refreshing --> errorWithCache: fetch failed
    error --> loading: retry
    errorWithCache --> refreshing: retry
"""

# ---------------------------------------------------------------------------
# 4. E-commerce use case
# ---------------------------------------------------------------------------

usecase_ecommerce = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart TD
    classDef server fill:#4a69bd,stroke:#fff,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef user fill:#e55039,stroke:#fff,color:#fff

    subgraph Backend
        CMS[CMS / Promo Engine]
        UserProfile[User Profile Service]
        Inventory[Inventory Service]
    end

    subgraph sdui_core
        Screen[SduiScreen]
        Differ[SduiDiffer]
        Renderer[SduiRenderer]
    end

    subgraph Flutter App
        HomeUI[Home Feed]
        PDPui[Product Detail]
        CartUI[Cart / Checkout]
    end

    CMS -->|personalised layout JSON| Screen
    UserProfile -->|user segment| CMS
    Inventory -->|stock visible_if| CMS
    Screen --> Differ
    Differ --> Renderer
    Renderer --> HomeUI
    Renderer --> PDPui
    Renderer --> CartUI

    class CMS,UserProfile,Inventory server
    class Screen,Differ,Renderer sdui
    class HomeUI,PDPui,CartUI user
"""

# ---------------------------------------------------------------------------
# 5. A/B testing use case
# ---------------------------------------------------------------------------

usecase_ab_testing = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart LR
    classDef server fill:#4a69bd,stroke:#fff,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef analytics fill:#f39c12,stroke:#fff,color:#fff

    Exp[Experiment Service]
    Exp -->|Variant A JSON| ScreenA[SduiScreen - user group A]
    Exp -->|Variant B JSON| ScreenB[SduiScreen - user group B]
    ScreenA -->|onEvent| Analytics[Analytics]
    ScreenB -->|onEvent| Analytics
    Analytics -->|winner| Exp

    class Exp server
    class ScreenA,ScreenB sdui
    class Analytics analytics
"""

# ---------------------------------------------------------------------------
# 6. Feature flags use case
# ---------------------------------------------------------------------------

usecase_feature_flags = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart TD
    classDef server fill:#4a69bd,stroke:#fff,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef widget fill:#27ae60,stroke:#fff,color:#fff
    classDef hidden fill:#7f8c8d,stroke:#fff,color:#fff

    Flags[Feature Flag Service]
    Flags -->|isSaleActive=true| Layout[JSON Layout]
    Layout -->|props.visible_if| Renderer[SduiRenderer]
    Renderer -->|visible| SaleBanner[Sale Banner widget]
    Renderer -->|hidden - no rebuild| HiddenNode[Hidden Node]

    class Flags server
    class Layout,Renderer sdui
    class SaleBanner widget
    class HiddenNode hidden
"""

# ---------------------------------------------------------------------------
# 7. Bloc integration
# ---------------------------------------------------------------------------

integration_bloc = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart TD
    classDef server fill:#4a69bd,stroke:#fff,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef bloc fill:#8e44ad,stroke:#fff,color:#fff
    classDef flutter fill:#0a3d62,stroke:#00a8ff,color:#fff

    Server[Backend API]
    Server -->|JSON + auth headers| Screen[SduiScreen]

    subgraph BLoC Layer
        AuthBloc[AuthBloc]
        CartBloc[CartBloc]
    end

    subgraph sdui_core
        Screen --> Renderer[SduiRenderer]
        ActionReg[SduiActionRegistry]
    end

    AuthBloc -->|Bearer token header| Screen
    Renderer -->|builds widgets| UI[Flutter UI]
    UI -->|user tap| ActionReg
    ActionReg -->|add_to_cart event| CartBloc
    CartBloc -->|CartUpdated state| UI

    class Server server
    class Screen,Renderer,ActionReg sdui
    class AuthBloc,CartBloc bloc
    class UI flutter
"""

# ---------------------------------------------------------------------------
# 8. State management overview (Provider / Riverpod)
# ---------------------------------------------------------------------------

integration_state_mgmt = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart LR
    classDef provider fill:#27ae60,stroke:#fff,color:#fff
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef server fill:#4a69bd,stroke:#fff,color:#fff

    subgraph Provider or Riverpod
        AuthProv[AuthProvider]
        ThemeProv[ThemeProvider]
        CartProv[CartNotifier]
    end

    subgraph sdui_core
        Scope[SduiScope]
        Screen[SduiScreen]
        ActionReg[SduiActionRegistry]
    end

    Server[Backend]

    AuthProv -->|token header| Screen
    ThemeProv -->|SduiTheme styles| Scope
    Screen -->|fetch layout| Server
    Server -->|JSON| Screen
    ActionReg -->|update_cart| CartProv

    class AuthProv,ThemeProv,CartProv provider
    class Scope,Screen,ActionReg sdui
    class Server server
"""

# ---------------------------------------------------------------------------
# 9. go_router navigation integration
# ---------------------------------------------------------------------------

integration_go_router = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart TD
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef router fill:#e67e22,stroke:#fff,color:#fff
    classDef server fill:#4a69bd,stroke:#fff,color:#fff

    Server[Backend]
    Server -->|JSON with navigate actions| Screen[SduiScreen]

    subgraph sdui_core
        Screen --> ActionReg[SduiActionRegistry]
        ActionReg -->|navigate event| Handler[navigate handler]
    end

    subgraph go_router
        Handler -->|context.go route| Router[GoRouter]
        Router --> RouteA[route home]
        Router --> RouteB[route product id]
        Router --> RouteC[route cart]
    end

    class Screen,ActionReg,Handler sdui
    class Router,RouteA,RouteB,RouteC router
    class Server server
"""

# ---------------------------------------------------------------------------
# 10. get_it / injectable service locator
# ---------------------------------------------------------------------------

integration_get_it = """
%%{init: {'theme': 'dark', 'themeVariables': { 'fontFamily': 'arial', 'background': '#1e1e1e'}}}%%
flowchart LR
    classDef sdui fill:#38ada9,stroke:#fff,color:#fff
    classDef getit fill:#c0392b,stroke:#fff,color:#fff
    classDef server fill:#4a69bd,stroke:#fff,color:#fff

    subgraph get_it service locator
        DioTransport[DioSduiTransport]
        WidgetReg[SduiWidgetRegistry]
        ActionReg[SduiActionRegistry]
    end

    subgraph Flutter App
        SduiScreen1[SduiScreen home]
        SduiScreen2[SduiScreen product]
    end

    DioTransport -->|injected| SduiScreen1
    DioTransport -->|injected| SduiScreen2
    WidgetReg -->|injected| SduiScreen1
    ActionReg -->|injected| SduiScreen2

    class DioTransport,WidgetReg,ActionReg getit
    class SduiScreen1,SduiScreen2 sdui
"""

# ---------------------------------------------------------------------------
# Generate all images
# ---------------------------------------------------------------------------

diagrams = [
    (architecture_diagram,    "assets/architecture.png"),
    (comparison_diagram,      "assets/comparison.png"),
    (lifecycle_diagram,       "assets/lifecycle.png"),
    (usecase_ecommerce,       "assets/usecase_ecommerce.png"),
    (usecase_ab_testing,      "assets/usecase_ab_testing.png"),
    (usecase_feature_flags,   "assets/usecase_feature_flags.png"),
    (integration_bloc,        "assets/integration_bloc.png"),
    (integration_state_mgmt,  "assets/integration_state_mgmt.png"),
    (integration_go_router,   "assets/integration_go_router.png"),
    (integration_get_it,      "assets/integration_get_it.png"),
]

for diagram_text, output_path in diagrams:
    generate_kroki(diagram_text, output_path)

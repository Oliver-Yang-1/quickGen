
**Project Introduction: QuickGen iOS Frontend**

**(Document Updated based on User Feedback)**

**1. Project Overview**

*   **Name:** QuickGen
*   **Concept:** An iOS application enabling users to rapidly generate simple H5 web page code through conversational interaction with an AI Large Language Model (LLM).
*   **Goal:** Provide a tool for quickly creating H5 prototypes or content snippets via natural language prompts.

**2. Target Audience**

*   Individuals or developers needing to quickly generate simple web content or prototypes.
*   Users who may not be proficient in HTML/CSS/JS but can describe their desired outcome.

**3. Core Technology & Architecture**

*   **Frontend:** Native iOS application built with **Swift** and **SwiftUI**.
*   **Backend:** Interaction with a lightweight **Backend for Frontend (BFF)**.
    *   **CRITICAL:** The iOS app **must not** call the LLM API directly. All LLM interactions (sending prompts, receiving code) must go through the BFF. This is for API key security, prompt management, cost control, and flexibility.
*   **Preview:** Use `WKWebView` to render the generated H5 code within the app.

**4. Key Features (MVP)**

*   Create and manage "Workspaces" for different H5 generation projects.
*   Chat interface for users to input natural language descriptions of desired web elements/layouts.
*   "Run" functionality to send prompts to the LLM (via BFF).
*   Display/Preview the LLM-generated H5 code within the app.
*   Basic workspace management (create with name input, open recent, potentially rename/delete).

**5. UI Structure Overview**

The application follows a structure inspired by Pythonista:

*   **Initial Screen:** A welcome/launch screen offering entry points.
*   **Main Interface:** A persistent sidebar (on iPad, **slide-over/toggleable via a slide-from-left animation** on iPhone) for navigating workspaces and accessing core sections, alongside a main content area displaying the active workspace or other selected content.

**6. Detailed Screen Descriptions**

**Screen 1: Initial Welcome Screen** (Based on Pythonista Image 1 Structure, but for entry points)

*   **Purpose:** Provides the initial entry points for the user.
*   **Layout:** Centered options on a clean background.
*   **Top Bar:**
    *   Left: Hamburger Menu icon (Toggles the sidebar, **sliding out from the left** if applicable on this screen, maintain consistency).
    *   Center: App Title "QuickGen".
    *   Right: Settings icon (Gear).
*   **Main Content (Centered Buttons/Links):**
    *   `[+] New Workspace...` (Primary Action, Blue Button): **Presents a modal dialog prompting the user to enter a name (similar input style to the provided Pythonista Image 1 for file naming).** Upon confirmation, creates a new workspace with that name and navigates to it.
    *   `Open Recent Workspace...` (Secondary Action, Outlined Button): Shows a list/modal of recently accessed workspaces.
    *   `Documentation` (Link/Tertiary Button): Opens help guides.
    *   `Community Forum` (Link/Tertiary Button - Optional): Link to support forum if available.
    *   `Release Notes` (Link/Tertiary Button - Optional): Link to version history.

**Screen 2: Main Application View - Sidebar** (Based on Pythonista Image 2 Structure)

*   **Purpose:** Primary navigation for workspaces and app sections.
*   **Layout:** A list-based sidebar. **This sidebar should slide in from the left when revealed and slide back when hidden.**
*   **Top:** Search Bar (Placeholder: "Search Workspaces").
*   **Sections:**
    *   **`WORKSPACES`**
        *   `[+] New Workspace` (Button/Row): Quick access to create a new workspace. **Presents the same name input modal dialog as the Welcome Screen button.** Creates the workspace and makes it active.
        *   `On My Device` (or similar): Lists locally saved user workspaces. Each row shows the workspace name. Tapping navigates to that Workspace View in the content area.
        *   `(Future)` `iCloud`: For potential cloud-synced workspaces.
    *   **`FAVORITES`**
        *   Lists workspaces marked as favorites by the user.
    *   **`EXAMPLES`**
        *   Pre-defined example workspaces demonstrating prompt techniques and results. Read-only.
    *   **`OTHER`**
        *   `Documentation`
        *   `Trash` (Deleted workspaces)
*   **Bottom Bar (within Sidebar):**
    *   Left: `+` Icon (Quick "New Workspace"): **Presents the same name input modal dialog.** Creates the workspace and makes it active.
    *   Right: `Settings` Icon (Gear).

**Screen 3: Main Application View - Content Area (Workspace View)** (Layout based on the provided Pythonista editor image)

*   **Purpose:** The primary interaction area where the user chats with the AI, runs generation, and previews the H5 output for a specific workspace.
*   **Layout:** Mimics the structure of the Pythonista code editor screen *when a workspace is active*.
*   **Top Bar:**
    *   Left: Hamburger Menu icon (**Toggles the Sidebar, animating it sliding out from the left when appearing and sliding back when dismissed**).
    *   Center: **Workspace Name** (e.g., "My Landing Page"). Tapping might allow renaming (potentially via the 'More Actions' menu).
    *   Right: Action Icons:
        *   `Run` (Play icon): Sends the current input text to the BFF/LLM. Should provide visual feedback during processing (e.g., loading indicator).
        *   `Preview` (Eye icon): Switches the main content area to Preview Mode. Icon might toggle state (e.g., Eye / Code icon) depending on the current mode.
        *   `(Optional)` `More Actions` (...): Menu for Rename, Add to Favorites, Export Chat/Code, Delete Workspace.
*   **Main Content Area:** This area dynamically switches between two modes:
    *   **a) Chat Mode:**
        *   Displays a scrollable history of the conversation.
        *   User prompts and AI responses (or confirmation messages) should be clearly distinguishable (e.g., alignment, background color).
        *   **Bottom Input Toolbar:** Contains a text input field ("Describe your webpage...") and potentially the `Run` button could be placed here instead of the top bar for easier access, especially on iPhone. *Developer decision based on usability.*
    *   **b) Preview Mode:**
        *   Replaces the chat history view.
        *   Contains a `WKWebView` instance that renders the *latest* H5 code generated for this workspace.
        *   May include helper buttons like `Copy Code` (Copies the raw H5 source) or `Export .h5` (Shares/saves the code as an HTML file) within this mode's view or integrated into the top bar actions.

**Screen 4: Settings**

*   **Purpose:** Configure application settings.
*   **Layout:** Standard iOS settings list.
*   **Potential Options (MVP):**
    *   Appearance (Light/Dark/System)
    *   Link to Documentation
    *   About / Version Info
    *   (Future: API Key Management if exposing different models, default export settings, etc.)

**7. Core User Flows (MVP)**

*   **Creating a New Workspace:**
    1.  User taps `[+] New Workspace...` (Welcome Screen) or `+` / `[+] New Workspace` (Sidebar).
    2.  **App presents a modal dialog prompting for the 'Workspace Name'.** This dialog should feature a text input field (pre-filled potentially with "Untitled Workspace" or empty) and 'Create'/'Confirm' and 'Cancel' buttons (style inspired by Pythonista's file creation prompt - see referenced Image 1).
    3.  User enters a desired name (e.g., "My First Page") and taps 'Create'.
    4.  App creates the new workspace using the provided name.
    5.  App navigates to the Workspace View for this new workspace.
    6.  Sidebar updates to show the new workspace (with its name) under `WORKSPACES`.
    7.  Content Area displays the empty Chat Mode, with the workspace's name shown in the top bar.
*   **Generating H5:**
    1.  User is in the Workspace View (Chat Mode).
    2.  User types a prompt (e.g., "Create a blue button that says 'Click Me'").
    3.  User taps `Run`.
    4.  App sends prompt to BFF -> LLM -> BFF -> App.
    5.  App receives H5 code. Chat history updates (e.g., with confirmation).
*   **Previewing H5:**
    1.  User is in the Workspace View (Chat Mode or after generation).
    2.  User taps `Preview`.
    3.  Content Area switches to Preview Mode, rendering the H5 in the WKWebView.
    4.  User can interact with the preview (if applicable) or use Copy/Export actions.
    5.  User taps `Back`/`Chat` (or the toggled Preview icon) to return to Chat Mode.
*   **Opening Existing Workspace:**
    1.  User taps a workspace name in the Sidebar (`WORKSPACES` or `FAVORITES`).
    2.  Content Area loads that workspace's chat history and latest generated code (ready for Preview).
*   **Toggling Sidebar:**
    1.  User is in the Main Application View (Workspace View active).
    2.  User taps the Hamburger Menu icon in the top-left corner.
    3.  The Sidebar animates, **sliding out from the left edge** of the screen. The main content area might dim or slightly shift right depending on the chosen implementation (especially on iPad).
    4.  User interacts with the Sidebar (e.g., selects another workspace).
    5.  Tapping the Hamburger Menu icon again (or potentially tapping outside the sidebar on iPad) causes the Sidebar to **slide back off-screen to the left**.

**8. Visual Style Guide**

*   Clean, native iOS look and feel using standard SwiftUI components where possible.
*   Use clear visual hierarchy.
*   Borrow structural and layout cues from the provided Pythonista screenshots but adapt controls and content for QuickGen's specific purpose (Chat/Preview vs. Code Editor).
*   Ensure clear distinction between user input and AI responses in the chat view.
*   **Implement standard iOS sidebar slide-in/out animations.**
*   **Design the 'New Workspace' name input dialog to be clear and simple, consistent with iOS modal patterns (inspired by the reference image).**

**9. Postponed / Non-MVP Features**

*   Direct drawing input / Multimodal LLM interaction.
*   Advanced code editing features within the app.
*   iCloud syncing (Consider designing data models with syncing in mind for the future).
*   Complex project/file management within a workspace (MVP workspace = single chat/H5 output).

**10. Key Considerations for Frontend Development**

*   **State Management:** Carefully manage the state between Chat Mode and Preview Mode within the Workspace View. Ensure the correct H5 code is displayed upon switching to Preview. Manage the state of the sidebar (visible/hidden).
*   **BFF Interaction:** Implement robust handling of network requests to the BFF, including loading states and error handling. Remember, *no direct LLM calls*.
*   **WKWebView:** Handle communication and potential issues with rendering diverse H5 content within the WebView.
*   **SwiftUI Implementation:** Leverage SwiftUI's declarative nature for building the UI components and managing data flow. Pay attention to performance with potentially long chat histories. Use appropriate SwiftUI containers and transitions for the **sliding sidebar animation**. Implement the **modal presentation for the workspace name input**.
*   **Adaptability:** Design for both iPhone and iPad layouts, particularly the **sidebar behavior (slide-over vs. persistent/split-view style on larger iPads)**.
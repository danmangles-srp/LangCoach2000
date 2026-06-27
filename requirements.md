# requirements.md

## 1. Functional Requirements

### 1.1 Audio Management & System Integration
* **FR-1.1.1:** The system must scan the local filesystem for specified directories on initialization and dynamically index audio formats (`.m4a`, `.mp3`, `.wav`).
* **FR-1.1.2:** The app must integrate with the native Android file management API to pull metadata (creation date, name, file size) from files created by external applications like Samsung Voice Recorder.
* **FR-1.1.3:** In-app audio recorder must save files directly to the globally targeted Samsung storage directory to maintain a unified audio pool.
* **FR-1.1.4:** The internal audio player must support background playback and audio focus management (pausing when phone calls are received).

### 1.2 GPA Spaced-Repetition Scheduler
* **FR-1.2.1:** Every indexed recording must possess a custom evaluation timeline calculated from its creation date stamp.
* **FR-1.2.2:** The calculation engine must evaluate the review status based on day-intervals: $D+1, D+2, D+4, D+7, D+30, D+90, D+180, D+365$.
* **FR-1.2.3:** A recording is flagged as "Reviewed" for its active milestone once it has been played past $80\%$ of its total duration.

### 1.3 Vocabulary & Flashcard Automation
* **FR-1.3.1:** Users must be able to link text formatting (English definition - Uzbek word) or raw device images (JPG/PNG files of notebook logs) directly to an audio file record.
* **FR-1.3.2:** Text parsing engine must automatically extract words from text logs via delimiter maps (e.g., lines containing `:` or `-`) to feed card generation.
* **FR-1.3.3:** The app must output flashcard updates to AnkiDroid via a native API or local database sync using the recording filename as a tracking tag.
* **FR-1.3.4:** An imaging pipeline must dynamically assign an explicit concept graphic to newly generated vocab items using an integrated image generation endpoint when online.

### 1.4 Task Tracking & Coaching Utilities
* **FR-1.4.1:** The app must feature a dedicated tasks engine supporting custom titles, descriptions, due dates, and completion status flags.
* **FR-1.4.2:** The application must push local system alarms to the device OS to alert users to pending language drills or deadlines.
* **FR-1.4.3:** The system must provide a dedicated repository to store structured text scripts or map existing media files into a structured agenda for live coaching reviews.

### 1.5 Analytics & Automated Email Delivery
* **FR-1.5.1:** The app must log user engagement metrics across granular metrics: Lesson Duration, Journaling Output (calculated by text log entries), Completed Queue items, and Flashcards reviewed.
* **FR-1.5.2:** Data visualization components must render native graphical charts depicting metric tracking against target weekly milestones.
* **FR-1.5.3:** A background reporting engine must aggregate the weekly metrics and dispatch a custom-styled vector or HTML data report directly to the user's email address.

---

## 2. Non-Functional Requirements

### 2.1 Offline Architecture (Offline-First)
* **NFR-2.1.1:** All core processing engines—including file indexing, queue scheduling, task tracking, and playback logs—must execute without an active internet connection.
* **NFR-2.1.2:** Database synchronization must rely entirely on a local relational sandbox (SQLite/Room).
* **NFR-2.1.3:** Features requiring external connectivity (e.g., AI image generation, report email dispatches) must queue background tasks and execute automatically upon network restoration.

### 2.2 Performance & Scalability
* **NFR-2.2.1:** File system indexing operations must evaluate up to 1,000 files in under 2.0 seconds without causing frame drops or blocking main UI rendering thread operations.
* **NFR-2.2.2:** Audio playback latency from UI touch trigger to hardware output must not exceed 250 milliseconds.

### 2.3 Architectural Portability
* **NFR-2.3.1:** The application core should decouple data layers from UI frameworks to allow future compilation targeting iOS with minimal core logic modification (e.g., choosing Kotlin Multiplatform or highly modular Flutter/React Native plugins).

### 2.4 User Experience, Aesthetics & Trust
* **NFR-2.4.1:** The app interface must reflect a bespoke luxury tier, featuring clean micro-interactions, cohesive dark/light typography scales, and absolute absence of unhandled error states.
* [cite_start]**NFR-2.4.2:** Given the sensitive, personal nature of deep cultural sharing sessions, all text logs and captured conversations must be securely processed locally, establishing strict sandboxed privacy constraints[cite: 310].
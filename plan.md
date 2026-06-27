# plan.md

## Milestone 1: Core Audio Sync & Native Playback (The Baseline)
**Objective:** Establish the foundation of the app by indexing and playing existing local recordings with zero fluff.

### User Stories
* **As a learner,** I want the app to scan my Android device for my Samsung Voice Recorder folder on initial launch so that I don't have to manually import my historical audio files.
* **As a learner,** I want a clean, premium interface displaying all indexed recordings so that I can see my target-language audio library at a glance.
* **As a learner,** I want to tap and play any recording instantly from within the app using standard audio controls (play, pause, seek).

### Acceptance Criteria
* On first install, the user is prompted with a native folder picker to select or confirm their Samsung Voice Recorder path.
* The app automatically indexes all `.m4a`/`.mp3`/`.wav` files in the designated directory without freezing the UI.
* Audio playback works flawlessly offline with native media session controls.
* UI matches premium visual standards (modern typography, high contrast, smooth transitions).

---

## Milestone 2: GPA Spaced-Repetition Scheduler & In-App Capturing
**Objective:** Transform static audio tracking into the structured Growing Participator Approach (GPA) review pipeline.

### User Stories
* [cite_start]**As a learner,** I want the app to automatically place recordings into a daily "Due for Review" list based on a strict interval sequence (1, 2, 4, 7, 30, 90, 180, 365 days after creation) so that I stay on top of my listening library[cite: 165].
* **As a learner,** I want to trigger a new audio recording directly within the app that automatically saves into the shared Samsung Voice Recorder folder so that it is instantly indexed.

### Acceptance Criteria
* The home screen displays a dynamic "Today's Review Queue" based on file creation dates and the GPA interval logic.
* Todays recordings can be ticked off. Recordings that are 1 day stale are presented and marked as such, but the prompt goes away on the 2nd day.
* Recordings in review queue can be listened to with 1 tap
* An interactive "Record" button captures audio in-app and exports it as a standard audio file to the indexed folder.
* Startup scans automatically update the database with any newly found external or internal recordings.

---

## Milestone 3: Languaculture Word Log & Visual Attachments
[cite_start]**Objective:** Allow users to bridge audio with explicit vocabulary data and visual media, matching the GPA "Word Log" concept[cite: 145].

### User Stories
* **As a learner,** I want to attach either a raw text list or a photo/image file of my vocabulary sheet to a specific recording.
* **As a learner,** I want the associated text or image vocabulary log to display side-by-side or contextually on-screen whenever that recording is playing.

### Acceptance Criteria
* The app media player dynamically displays a toggle panel showing either the associated text log or the uploaded photo.
* Media mapping persists entirely offline via a local SQLite/Room database.
* Data schema links one text file and/or multiple image files to a single audio recording record.

---

## Milestone 4: Offline-First Automated Anki Generation & AI Engine
**Objective:** Leverage local or lightweight integrations to push vocabulary to Anki and generate intuitive visual learning cards.

### User Stories
* **As a learner,** I want the app to scan my text-based vocabulary list, extract English/Uzbek pairs, and automatically inject them into my Anki app via a localized deck tagged with the recording name.
* **As a learner,** I want each card to feature both a direct translation card and a separate AI-generated image card representing the Uzbek word to encourage immersion.

### Acceptance Criteria
* Saving a text vocab list auto-generates flashcards in Anki via AnkiConnect (Android intent API) with custom tags matching the recording filename.
* Flashcard layout includes: Type 1 (English text <-> Uzbek text) and Type 2 (AI-Generated Concept Image -> Uzbek text).
* Image generation is skipped when internet connection is not available.

---

## Milestone 5: Task Management, Coaching Repository & Notifications
[cite_start]**Objective:** Equip the user with an actionable dashboard to manage custom learning targets and facilitate sessions with their language coach[cite: 562].

### User Stories
* **As a learner,** I want to create custom exercises (e.g., "Memorize folk song 'Yor-Yor'") with hard deadlines and receive native Android push notifications when they are due.
* **As a learner,** I want to maintain a structured bank of conversation topics, questions, and cultural scripts to maximize efficiency during live coaching sessions.

### Acceptance Criteria
* A dedicated "Exercises & Tasks" view allows creation, due date setting, and standard checkbox task completion.
* Local notifications trigger accurately on the designated due dates even when the app is completely closed.
* A "Coach Bank" repository lets users save text notes and link existing recordings or vocabulary words as talking points for upcoming live sessions.

---

## Milestone 6: Analytics Dashboard & Automated Graphic Reports
**Objective:** Deliver a highly aesthetic summary of user consistency to reinforce the premium app experience.

### User Stories
* **As a learner,** I want to see a beautifully visualized performance dashboard displaying key metrics: total lesson hours, journaling minutes, recording reviews completed, and flashcards cleared.
* **As a learner,** I want to receive an automated, visually striking weekly summary email detailing my learning trajectory.

### Acceptance Criteria
* The statistics view renders native vector charts tracking daily, weekly, and monthly activity metrics.
* Performance counters increment seamlessly behind the scenes based on user interaction (e.g., listening to a due recording adds to "Recording Reviews").
* A local service or offline hook dispatches a stylized HTML email report at the end of every week utilizing a premium graphic layout.
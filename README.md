# Focus Spots

> Focus smart at your favourite study places.

Focus Spots is an iOS-first Flutter app that makes focused study time visible and measurable, tied to the real places where you study. You save your study spots, start a focus session at one of them, and the app uses the phone's accelerometer to count how often you pick up your phone. Over the weeks you see how much you actually studied, how often you got distracted, and how you rank against others on a weekly leaderboard.

Developed as part of **KV Mobile Computing**, JKU Linz, winter semester 2026W.

---

## Motivation

Students constantly pick up their phones while studying, often without noticing. They lose focus and can't tell how productive they really were. At the end of a day in the library, you often have no idea how much you studied.

Focus Spots aims to answer that: it recognises where you study and shows you how often you got distracted.

## Features

| Feature | Description |
|---|---|
| **Study spots** | Save the places where you like to study, e.g. library, campus, desk at home. |
| **Pick your spot** | Open the app, choose where you are studying and start a session. |
| **Focus sessions** | A clearly visible timer while a session is running. |
| **Distraction tracking** | Detects when you pick up your phone during a session. |
| **Progress** | Focus time and distractions per session and over the weeks. |
| **Leaderboard** | Compare your weekly focus time in a ranking. |

**Our angle:** real study locations + sensor-based distraction tracking + a leaderboard.

## Technical overview

The system has two parts: the iPhone app, where sensors and logic run, and a cloud backend that only stores and syncs data.

### Sensors

- **Location (GPS + Wi-Fi positioning)** – recognises study spots. Wi-Fi positioning matters because many spots (e.g. the library) are indoors, where GPS alone is inaccurate.
- **Accelerometer** – detects phone pickups. While the phone lies on the table it only measures gravity; when it is picked up, the values change and a pickup is counted.

Since the app is built with Flutter rather than natively, sensors are accessed through Flutter plugins, which talk to Apple's **Core Location** and **Core Motion** frameworks.

### App (Flutter, iOS)

- User interface
- Session logic (timer, pickup counting)
- Local database on the phone (e.g. SQLite), so sessions are saved even without an internet connection

### Backend

- **Firebase Authentication** – user accounts
- **Cloud Firestore** – session history and weekly statistics
- Connection over HTTPS via Wi-Fi or cellular network

```
┌─────────────────────────── iPhone ───────────────────────────┐
│  GPS + Wi-Fi positioning        Accelerometer                 │
│        │  (Core Location)             │  (Core Motion)        │
│        └──────────── Flutter plugins ─┘                       │
│                         │                                     │
│              Flutter app: UI · session logic                  │
│                         │                                     │
│              Local database (SQLite, offline)                 │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTPS (Wi-Fi / cellular)
┌─────────────────────────┴──────── Cloud ─────────────────────┐
│   Firebase Authentication       Cloud Firestore               │
│   (accounts)                    (sessions, weekly stats)      │
└──────────────────────────────────────────────────────────────┘
```

## Tech stack

| | |
|---|---|
| **Framework** | Flutter (Dart) |
| **Platform** | Mainly iOS, tested on our own iPhones; Android possible later from the same code |
| **Hardware** | iPhone with built-in GPS and accelerometer (no extra hardware needed) |
| **Devices** | iPhone 17, MacBook, Windows PC |
| **Dev tools** | VS Code, Flutter SDK, GitHub, Mac with Xcode (required for iOS builds) |
| **Backend** | Firebase (Authentication, Cloud Firestore) |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- macOS with Xcode (Apple only allows iOS apps to be built with Xcode)
- An iPhone for testing (sensors don't work properly in the simulator)
- A Firebase project

### Setup

```bash
git clone <repository-url>
cd focus_spots
flutter pub get
```

Firebase configuration: add your own `GoogleService-Info.plist` to `ios/Runner/` (not committed to the repository).

### Run on an iPhone

```bash
open ios/Runner.xcworkspace   # set your team for code signing once
flutter run
```

Location and motion access require the usage descriptions in `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`, `NSMotionUsageDescription`).

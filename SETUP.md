# TimeControl – Setup Guide

## Prerequisites
- Xcode 15+
- iOS 16+ deployment target
- Apple Developer account (paid, for FamilyControls entitlement)
- Firebase project

---

## 1. Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **App** (iOS)
3. Product Name: `TimeControl`
4. Bundle ID: `com.yourname.timecontrol` *(use your own reverse-domain)*
5. Language: **Swift**, Interface: **SwiftUI**
6. Save inside this repository folder

---

## 2. Add App Extensions (3 targets)

For each extension: **File → New → Target**

| Extension Name | Template |
|---|---|
| `DeviceActivityMonitorExtension` | **Device Activity Monitor Extension** |
| `ShieldConfigurationExtension` | **Shield Configuration Extension** |
| `DeviceActivityReportExtension` | **Device Activity Report Extension** |

After creating each, **replace the generated stub** with the `.swift` file in the matching folder.

---

## 3. Add Swift Package Dependencies

**File → Add Package Dependencies**, add:

| Package URL | Products to add |
|---|---|
| `https://github.com/firebase/firebase-ios-sdk` | FirebaseAuth, FirebaseFirestore, FirebaseFirestoreSwift |
| `https://github.com/google/GoogleSignIn-iOS` | GoogleSignIn, GoogleSignInSwift |

---

## 4. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add an **iOS app** with your bundle ID
4. Download `GoogleService-Info.plist` and **replace** `TimeControl/Resources/GoogleService-Info.plist`
5. Enable **Authentication** → Sign-in methods: **Email/Password** + **Google**
6. Enable **Firestore Database** (start in test mode, then add rules below)

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    match /usernames/{username} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }

    match /friendRequests/{reqId} {
      allow read: if request.auth.uid == resource.data.fromUserId
                  || request.auth.uid == resource.data.toUserId;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.toUserId;
    }

    match /screenTimeRequests/{reqId} {
      allow read: if request.auth.uid == resource.data.fromUserId
                  || request.auth.uid == resource.data.toUserId;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.toUserId;
    }
  }
}
```

---

## 5. Google Sign-In URL Scheme

1. In `GoogleService-Info.plist`, find the value of `REVERSED_CLIENT_ID`
2. In Xcode: Select the `TimeControl` target → **Info** tab → **URL Types**
3. Add a new URL Type with that reversed client ID as the scheme

---

## 6. App Group (for sharing data with extensions)

1. In Xcode: Select the `TimeControl` target → **Signing & Capabilities**
2. Add **App Groups** capability
3. Add group: `group.com.timecontrol.shared`
4. Repeat for **all 3 extensions**

---

## 7. FamilyControls Entitlement

1. Add **Family Controls** capability to the main target in Xcode
2. For **TestFlight / App Store distribution**, apply for the entitlement:
   - [https://developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
3. During development, the entitlement works on a physical device with your dev team.

---

## 8. Add Source Files

Drag all `.swift` files from this repository into their matching Xcode groups:

```
TimeControl/App/          → TimeControlApp.swift, ContentView.swift
TimeControl/Models/       → AppUser.swift, FriendModels.swift, ScreenTimeModels.swift
TimeControl/Services/     → AuthService.swift, FirestoreService.swift, ScreenTimeService.swift
TimeControl/ViewModels/   → AuthViewModel.swift, FriendsViewModel.swift, LeaderboardViewModel.swift, ScreenTimeViewModel.swift
TimeControl/Views/...     → All view files
TimeControl/Extensions/   → Color+Theme.swift
TimeControl/Resources/    → Info.plist, TimeControl.entitlements, GoogleService-Info.plist (yours)

DeviceActivityMonitorExtension/   → DeviceActivityMonitorExtension.swift
ShieldConfigurationExtension/     → ShieldConfigurationExtension.swift
DeviceActivityReportExtension/    → DeviceActivityReportExtension.swift
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Main App                         │
│                                                     │
│  Auth (Firebase + Google) ──► Firestore             │
│  ScreenTimeService ──► FamilyControls API           │
│  FriendsViewModel ──► Firestore friend graph        │
│  LeaderboardVM ──► Firestore sorted by screen time  │
└────────────────┬────────────────────────────────────┘
                 │ App Group (shared UserDefaults)
     ┌───────────┼───────────────┐
     ▼           ▼               ▼
DeviceActivity  Shield    DeviceActivityReport
Monitor Ext.    Config.   Extension (writes
(threshold)     Ext.      daily total → shared)
```

## Key Features

| Feature | Implementation |
|---|---|
| Screen time reading | `DeviceActivityReport` extension writes to App Group |
| App limits | `ManagedSettings` shield + `DeviceActivity` schedule |
| Friends | Firestore `users` + `friendRequests` collections |
| @ username search | Firestore query on `username` field |
| Screen time requests | Firestore `screenTimeRequests` collection |
| Leaderboard | Firestore query on `friendIds`, sorted by `totalScreenTimeToday` |
| Google Sign-In | Firebase Auth + GoogleSignIn SDK |
| Email/Password | Firebase Auth |

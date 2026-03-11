# NileAssist - Facility Maintenance Management System

## Overview
NileAssist is a comprehensive, ticket-based facility maintenance management system built with Flutter and Firebase. It streamlines the process of reporting, assigning, tracking, and resolving facility-related issues (complaints). The system provides a unified platform for various stakeholders, ensuring efficient communication, accountability, and quick resolution of maintenance tasks.

## Key Features & What the System Does
- **Role-Based Access Control:** Secure, tailored experiences and dashboards for Admins, Facility Managers, Maintenance Supervisors, Maintenance Staff, and general Users (requesters).
- **Ticket / Complaint Management:** Users can easily submit maintenance requests with detailed diagnostic information and attachments.
- **Real-Time Chat Context:** Integrated chat functionality linked directly to specific tickets, allowing seamless communication between assignees, supervisors, and requesters.
- **Push Notifications:** Real-time updates on ticket status changes, new chat messages, and system alerts using Firebase Cloud Messaging.
- **Profile Management:** Users can manage their profiles, upload profile pictures, and maintain their contact information seamlessly.

## System Architecture

NileAssist follows a modern serverless architecture utilizing **Flutter** for the cross-platform client application and **Google Firebase** as the powerful backend-as-a-service (BaaS).

### Frontend (Client-Side)
- **Framework:** Flutter (Dart) allowing cross-platform deployment.
- **State Management & Async UI:** Utilizes `StreamBuilder` and `FutureBuilder` extensively for real-time reactivity to authentication states and remote database changes.
- **Routing:** Global navigator keys allow handling background notification routing directly to deep-linked screens (e.g., opening a specific chat detail directly from a push notification).

### Backend (Firebase Services)
- **Firebase Authentication:** Handles secure user login, registration, password resets, and email verification.
- **Cloud Firestore:** A NoSQL real-time document database storing structured data such as user profiles grouped by collections (e.g., `maintenance`, `maintenance_supervisors`), complaints/tickets, and chat messages.
- **Firebase Storage:** Stores unstructured heavy media files, primarily profile pictures and ticket attachments.
- **Firebase Cloud Messaging (FCM):** Delivers reliable, cross-platform push notifications to user devices in real-time.

## Project Structure & Modules

The application is cleanly modularized within the `lib/` directory:

### 1. Models (`lib/models/`)
Contains data structures and entity representations bridging UI data and backend schema.
- example: `admin.dart` representing administrative user privileges.

### 2. Screens (`lib/screens/`)
Contains the UI layer and individual views for the core user experiences.
- **Authentication:** `login.dart`, `gstarted.dart`, `forgot_password.dart`, `verify_email_screen.dart`
- **Dashboards (Role-Specific):** `mainLayout.dart` (dynamic entry), `staffDashboard.dart`, `facilitymanager.dart`, `maintenance_supervisor.dart`, `maintenance.dart`, `admin.dart`
- **Complaints & Issues:** `complaint_screen.dart`, `complaint_form.dart`, `complaintDetail.dart`
- **Communication:** `chat.dart`, `chat_detail.dart`
- **User Settings:** `profile_screen.dart`, `uploadProfilePicture.dart`

### 3. Services (`lib/services/` & `lib/auth/`)
Handles heavy background processes, database transactions, API calls, and third-party integrations.
- **`auth_service.dart`**: Modularized authentication flows.
- **`complaint_services.dart`**: Core CRUD operations and business logic for managing, updating, and assigning tickets.
- **`notification_service.dart`**: Configures and handles both local tracking and FCM push notifications.

### 4. Widgets (`lib/widgets/`)
Contains reusable standalone internal UI components utilized across multiple screens (e.g., custom buttons, interactive cards, input fields) preventing code duplication.

## Entity Relationships

- **User -> Role:** A generic User possesses exactly one designated role capability (Admin, Facility Manager, Supervisor, Staff, or Requester).
- **Requester -> Complaint:** A User can open multiple Complaints over time.
- **Complaint -> Assignee:** A Complaint ticket can be assigned dynamically to Maintenance Supervisor(s) or Staff depending on the required tier of support.
- **Complaint -> Chat Thread:** Each Complaint spins up an associated 1-to-1 or group chat document collection for contextual, in-thread communication.
- **User -> Profile Attributes:** A User profile maps strictly to visual attributes like profile pictures stored physically in Firebase Storage.

## Getting Started

### Prerequisites
- Flutter SDK (`^3.10.4`)
- Dart SDK
- Active Firebase Project Configuration

### Setup Instructions
1. Clone the repository.
2. Run `flutter pub get` in the root directory to install all dependencies specified in `pubspec.yaml`.
3. Ensure you have proper Firebase configuration files correctly placed.
4. Run the app using `flutter run` on your preferred emulator or physical test device.

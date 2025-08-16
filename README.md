# JobDone

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-ffca28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Magableh88/job_done)](https://github.com/Magableh88/job_done/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Magableh88/job_done)](https://github.com/Magableh88/job_done/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Magableh88/job_done/pulls)

## Introduction

**JobDone** is a dynamic, user-driven marketplace where customers post jobs and service providers (fixers) offer to complete them. It connects everyday people with skilled problem-solvers to get tasks done quickly and efficiently.

## Demo

[🎥 Watch Demo Video](link-to-video)

## Features

- Post jobs with detailed descriptions and photos
- Browse offers from fixers and accept the best fit
- Real-time in-app chat between customers and fixers
- Role-based dashboards for customers and fixers
- Ratings and reviews after job completion
- Document verification for fixers
- View jobs on a map using Google Maps
- Secure storage for job images and documents

## Target Audience

### Consumers (Customers)
- Create and manage job requests
- Review offers and communicate with fixers
- Track job progress and leave ratings

### Service Providers (Fixers)
- Browse available jobs and submit offers
- Chat with customers to clarify details
- Manage profile, verification documents, and job history

## Tech Stack

- **Flutter (Dart)**
- **Firebase Authentication, Firestore, Storage**
- **Google Maps API**

## Project Structure

```
/lib
  /models          -> Job, Offer models
  /controllers     -> JobService, OfferService, StorageService, ChatService
  /views           -> AddJobView, JobListView, FixerJobListView, FixerMapView,
                      FixerProfileView, Chat, Registration/Login, etc.
  main.dart        -> Firebase initialization and AuthGate
```

## Key Models & Controllers

- **Job Model** – captures job details such as title, description, location, and status.
- **Offer Model** – represents fixer bids including price, timeline, and messages.
- **JobService** – handles job creation, updates, and retrieval from Firestore.
- **OfferService** – manages offers tied to jobs and fixer responses.
- **StorageService** – uploads and retrieves images or verification documents.
- **ChatService** – real-time messaging between customers and fixers.

## Firebase Integration

- **Authentication** – separate flows for customers and fixers.
- **Firestore** – stores jobs, users, offers, and chat messages.
- **Storage** – saves job images and verification documents.
- **Initialization** – all Firebase services initialized in `main.dart`.

## Installation & Setup

1. **Clone repo**
   ```bash
   git clone https://github.com/Magableh88/job_done.git
   cd job_done
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
4. **Run app**
   ```bash
   flutter run
   ```

## Contributing

Contributions are welcome! Please open an issue to discuss your idea or submit a pull request with improvements. Ensure your PR follows the project's code style and includes relevant tests or documentation.

## License

This project is released under the [MIT License](LICENSE).


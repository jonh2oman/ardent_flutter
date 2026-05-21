# RCSCC Training Plan & Management System (Ardent Flutter)

A comprehensive, all-in-one management application designed for Royal Canadian Sea Cadet Corps (RCSCC). Built with Flutter and powered by Firebase, this application streamlines corps administration, training tracking, and logistics management into a single, cohesive platform.

## Features

- **Dashboard & Administration**: Quick overview of unit statistics and administrative settings.
- **Personnel Management**: Track cadets and staff, manage profiles, and monitor progression.
- **Training & Attendance**: Plan curriculum, manage parade days, and track daily attendance.
- **Marksmanship**: Record range scores and track qualifications.
- **Supply & Logistics**: Manage the quartermaster exchange, track uniform issuance, and monitor unit assets and equipment loans via PDF loan cards.
- **Financials**: Maintain bank ledgers, track budgets, and generate PDF financial reports.
- **Fundraising**: Organize campaigns, assign items to members, track returns, and generate detailed reports.
- **Awards & Qualifications**: Log and track medals, badges, and other cadet achievements.
- **Promotions**: Monitor cadet ranks, evaluate promotion requirements, and generate military orders.
- **Ship's Log**: Keep an official digital record of corps activities and events.
- **Bulletin Board & Calendar**: Centralized communication and event scheduling.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Web/Mobile)
- **Backend & Database**: [Firebase](https://firebase.google.com/) (Authentication, Cloud Firestore)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Styling**: Modern, responsive UI with customized dark/light theme support.
- **Continuous Deployment**: Automated GitHub Actions pipeline for publishing to GitHub Pages.

## Getting Started

### Prerequisites

- Flutter SDK
- A Firebase project with Authentication and Firestore configured

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jonh2oman/ardent_flutter.git
   cd ardent_flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Replace the `FirebaseOptions` configuration in `lib/main.dart` with your own Firebase project credentials if setting up your own instance.

4. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

## Deployment

This project is configured with a GitHub Actions workflow that automatically builds the Flutter Web application and deploys it to GitHub Pages whenever changes are pushed to the `main` branch. 

**Live Application**: [https://jonh2oman.github.io/ardent_flutter/](https://jonh2oman.github.io/ardent_flutter/)

## License

This project is intended for administrative use and training management.

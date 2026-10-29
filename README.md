# ⚡ Sri Lanka Electricity Bill Calculator

A Flutter-based electricity bill calculator designed for Sri Lankan consumers using **CEB (Ceylon Electricity Board)** and **LECO (Lanka Electricity Company)** services. The project includes locally bundled tariff data to support offline calculations.

[![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)](https://dart.dev/)
[![GitHub](https://img.shields.io/badge/Source-GitHub-181717?logo=github)](https://github.com/DulajAR/electricity-bill-calculator)

## 📖 Overview

**Sri Lanka Electricity Bill Calculator** is a Flutter project focused on helping users estimate their electricity bills based on applicable tariff information. It is designed around the Sri Lankan electricity billing context and includes tariff assets in the application, reducing dependence on an internet connection for locally supported tariff calculations.

> **Disclaimer:** Results are estimates for reference only. Actual CEB/LECO bills may differ due to tariff revisions, taxes, adjustments, billing periods, and other charges. Always refer to your official electricity bill and the latest published tariff information.

## ✨ Highlights

- ⚡ Electricity bill estimation for the Sri Lankan CEB/LECO context
- 📦 Bundled tariff assets for offline tariff support
- 📱 Flutter-based user interface
- 🧩 Cross-platform Flutter project structure
- 🔧 Open-source codebase suitable for learning and further development

## 🛠️ Tech Stack

| Technology | Purpose |
| --- | --- |
| Flutter | Application framework and UI |
| Dart | Programming language |
| `http` | HTTP request support |
| `path_provider` | Application filesystem path support |
| `shared_preferences` | Local key-value storage support |
| Material Design | UI components |

## 📁 Project Structure

```text
electricity-bill-calculator/
├── android/           # Android platform project
├── ios/               # iOS platform project
├── linux/             # Linux platform project
├── macos/             # macOS platform project
├── web/               # Web platform project
├── windows/           # Windows platform project
├── assets/
│   └── tariffs/       # Bundled electricity tariff data
├── lib/               # Flutter/Dart application source
├── test/              # Flutter tests
└── pubspec.yaml       # Project metadata and dependencies
```

> Platform folders are present in the repository; this does not imply that every platform has been tested or released.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code with Flutter/Dart extensions
- Android emulator or physical device for Android testing

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/DulajAR/electricity-bill-calculator.git
   ```

2. Navigate into the project:

   ```bash
   cd electricity-bill-calculator
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Check your Flutter environment:

   ```bash
   flutter doctor
   ```

5. Run the application:

   ```bash
   flutter run
   ```

## 📦 Build an Android APK

To create a release APK:

```bash
flutter build apk --release
```

The APK will typically be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To create smaller APKs for individual CPU architectures:

```bash
flutter build apk --release --split-per-abi
```



<!--
| Calculator | Bill Breakdown |
| --- | --- |
| ![Calculator](screenshots/calculator.png) | ![Bill Breakdown](screenshots/bill-breakdown.png) |
-->

## 🔄 Tariff Data

The repository contains tariff-related assets in `assets/tariffs/`. Because electricity rates can change, users and contributors should verify that the tariff information used for any estimate reflects the appropriate published rates and effective dates.

## 🤝 Contributing

Suggestions, bug reports, and contributions are welcome. Please open an issue to discuss a proposed improvement or submit a pull request.

## 👨‍💻 Developer

**Dulaj Ranasinghe**

- GitHub: [@DulajAR](https://github.com/DulajAR)
- Repository: [electricity-bill-calculator](https://github.com/DulajAR/electricity-bill-calculator)

---



## 🖼️ Screenshots


<img width="233" height="432" alt="tariefRate" src="https://github.com/user-attachments/assets/3ea82479-8353-4bcf-8194-3657bc358a4d" />
<img width="233" height="429" alt="setting" src="https://github.com/user-attachments/assets/a93476e4-5317-4860-9987-9ed07edc80c6" />
<img width="232" height="431" alt="home" src="https://github.com/user-attachments/assets/afe49339-2ee7-414e-ae3f-75fc42d5c42f" />
<img width="232" height="429" alt="hmeB" src="https://github.com/user-attachments/assets/9e00a6af-7be5-46c4-b685-2a2fc2097bc5" />
<img width="234" height="431" alt="darkMode" src="https://github.com/user-attachments/assets/1cf44edb-8fb9-49f6-93b9-ad6345b9f854" />
<img width="233" height="431" alt="billDetail" src="https://github.com/user-attachments/assets/52af5602-57db-49ad-bd3b-114e8bf6702f" />
<img width="233" height="432" alt="billDetail 2" src="https://github.com/user-attachments/assets/4f1cfadb-541a-4bc0-a272-f5952a34f77c" />


**Built with Flutter and Dart.**

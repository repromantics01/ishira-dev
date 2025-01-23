# PawsMatch

PawsMatch is a Flutter-based application designed to help pet rescue organizations manage pet adoptions, surrender requests, and communications with pet adopters and surrenderers.

## Table of Contents

- [Getting Started](https://github.com/repromantics01/pawsmatch/edit/main/README.md#getting-started)
- [Development Rules](https://github.com/repromantics01/pawsmatch/edit/main/README.md#development-rules)

## Getting Started

Follow these instructions to set up the project on your local machine for development and testing purposes.

### Prerequisites

Ensure you have the following installed on your machine:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) for Android emulation
- [Visual Studio Code](https://code.visualstudio.com/) or any IDE with Flutter and Dart extensions
- [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase integration)
- [Node.js and npm](https://nodejs.org/) (for web development and build tools)
- [GitKraken](https://www.gitkraken.com/download) (optional) (for repository management)

### Installation

1. **Clone the repository:**
    ```sh
    git clone https://github.com/repromantics01/pawsmatch.git
    cd pawsmatch
    ```

2. **Install Flutter dependencies:**
    ```sh
    flutter pub get
    ```
    
3. **Install Node.js dependencies:**
    ```sh
    npm install
    ```
4. **OPTIONAL if Firebase CLI is not yet installed (NOTE: ensure you have Node.js installed)** 
   ```sh
   npm install -g firebase-tools
   ```
   - this command enables the globally available firebase commands
   - continue to [log in and test the CLI](https://firebase.google.com/docs/cli#sign-in-test-cli)
   - **Note: If the `npm install -g firebase-tools` command fails, you might need to [change npm permissions](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally)**

### Running the Application

1. **Run Mobile Pages:**
    ```sh
    flutter run -t lib/main_mobile.dart
    ```

2. **Run Website Pages:**
    ```sh
    flutter run -t lib/main_web.dart
    ```

### Configuring Android Studio

1. **Open Android Studio.**
2. **Select "Open an existing Android Studio project".**
3. **Navigate to the cloned repository directory and select it.**
4. **Wait for Android Studio to index the project and download any necessary dependencies.**
5. **Ensure that the Flutter and Dart plugins are installed:**
    - Go to `File > Settings > Plugins`.
    - Search for "Flutter" and "Dart" and install them if they are not already installed.
6. **Configure the Android emulator:**
    - Go to `Tools > AVD Manager`.
    - Create a new virtual device or select an existing one.
    - Start the emulator.

For further assistance, refer to the [Flutter documentation](https://flutter.dev/docs) and the [Firebase documentation](https://firebase.google.com/docs).


## Development Rules
Follow these rules and instructions to ensure a smooth development process and code quality.

### Branching

- **Main Branch:** The `main` branch contains the stable and production-ready version of the code.
- **Development Branch:** The `development` branch is used to integrate new features and bug fixes, less stable than main.  
- **Feature Branches:** Create a new branch for each feature or bug fix. Name the branch descriptively, e.g., `feature/add-login` or `bugfix/fix-crash`.

    ```sh
    git checkout -b feature/your-feature-name development
    ```

#### Committing

- **Commit Messages:** Write clear and concise commit messages. Use the imperative mood, e.g., "Added login feature" or "Fix crash on startup".
- **Commit Often:** Commit your changes frequently to keep your work backed up and to make it easier to review changes.

    ```sh
    git commit -m 'Add some feature'
    ```

#### Pull Requests

- **Create Pull Requests:** When your feature or bug fix is complete, create a pull request to merge your changes into the `development` branch.
- **Review:** Request a review from the lead developer/project manager before merging.
- **Resolve Conflicts:** Ensure there are no merge conflicts before merging your pull request.

    ```sh
    git push origin feature/your-feature-name
    ```









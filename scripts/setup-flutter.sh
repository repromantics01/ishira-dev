#!/bin/bash
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.2-stable.tar.xz | tar -xJ
export PATH="$PATH:$(pwd)/flutter/bin"
flutter precache --web --no-android --no-ios
flutter doctor

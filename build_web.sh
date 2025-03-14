#!/bin/bash

set -e
# Install Flutter if not installed
if ! command -v flutter &> /dev/null
then
    echo "Flutter is not installed. Installing now..."
    git clone https://github.com/flutter/flutter.git -b stable
    export PATH="$PATH:$(pwd)/flutter/bin"
    flutter doctor
fi

flutter build web --target=lib/main_web.dart \
  --dart-define=NEXT_PUBLIC_FIREBASE_API_KEY=$NEXT_PUBLIC_FIREBASE_API_KEY \
  --dart-define=NEXT_PUBLIC_FIREBASE_APP_ID_WEB=$NEXT_PUBLIC_FIREBASE_APP_ID_WEB \
  --dart-define=NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=$NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID \
  --dart-define=NEXT_PUBLIC_FIREBASE_PROJECT_ID=$NEXT_PUBLIC_FIREBASE_PROJECT_ID \
  --dart-define=NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=$NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN \
  --dart-define=NEXT_PUBLIC_FIREBASE_DATABASE_URL=$NEXT_PUBLIC_FIREBASE_DATABASE_URL \
  --dart-define=NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=$NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET \
  --dart-define=NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=$NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID \
  --dart-define=NEXT_PUBLIC_FIREBASE_IOS_BUNDLE_ID=$NEXT_PUBLIC_FIREBASE_IOS_BUNDLE_ID \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL \
  --dart-define=NEXT_PUBLIC_SUPABASE_KEY=$NEXT_PUBLIC_SUPABASE_KEY \
  --dart-define=NEXT_PUBLIC_GOOGLE_APPLICATION_CREDENTIALS=$NEXT_PUBLIC_GOOGLE_APPLICATION_CREDENTIALS \
  --dart-define=NEXT_FIREBASE_TOKEN=$NEXT_PUBLIC_FIREBASE_TOKEN 

echo "Build completed successfully. Output directory: build/web"
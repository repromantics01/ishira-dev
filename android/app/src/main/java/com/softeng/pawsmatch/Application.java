package com.softeng.pawsmatch;

import io.flutter.app.FlutterApplication;
import androidx.multidex.MultiDex;
import android.content.Context;

public class Application extends FlutterApplication {
  @Override
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    MultiDex.install(this);
  }
}

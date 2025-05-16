package com.softeng.pawsmatch;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.PluginRegistry;

/**
 * Class that provides compatibility for plugins using the new embedding.
 */
@Keep
public final class FlutterPluginRegistrant {
    public static void registerWith(@NonNull FlutterEngine flutterEngine) {
        // Modern plugins are auto-registered by the Flutter framework
        // No need to manually register plugins
    }
}

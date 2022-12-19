package com.example.droid_top

import android.app.ActivityManager
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream


class MainActivity : FlutterActivity() {

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
//    var icon = packageManager.getApplicationInfo("com.tencent.mm", PackageManager.GET_META_DATA)
//    println("com.tencent.mm:" + icon.toString())
    val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
    activityManager.runningAppProcesses[0]
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.droid_top").setMethodCallHandler { call, result ->
      when (call.method) {
        "getApplicationIcon" -> {
          try {
            result.success(packageManager.getApplicationIcon(call.arguments as String).toBitmap()?.toByteArray())
          } catch (error: Exception) {
            result.error("error", error.message, error)
          }
        }
        else -> { // Note the block

        }
      }
    }
  }
}

fun Drawable.toBitmap(scale: Int = 1): Bitmap? {
  if (this is BitmapDrawable) {
    if (this.bitmap != null) {
      return this.bitmap
    }
  }
  // drawable is anything else for example:
  // - ColorDrawable
  // - AdaptiveIconDrawable
  // - VectorDrawable
  val bitmap = if (this.intrinsicWidth <= 0 || this.intrinsicHeight <= 0) {
    // Single color bitmap will be created of 1x1 pixel
    Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
  } else {
    Bitmap.createBitmap(
        this.intrinsicWidth * scale,
        this.intrinsicHeight * scale,
        Bitmap.Config.ARGB_8888
    )
  }
  val canvas = Canvas(bitmap)
  this.setBounds(0, 0, canvas.width, canvas.height)
  this.draw(canvas)
  return bitmap
}

fun Bitmap.toByteArray(): ByteArray {
  val stream = ByteArrayOutputStream()
  this.compress(Bitmap.CompressFormat.PNG, 90, stream)
  return stream.toByteArray()
}
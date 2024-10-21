package com.example.phidrillsim_connect

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.provider.MediaStore
import android.content.ContentValues
import android.net.Uri
import java.io.InputStream
import java.net.URL
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.phidrillsim.connect/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveFileToDownloads") {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType")
                if (url != null && fileName != null && mimeType != null) {
                    // Run the file download operation on a background thread
                    CoroutineScope(Dispatchers.IO).launch {
                        val res = saveFileToDownloads(url, fileName, mimeType)
                        withContext(Dispatchers.Main) {
                            if (res) {
                                result.success("File saved successfully")
                            } else {
                                result.error("UNAVAILABLE", "Could not save file", null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveFileToDownloads(url: String, fileName: String, mimeType: String): Boolean {
        try {
            val inputStream: InputStream = URL(url).openStream()
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/PhiDrillSim Connect")
            }

            val uri: Uri? = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            uri?.let {
                contentResolver.openOutputStream(it)?.use { outputStream ->
                    inputStream.use { input ->
                        input.copyTo(outputStream)
                    }
                }
                return true
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error saving file to downloads", e)
            return false
        }
        return false
    }
}

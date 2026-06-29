package com.rivendell.app

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Hosts the SAF folder-picker channel (FR-1.1.1, T1.1 B2). Launches
// ACTION_OPEN_DOCUMENT_TREE, takes a persistable READ permission on the chosen
// tree URI (so indexing survives reboots without re-prompting), and returns the
// URI string to Dart. A single pending Result is guarded against re-entry.
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "rivendell/folder"
    }

    private var pendingResult: MethodChannel.Result? = null

    private val openTreeLauncher: ActivityResultLauncher<Uri?> =
        registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
            val result = pendingResult
            pendingResult = null
            if (result == null) return@registerForActivityResult
            if (uri == null) {
                result.success(null) // user cancelled
                return@registerForActivityResult
            }
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
                result.success(uri.toString())
            } catch (e: SecurityException) {
                result.error("PERMISSION_FAILED", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    if (pendingResult != null) {
                        result.error(
                            "REENTRY",
                            "a folder pick is already in flight",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    openTreeLauncher.launch(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}

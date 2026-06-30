package com.rivendell.app

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

// Hosts the SAF folder-picker + audio-indexer channels (FR-1.1.1 / FR-1.1.2,
// T1.1 B2 + T1.2), the in-app recorder's folder writer (FR-1.1.3, T2.7), and
// the background audio service (T1.5, FR-1.1.4).
//
//   rivendell/folder  :: pickFolder() -> tree URI string (persistable RW)
//   rivendell/scan    :: listAudioFiles(treeUri) -> [{path,name,size,lastModified}]
//   rivendell/record  :: copyToFolder(treeUri, sourcePath, displayName) -> doc URI
//
// Extends [AudioServiceFragmentActivity] (a [FlutterFragmentActivity], i.e. an
// androidx [FragmentActivity] -> [ComponentActivity]) for two reasons:
//   1. audio_service needs this host so its media-session plugin can bind to
//      the activity's engine (background playback + lock-screen controls).
//   2. SAF's [registerForActivityResult] is a [ComponentActivity] API. The
//      plain [AudioServiceActivity] extends [FlutterActivity] (plain Activity)
//      where it is unavailable, so the Fragment variant is required.
class MainActivity : AudioServiceFragmentActivity() {

    private companion object {
        const val FOLDER_CHANNEL = "rivendell/folder"
        const val SCAN_CHANNEL = "rivendell/scan"
        const val RECORD_CHANNEL = "rivendell/record"
        val SUPPORTED_EXT = setOf("m4a", "mp3", "wav")
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
                // READ + WRITE so the in-app recorder (T2.7) can drop captures
                // into the same folder the indexer reads. READ-only picks made
                // before this grant landed can't be written; the user re-picks.
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
                result.success(uri.toString())
            } catch (e: SecurityException) {
                result.error("PERMISSION_FAILED", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, FOLDER_CHANNEL).setMethodCallHandler { call, result ->
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

        MethodChannel(messenger, SCAN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "listAudioFiles" -> {
                    val treeUri = call.argument<String>("treeUri")
                    if (treeUri == null) {
                        result.error("BAD_ARGS", "treeUri is required", null)
                        return@setMethodCallHandler
                    }
                    // Cursor I/O off the platform main thread (NFR-2.2.1).
                    thread(start = true) {
                        try {
                            result.success(listAudioFiles(treeUri))
                        } catch (e: Exception) {
                            result.error("SCAN_FAILED", e.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, RECORD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyToFolder" -> {
                    val treeUri = call.argument<String>("treeUri")
                    val sourcePath = call.argument<String>("sourcePath")
                    val displayName = call.argument<String>("displayName")
                    if (treeUri == null || sourcePath == null || displayName == null) {
                        result.error("BAD_ARGS", "treeUri/sourcePath/displayName required", null)
                        return@setMethodCallHandler
                    }
                    // File I/O off the platform main thread.
                    thread(start = true) {
                        try {
                            val docUri = copyToFolder(treeUri, sourcePath, displayName)
                            if (docUri != null) {
                                result.success(docUri)
                            } else {
                                result.error("COPY_FAILED", "could not create document", null)
                            }
                        } catch (e: Exception) {
                            result.error("COPY_FAILED", e.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /** List supported-audio documents that are direct children of [treeUriStr]. */
    private fun listAudioFiles(treeUriStr: String): List<Map<String, Any?>> {
        val treeUri = Uri.parse(treeUriStr)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        ) ?: return emptyList()

        val projection = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_SIZE,
            Document.COLUMN_LAST_MODIFIED,
        )
        val out = mutableListOf<Map<String, Any?>>()
        contentResolver
            .query(childrenUri, projection, null, null, null)
            ?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(Document.COLUMN_DOCUMENT_ID)
                val nameCol = cursor.getColumnIndexOrThrow(Document.COLUMN_DISPLAY_NAME)
                val sizeCol = cursor.getColumnIndexOrThrow(Document.COLUMN_SIZE)
                val modCol = cursor.getColumnIndexOrThrow(Document.COLUMN_LAST_MODIFIED)
                while (cursor.moveToNext()) {
                    val docId = cursor.getString(idCol) ?: continue
                    val name = cursor.getString(nameCol) ?: continue
                    if (!isSupportedAudio(name)) continue
                    val size = if (cursor.isNull(sizeCol)) 0L else cursor.getLong(sizeCol)
                    val modified =
                        if (cursor.isNull(modCol)) {
                            System.currentTimeMillis()
                        } else {
                            cursor.getLong(modCol)
                        }
                    val docUri =
                        DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                            ?: continue
                    out.add(
                        mapOf(
                            "path" to docUri.toString(),
                            "name" to name,
                            "size" to size,
                            "lastModified" to modified,
                        ),
                    )
                }
            }
        return out
    }

    /**
     * Create a child document named [displayName] under [treeUriStr] and stream
     * [sourcePath]'s bytes into it (FR-1.1.3). Returns the new document's URI
     * so the indexer's next scan picks it up. If a document with the name
     * already exists SAF appends a suffix; the returned URI is authoritative.
     */
    private fun copyToFolder(
        treeUriStr: String,
        sourcePath: String,
        displayName: String,
    ): String? {
        val treeUri = Uri.parse(treeUriStr)
        val parentDoc = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        ) ?: return null
        val newDoc = DocumentsContract.createDocument(
            contentResolver,
            parentDoc,
            // audio/mp4 is the standard MIME for the .m4a AAC container.
            "audio/mp4",
            displayName,
        ) ?: return null

        File(sourcePath).inputStream().use { input ->
            contentResolver.openOutputStream(newDoc, "w")?.use { output ->
                input.copyTo(output)
            } ?: return null
        }
        return newDoc.toString()
    }

    private fun isSupportedAudio(name: String): Boolean {
        val ext = name.substringAfterLast('.', "").lowercase()
        return ext in SUPPORTED_EXT
    }
}

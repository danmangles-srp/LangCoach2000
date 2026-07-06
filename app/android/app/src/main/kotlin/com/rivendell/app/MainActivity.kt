package com.rivendell.app

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.File
import kotlin.concurrent.thread

// Hosts the SAF folder-picker + audio-indexer channels (FR-1.1.1 / FR-1.1.2,
// T1.1 B2 + T1.2), the in-app recorder's folder writer (FR-1.1.3, T2.7), the
// word-log image writer (FR-1.3.1, T3.3), the background audio service
// (T1.5, FR-1.1.4), and the AnkiDroid adapter (FR-1.3.3, T4.1).
//
//   rivendell/folder   :: pickFolder() -> tree URI string (persistable RW)
//   rivendell/scan     :: listAudioFiles(treeUri) -> [{path,name,size,lastModified}]
//   rivendell/record   :: copyToFolder(treeUri, sourcePath, displayName) -> doc URI
//   rivendell/wordlog  :: copyImage(sourceUri, destRelativePath) -> void
//   rivendell/anki     :: isInstalled/ensureDeck/ensureModel/noteExists/addNote/addMedia
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
        const val WORDLOG_CHANNEL = "rivendell/wordlog"
        const val ANKI_CHANNEL = "rivendell/anki"
        const val ANKI_PACKAGE = "com.ichi2.anki"
        const val FILE_PROVIDER_AUTHORITY_SUFFIX = ".fileprovider"
        val SUPPORTED_EXT = setOf("m4a", "mp3", "wav")
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingPickResult: MethodChannel.Result? = null

    private val ankiGateway: AnkiGateway by lazy { AnkiGateway(this) }

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

    // Android image picker (FR-1.3.1, T3.4). PickVisualMedia needs no
    // permission and works on API 26+ via the Play Services photo-picker
    // backport. The returned URI carries a temporary read grant for this
    // process, so copyImage can stream it without an extra permission take.
    private val pickImageLauncher: ActivityResultLauncher<PickVisualMediaRequest> =
        registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            val result = pendingPickResult
            pendingPickResult = null
            if (result == null) return@registerForActivityResult
            if (uri == null) {
                result.success(null) // user cancelled
                return@registerForActivityResult
            }
            val ext = mimeToExt(contentResolver.getType(uri))
            if (ext == null) {
                result.error("UNSUPPORTED", "unsupported image type", null)
                return@registerForActivityResult
            }
            result.success(mapOf("uri" to uri.toString(), "ext" to ext))
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

                "renameDocument" -> {
                    val docUri = call.argument<String>("docUri")
                    val displayName = call.argument<String>("displayName")
                    if (docUri == null || displayName == null) {
                        result.error("BAD_ARGS", "docUri/displayName required", null)
                        return@setMethodCallHandler
                    }
                    thread(start = true) {
                        try {
                            val newUri = renameDocument(docUri, displayName)
                            if (newUri != null) {
                                result.success(newUri)
                            } else {
                                result.error("RENAME_FAILED", "could not rename document", null)
                            }
                        } catch (e: Exception) {
                            result.error("RENAME_FAILED", e.message, null)
                        }
                    }
                }

                "deleteDocument" -> {
                    val docUri = call.argument<String>("docUri")
                    if (docUri == null) {
                        result.error("BAD_ARGS", "docUri required", null)
                        return@setMethodCallHandler
                    }
                    thread(start = true) {
                        try {
                            val removed = deleteDocument(docUri)
                            result.success(removed)
                        } catch (e: Exception) {
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, WORDLOG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyImage" -> {
                    val sourceUri = call.argument<String>("sourceUri")
                    val destRelativePath = call.argument<String>("destRelativePath")
                    if (sourceUri == null || destRelativePath == null) {
                        result.error("BAD_ARGS", "sourceUri/destRelativePath required", null)
                        return@setMethodCallHandler
                    }
                    // File I/O off the platform main thread.
                    thread(start = true) {
                        try {
                            copyImage(sourceUri, destRelativePath)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("IO", e.message, null)
                        }
                    }
                }

                "pickImage" -> {
                    if (pendingPickResult != null) {
                        result.error("REENTRY", "an image pick is already in flight", null)
                        return@setMethodCallHandler
                    }
                    pendingPickResult = result
                    pickImageLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                    )
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, ANKI_CHANNEL).setMethodCallHandler { call, result ->
            // Every op hits AnkiDroid's content provider — off the main thread.
            thread(start = true) {
                try {
                    when (call.method) {
                        "isInstalled" -> result.success(ankiGateway.isInstalled())

                        "ensureDeck" -> {
                            val name = call.argument<String>("name")
                            if (name == null) {
                                result.error("BAD_ARGS", "name is required", null)
                                return@thread
                            }
                            result.success(ankiGateway.ensureDeck(name))
                        }

                        "ensureModel" -> {
                            val name = call.argument<String>("name")
                            val fields = call.argument<List<String>>("fields")
                            val front = call.argument<String>("front")
                            val back = call.argument<String>("back")
                            val css = call.argument<String>("css") ?: ""
                            if (name == null || fields == null || front == null || back == null) {
                                result.error("BAD_ARGS", "name/fields/front/back required", null)
                                return@thread
                            }
                            result.success(
                                ankiGateway.ensureModel(name, fields, front, back, css),
                            )
                        }

                        "noteExists" -> {
                            // Dart ints arrive as int32 or int64 depending on
                            // size; read as Number so both widths decode.
                            val modelId = call.argument<Number>("modelId")?.toLong()
                            val firstField = call.argument<String>("firstField")
                            if (modelId == null || firstField == null) {
                                result.error("BAD_ARGS", "modelId/firstField required", null)
                                return@thread
                            }
                            result.success(ankiGateway.noteExists(modelId, firstField))
                        }

                        "addNote" -> {
                            val deckId = call.argument<Number>("deckId")?.toLong()
                            val modelId = call.argument<Number>("modelId")?.toLong()
                            val fields = call.argument<List<String>>("fields")
                            val tags = call.argument<List<String>>("tags") ?: emptyList()
                            if (deckId == null || modelId == null || fields == null) {
                                result.error("BAD_ARGS", "deckId/modelId/fields required", null)
                                return@thread
                            }
                            // null note id = insert failed (not a dupe) → null to Dart.
                            result.success(ankiGateway.addNote(deckId, modelId, fields, tags))
                        }

                        "addMedia" -> {
                            // T4.4: import a cached AI image into AnkiDroid's
                            // media collection. relativePath is app-relative
                            // under filesDir (where the ai_image cache writes);
                            // expose it via a FileProvider content URI + a read
                            // grant to AnkiDroid, then let AddContentApi import.
                            val relativePath = call.argument<String>("relativePath")
                            val preferredName = call.argument<String>("preferredName")
                            if (relativePath == null || preferredName == null) {
                                result.error(
                                    "BAD_ARGS",
                                    "relativePath/preferredName required",
                                    null,
                                )
                                return@thread
                            }
                            result.success(
                                addMediaToAnki(relativePath, preferredName),
                            )
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    // AnkiDroid's READ_WRITE permission not granted (e.g. first run
                    // before access requested). Surfaced as a typed error so the UI
                    // can prompt; T4.5 wires the request flow.
                    result.error("ANKI_NO_ACCESS", e.message, null)
                } catch (e: Exception) {
                    result.error("ANKI_FAILED", e.message, null)
                }
            }
        }
    }
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

    /**
     * Rename the SAF document at [docUriStr] to [displayName], returning the new
     * document URI (T10.4). SAF may change the URI stem even when the name
     * matches (e.g. a collision suffix), so the returned URI is authoritative.
     */
    private fun renameDocument(
        docUriStr: String,
        displayName: String,
    ): String? {
        val docUri = Uri.parse(docUriStr)
        val renamed = DocumentsContract.renameDocument(
            contentResolver,
            docUri,
            displayName,
        ) ?: return null
        return renamed.toString()
    }

    /**
     * Delete the SAF document at [docUriStr] (T10.5). Returns true if a row was
     * removed, false if the file was already gone. Throws on permission/IO
     * failure so the caller can surface it.
     */
    private fun deleteDocument(docUriStr: String): Boolean {
        val docUri = Uri.parse(docUriStr)
        return DocumentsContract.deleteDocument(contentResolver, docUri)
    }

    /**
     * Import the cached AI image at [relativePath] (app-relative under filesDir)
     * into AnkiDroid's media collection (FR-1.3.4, T4.4). Exposes the file via a
     * FileProvider content URI, grants AnkiDroid a temporary read grant, then
     * asks AddContentApi to import it under [preferredName]. Returns the
     * formatted `<img src="...">` field string, or null if the file is missing
     * or AnkiDroid refused the import (retryable).
     */
    private fun addMediaToAnki(relativePath: String, preferredName: String): String? {
        val file = File(filesDir, relativePath)
        if (!file.exists()) return null
        val authority = "$packageName$FILE_PROVIDER_AUTHORITY_SUFFIX"
        val uri = FileProvider.getUriForFile(this, authority, file) ?: return null
        grantUriPermission(
            ANKI_PACKAGE,
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
        return try {
            ankiGateway.addMedia(uri, preferredName)
        } finally {
            // Drop the read grant once AnkiDroid has copied the bytes.
            try {
                revokeUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: SecurityException) {
                // best-effort cleanup; nothing to act on.
            }
        }
    }

    private fun isSupportedAudio(name: String): Boolean {
        val ext = name.substringAfterLast('.', "").lowercase()
        return ext in SUPPORTED_EXT
    }

    /** Map an image MIME type to a lowercase extension (no dot), or null when
     *  JPG/PNG only (FR-1.3.1). [copyImage] re-encodes through BitmapFactory so
     *  the stored bytes are always a Flutter-renderable JPEG/PNG even when the
     *  source streams bytes that don't match its mime (T9.2 root cause). */
    private fun mimeToExt(mime: String?): String? =
        when (mime) {
            "image/jpeg" -> "jpg"
            "image/png" -> "png"
            else -> null
        }

    /**
     * Normalize a picked image's bytes ([sourceUriStr], a content:// URI from
     * the photo picker) into app-private storage at [destRelativePath] under
     * filesDir (FR-1.3.1). Decodes via [BitmapFactory] and re-encodes to match
     * the destination's extension (JPEG for `.jpg`/HEIC sources, PNG for
     * `.png`) so the stored file always decodes in Flutter's `Image.file`,
     * regardless of the source format. Downsamples to a 2048px max edge to
     * bound memory + storage. Throws [java.io.IOException] on a corrupt or
     * undecodable source so the caller surfaces the failure rather than
     * writing a file that renders as a broken image.
     *
     * The picker URI is read exactly ONCE — into a byte buffer that both the
     * bounds probe and the decode reuse. The PickVisualMedia read grant is
     * not reliably reusable across opens on some OEMs (Samsung): a second
     * openInputStream() on the same URI can throw SecurityException, which
     * surfaced as "could not decode image bytes" → the attach-failed snackbar
     * (T14.4 root cause). Buffering collapses the two opens into one.
     */
    private fun copyImage(sourceUriStr: String, destRelativePath: String) {
        val source = Uri.parse(sourceUriStr)
        val dest = File(filesDir, destRelativePath)
        dest.parentFile?.mkdirs()

        val bytes = contentResolver.openInputStream(source)?.use { it.readBytes() }
            ?: throw java.io.IOException("could not open source URI")

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeStream(ByteArrayInputStream(bytes), null, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            throw java.io.IOException(
                "could not read image bounds (corrupt or unsupported format)",
            )
        }
        val sample = sampleSizeFor(bounds.outWidth, bounds.outHeight, maxEdge = 2048)
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val bitmap = BitmapFactory.decodeStream(ByteArrayInputStream(bytes), null, opts)
        try {
            if (bitmap == null) {
                throw java.io.IOException("image decoded to null (unsupported format)")
            }
            val format =
                if (dest.extension.equals("png", ignoreCase = true)) {
                    Bitmap.CompressFormat.PNG
                } else {
                    Bitmap.CompressFormat.JPEG
                }
            dest.outputStream().use { out ->
                if (!bitmap.compress(format, 92, out)) {
                    throw java.io.IOException("could not compress image to $dest")
                }
            }
        } finally {
            bitmap?.recycle()
        }
    }

    /** Largest power-of-two sample size keeping the longer edge ≤ [maxEdge]. */
    private fun sampleSizeFor(width: Int, height: Int, maxEdge: Int): Int {
        var sample = 1
        val longest = maxOf(width, height)
        while (longest / sample > maxEdge) sample *= 2
        return sample
    }
}

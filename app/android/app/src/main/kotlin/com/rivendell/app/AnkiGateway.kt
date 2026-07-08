package com.rivendell.app

import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat
import com.ichi2.anki.api.AddContentApi

// Thin Kotlin wrapper over AnkiDroid's [AddContentApi] (FR-1.3.3, T4.1). Resolves
// decks / models by name (create-or-find, since the API exposes no by-name
// lookup), reports install state, and fronts the explicit first-field dupe
// check the export service needs before adding. Every call hits AnkiDroid's
// content provider, so callers run this off the platform main thread.
//
// AnkiDroid's addNote performs NO duplicate checking — it always inserts.
// Re-save safety comes from [noteExists] (Anki keys uniqueness on a model's
// first field).
//
// T16.1: install detection + the runtime-permission gate live here so the
// channel (T16.2) + Dart UI (T16.3) drive AnkiDroid's native grant flow before
// the first content-provider query — without it every deckList/addNote call is
// rejected with "Permission not granted for: CardContentProvider.query".
class AnkiGateway(private val context: Context) {

    private val api: AddContentApi by lazy { AddContentApi(context) }

    /**
     * Whether AnkiDroid is installed AND its API is exposed (T16.1). Uses
     * [AddContentApi.getAnkiDroidPackageName] — the canonical check from the
     * official apisample — which returns null when AnkiDroid is absent or when
     * its global "Enable AnkiDroid API" toggle is off (AnkiDroid 2.24+).
     * Replaces the raw packageManager probe, which reported "installed" even
     * when the API was disabled.
     */
    fun isInstalled(): Boolean = AddContentApi.getAnkiDroidPackageName(context) != null

    /**
     * Whether the AnkiDroid READ_WRITE permission still needs a runtime grant
     * (T16.1). The v1.1.0 aar ships no `shouldRequestPermission` on
     * [AddContentApi], so this reimplements the apisample's
     * `AnkiDroidHelper.shouldRequestPermission` inline: post-M material release
     * + [ContextCompat.checkSelfPermission] against the aar's exported
     * [AddContentApi.READ_WRITE_PERMISSION] constant. Mirrors what
     * `AddContentApi.hasReadWritePermission()` (private) checks internally.
     */
    fun shouldRequestPermission(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            ContextCompat.checkSelfPermission(
                context,
                AddContentApi.READ_WRITE_PERMISSION,
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED

    /** Create-or-find the named deck. Returns its id. */
    fun ensureDeck(name: String): Long {
        api.deckList?.entries?.firstOrNull { it.value == name }?.let { return it.key }
        return api.addNewDeck(name)
            ?: throw IllegalStateException("AnkiDroid returned no deck id for \"$name\"")
    }

    /** Create-or-find a single-card note type by name. Returns its model id. */
    fun ensureModel(
        name: String,
        fields: List<String>,
        front: String,
        back: String,
        css: String,
    ): Long {
        api.modelList?.entries?.firstOrNull { it.value == name }?.let { return it.key }
        val mid = api.addNewCustomModel(
            name,
            fields.toTypedArray(),
            arrayOf("Card 1"),
            arrayOf(front),
            arrayOf(back),
            css.ifEmpty { null },
            null,
            null,
        ) ?: throw IllegalStateException("AnkiDroid returned no model id for \"$name\"")
        return mid
    }

    /** Whether a note whose first field equals [firstField] exists for [modelId]. */
    fun noteExists(modelId: Long, firstField: String): Boolean =
        api.findDuplicateNotes(modelId, firstField).isNotEmpty()

    /** Always inserts (no dupe check). Returns the note id, or null on failure. */
    fun addNote(
        deckId: Long,
        modelId: Long,
        fields: List<String>,
        tags: List<String>,
    ): Long? = api.addNote(modelId, deckId, fields.toTypedArray(), tags.toSet())

    /**
     * Import an image into AnkiDroid's media collection (T4.4, FR-1.3.4).
     * [fileUri] must be readable by AnkiDroid — the caller exposes a FileProvider
     * content URI and grants read permission to com.ichi2.anki. [preferredName]
     * is the base filename (no extension) AnkiDroid stores the media under.
     * Returns the formatted `<img src="...">` field string to drop into a note,
     * or null if AnkiDroid could not import the media (retryable — the cached
     * image is unaffected, so a later export re-tries).
     */
    fun addMedia(fileUri: Uri, preferredName: String): String? =
        api.addMediaFromUri(fileUri, preferredName, "image")
}

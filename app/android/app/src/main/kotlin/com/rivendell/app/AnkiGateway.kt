package com.rivendell.app

import android.content.Context
import android.content.pm.PackageManager
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
class AnkiGateway(private val context: Context) {

    private val api: AddContentApi by lazy { AddContentApi(context) }

    /** Whether AnkiDroid (com.ichi2.anki) is installed on the device. */
    fun isInstalled(): Boolean = try {
        context.packageManager.getPackageInfo(ANKI_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

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

    private companion object {
        const val ANKI_PACKAGE = "com.ichi2.anki"
    }
}

# feedback

1. Gate.sh should be maybe a git hook? or something more efficient
1. Do an architecture review across the whole app, critically review, and spawn a milestone to improve this for long term maintainability
1. image attachments are broken - says doesn't attach. Think deeply about this one - you've clearly got a tricky issue here since you've failed 3 times.
1. get recordings to save to all recordings - 
```
    How to Mimic the Behavior (Step-by-Step)
Instead of saving your audio using standard Java/Kotlin File() or FileOutputStream paths, you need to inject it directly into the system's MediaStore using specific database keys.

1. Insert the Correct MediaStore Flags
Samsung's "All recordings" tab runs a global query against the Android MediaStore looking for specific audio attributes. You need to explicitly tell the OS that your file is a voice recording, not a music track or a generic download.

2. Implementation Code (Java/Android)
Here is how to save your audio files so the system indexes them exactly the way Samsung's global query expects:
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import java.io.OutputStream;

public void saveRecordingToAllTabs(Context context, byte[] audioData) {
    ContentResolver resolver = context.getContentResolver();
    ContentValues values = new ContentValues();

    // Set the basic file details
    values.put(MediaStore.Audio.Media.DISPLAY_NAME, "Voice_App_" + System.currentTimeMillis() + ".m4a");
    values.put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4");
    values.put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_RECORDINGS + "/Voice Recorder");

    // CRITICAL: The Android 12+ Voice Recording flag
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        values.put(MediaStore.Audio.Media.IS_RECORDING, 1);
        values.put(MediaStore.Audio.Media.IS_MUSIC, 0);
    }

    // CRITICAL: Legacy Samsung Metadata Triggers
    // Older One UI versions filter by Album/Artist strings if the IS_RECORDING flag is absent
    values.put(MediaStore.Audio.Media.ALBUM, "Voice Recorder");
    values.put(MediaStore.Audio.Media.ARTIST, "Voice Recorder");

    // Insert into the system MediaStore
    Uri audioUri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values);

    if (audioUri != null) {
        try (OutputStream os = resolver.openOutputStream(audioUri)) {
            if (os != null) {
                os.write(audioData);
                os.flush();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```
1. today should show any recordings at all that became due in the last 2 weeks, up to a max of 4 items to review
1. there's a bug/crash on the settings screen: "lateinitializationerror: field _username@196043595 has not been initialised"
1. bug: when the recording auto-advances to the next recording that recording shows as a zero length recording.
1. when a recording finishes and auto advance is off the pause button should flip to play

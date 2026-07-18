# R8 keep rules for release builds.
#
# Crash: java.lang.NoSuchMethodException: androidx.work.impl.WorkDatabase_Impl.<init> []
# at androidx.work.WorkManagerInitializer — fires via androidx.startup before any
# Flutter/Dart code runs. R8 strips the no-arg constructor Room generates for the
# WorkManager database; the keep rule preserves it so reflective instantiation by
# androidx.startup succeeds. Affects release-only because debug builds skip R8.

-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
-keep class * extends androidx.room.RoomDatabase

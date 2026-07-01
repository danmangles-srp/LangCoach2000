// Rivendell — minimal, dependency-free localizations (NFR-2.5.x).
//
// Flutter's gen_l10n would pull flutter_localizations, which forces an intl
// bump that clashes with the project's pinned matrix (intl ^0.19). Until that
// pin moves, we hand-roll a Localizations<AppStrings>: externalized, locale-
// aware strings with Uzbek (uz) as a first-class locale — Rivendell is for
// learners of Uzbek — and English (en) as the fallback/seed. Migrating to
// gen_l10n later is a mechanical ARB port; the call sites (AppStrings.of) stay.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// The locales Rivendell ships translations for, in priority order. Drives
  /// `MaterialApp.supportedLocales`. Keep the seed locale last so the device
  /// locale resolves to a translation when one exists.
  static const List<Locale> supportedLocales = [Locale('uz'), Locale('en')];

  static const _en = _Bundle(
    recordingsTitle: 'Recordings',
    recordingsDetailTitle: 'Recording',
    recordingsNotFound: 'This recording is no longer available.',
    emptyTitle: 'No recordings yet',
    emptyBody:
        'Point Rivendell at your Samsung Voice Recorder folder and your '
        'recordings will appear here.',
    emptyHint: 'Tap refresh after picking a folder to index it.',
    loading: 'Loading recordings…',
    errorTitle: "Couldn't load recordings",
    retry: 'Try again',
    scanTooltip: 'Refresh library',
    scanFailed: "Couldn't scan that folder.",
    scannedCountN: 'Indexed {n} recordings.',
    unknownDuration: '—:—',
    unknownFormat: 'audio',
    metaDate: 'Recorded',
    metaDuration: 'Duration',
    metaSize: 'Size',
    metaFormat: 'Format',
    playTooltip: 'Play',
    pauseTooltip: 'Pause',
    replayTooltip: 'Replay',
    queueNavToday: 'Today',
    queueNavLibrary: 'Library',
    queueTitle: "Today's Review Queue",
    queueEmptyTitle: 'Nothing due today',
    queueEmptyBody:
        'You’re all caught up. Recordings due for review will appear '
        'here on their schedule.',
    queueStaleBadge: 'Stale',
    queueDueToday: 'Due today',
    queueDueTomorrow: 'Due tomorrow',
    queueUpNextBadge: 'Up next',
    queueSectionTomorrow: 'Tomorrow',
    queueOverdueN: '{n} day overdue',
    queueNowPlaying: 'Now playing',
    reviewHistoryTitle: 'Review history',
    reviewLastReviewed: 'Last reviewed',
    reviewNever: 'Never',
    reviewMilestoneReached: 'Milestone reached',
    reviewNoneYet: 'None yet',
    reviewCountN: '{n} reviews',
    reviewMarkReviewed: 'Mark reviewed',
    reviewUndo: 'Undo',
    reviewDueLabel: 'Due',
    recordTooltip: 'Record',
    recordSheetTitle: 'Record',
    recordStart: 'Record',
    recordStop: 'Stop',
    recordSaving: 'Saving…',
    recordPermissionDenied:
        'Microphone permission denied. Grant it in system settings to record.',
    recordNoFolder: 'Pick a Samsung Voice Recorder folder before recording.',
    recordFailed: "Couldn't save the recording. Try again.",
    recordSavedN: 'Saved “{name}”.',
    wordLogTitle: 'Word log',
    wordLogTabText: 'Text',
    wordLogTabImages: 'Images',
    wordLogAddText: 'Add text log',
    wordLogEditText: 'Edit text log',
    wordLogAddImage: 'Add photo',
    wordLogTextEmpty: 'No text log yet. Paste an English↔Uzbek word list.',
    wordLogImagesEmpty: 'No photos attached yet.',
    wordLogTextDialogHint: 'One pair per line: english: uzbek',
    wordLogSave: 'Save',
    wordLogCancel: 'Cancel',
    wordLogAttachFailed: 'Could not attach. Try again.',
    ankiSend: 'Send to Anki',
    ankiSending: 'Sending…',
    ankiRetry: 'Retry',
    ankiNotInstalledTitle: 'AnkiDroid not installed',
    ankiNotInstalledBody:
        'Install AnkiDroid (com.ichi2.anki) from Google Play, then reopen '
        'this recording and send again.',
    ankiSendFailed: 'Send failed. Try again.',
    ankiAddedN: 'Added: {n}',
    ankiSkippedN: 'Skipped: {n}',
    ankiFailedN: 'Failed: {n}',
    ankiPendingN: 'Queued images: {n}',
    ankiPendingHint:
        'Queued images generate on reconnect and attach on your next send.',
    ankiGotIt: 'Got it',
    tasksTitle: 'Tasks',
    tasksEmptyTitle: 'No tasks yet',
    tasksEmptyBody:
        'Add an exercise or goal — e.g. “Memorize Yor-Yor” — with an optional '
        'due date.',
    tasksAdd: 'Add task',
    taskFieldTitle: 'Title',
    taskFieldDescription: 'Notes (optional)',
    taskFieldDueDate: 'Due date',
    taskNoDate: 'No date',
    taskClearDate: 'Clear date',
    taskSave: 'Save',
    taskDelete: 'Delete',
    taskOverdue: 'Overdue',
    taskDueOnN: 'Due {date}',
  );

  static const _uz = _Bundle(
    recordingsTitle: 'Yozuvlar',
    recordingsDetailTitle: 'Yozuv',
    recordingsNotFound: 'Bu yozuv endi mavjud emas.',
    emptyTitle: "Hozircha yozuvlar yo'q",
    emptyBody:
        "Rivendell'ni Samsung Voice Recorder jildiga yo'naltiring — "
        'yozuvlaringiz shu yerda paydo bo‘ladi.',
    emptyHint: 'Jildni tanlagach, yangilash tugmasini bosing.',
    loading: 'Yozuvlar yuklanmoqda…',
    errorTitle: "Yozuvlarni yuklab bo'lmadi",
    retry: 'Qayta urinib ko‘ring',
    scanTooltip: 'Kutubxonani yangilash',
    scanFailed: 'Bu jildni skanerlab bo‘lmadi.',
    scannedCountN: '{n} ta yozuv indekslandi.',
    unknownDuration: '—:—',
    unknownFormat: 'audio',
    metaDate: 'Yozilgan',
    metaDuration: 'Davomiyligi',
    metaSize: 'Hajmi',
    metaFormat: 'Format',
    playTooltip: 'Ijro etish',
    pauseTooltip: 'To‘xtatish',
    replayTooltip: 'Qayta ijro',
    queueNavToday: 'Bugun',
    queueNavLibrary: 'Kutubxona',
    queueTitle: 'Bugungi takrorlash navbati',
    queueEmptyTitle: 'Bugun takrorlash yo‘q',
    queueEmptyBody:
        'Hammasi bajarildi. Takrorlashga zarur yozuvlar jadvali bo‘yicha '
        'shu yerda paydo bo‘ladi.',
    queueStaleBadge: 'Muddati o‘tgan',
    queueDueToday: 'Bugun',
    queueDueTomorrow: 'Ertaga',
    queueUpNextBadge: 'Keyingi',
    queueSectionTomorrow: 'Ertaga',
    queueOverdueN: '{n} kun muddati o‘tgan',
    queueNowPlaying: 'Ijro etilmoqda',
    reviewHistoryTitle: 'Takrorlash tarixi',
    reviewLastReviewed: 'So‘nggi takrorlash',
    reviewNever: 'Hech qachon',
    reviewMilestoneReached: 'Erishilgan bosqich',
    reviewNoneYet: 'Hali yo‘q',
    reviewCountN: '{n} ta takrorlash',
    reviewMarkReviewed: 'Belgilash',
    reviewUndo: 'Bekor qilish',
    reviewDueLabel: 'Muddati',
    recordTooltip: 'Yozib olish',
    recordSheetTitle: 'Yozib olish',
    recordStart: 'Yozib olish',
    recordStop: 'To‘xtatish',
    recordSaving: 'Saqlanmoqda…',
    recordPermissionDenied:
        'Mikrofon ruxsati rad etildi. Yozib olish uchun sozlamalarda '
        'ruxsat bering.',
    recordNoFolder:
        'Yozib olishdan oldin Samsung Voice Recorder jildini tanlang.',
    recordFailed: 'Yozuvni saqlab bo‘lmadi. Qayta urinib ko‘ring.',
    recordSavedN: '“{name}” saqlandi.',
    wordLogTitle: 'So‘zlar daftari',
    wordLogTabText: 'Matn',
    wordLogTabImages: 'Rasmlar',
    wordLogAddText: 'Matn qo‘shish',
    wordLogEditText: 'Matnni tahrirlash',
    wordLogAddImage: 'Rasm qo‘shish',
    wordLogTextEmpty:
        'Hozircha matn yo‘q. Inglizcha↔o‘zbekcha so‘zlar ro‘yxatini qo‘ying.',
    wordLogImagesEmpty: 'Hozircha birorta rasm biriktirilmagan.',
    wordLogTextDialogHint: 'Har qatorda bittadan: english: uzbek',
    wordLogSave: 'Saqlash',
    wordLogCancel: 'Bekor qilish',
    wordLogAttachFailed: 'Biriktirib bo‘lmadi. Qayta urinib ko‘ring.',
    ankiSend: "Anki'ga yuborish",
    ankiSending: 'Yuborilmoqda…',
    ankiRetry: 'Qayta urinish',
    ankiNotInstalledTitle: 'AnkiDroid o‘rnatilmagan',
    ankiNotInstalledBody:
        "Google Play'dan AnkiDroid (com.ichi2.anki) o‘rnating, so‘ng yozuvni "
        'qaytaring va yuboring.',
    ankiSendFailed: 'Yuborib bo‘lmadi. Qayta urinib ko‘ring.',
    ankiAddedN: 'Qo‘shildi: {n}',
    ankiSkippedN: 'O‘tkazib yuborildi: {n}',
    ankiFailedN: 'Muvaffaqiyatsiz: {n}',
    ankiPendingN: 'Navbatdagi rasmlar: {n}',
    ankiPendingHint:
        'Navbatdagi rasmlar aloqada tiklanganda yaratiladi va keyingi '
        'yuborishda biriktiriladi.',
    ankiGotIt: 'Tushunarli',
    tasksTitle: 'Vazifalar',
    tasksEmptyTitle: 'Hozircha vazifalar yo‘q',
    tasksEmptyBody:
        'Mashq yoki maqsad qo‘shing — masalan, “Yor-Yor ni yod oling” — '
        'ixtiyoriy muddat bilan.',
    tasksAdd: 'Vazifa qo‘shish',
    taskFieldTitle: 'Sarlavha',
    taskFieldDescription: 'Izoh (ixtiyoriy)',
    taskFieldDueDate: 'Muddati',
    taskNoDate: 'Sanasiz',
    taskClearDate: 'Sanani olib tashlash',
    taskSave: 'Saqlash',
    taskDelete: 'O‘chirish',
    taskOverdue: 'Muddati o‘tgan',
    taskDueOnN: 'Muddati: {date}',
  );

  // Resolve the bundle for the active locale, falling back to English.
  _Bundle get _bundle => locale.languageCode == 'uz' ? _uz : _en;

  String get recordingsTitle => _bundle.recordingsTitle;
  String get recordingsDetailTitle => _bundle.recordingsDetailTitle;
  String get recordingsNotFound => _bundle.recordingsNotFound;
  String get emptyTitle => _bundle.emptyTitle;
  String get emptyBody => _bundle.emptyBody;
  String get emptyHint => _bundle.emptyHint;
  String get loading => _bundle.loading;
  String get errorTitle => _bundle.errorTitle;
  String get retry => _bundle.retry;
  String get scanTooltip => _bundle.scanTooltip;
  String get scanFailed => _bundle.scanFailed;
  String scannedCount(int n) => _bundle.scannedCountN.replaceAll('{n}', '$n');
  String get unknownDuration => _bundle.unknownDuration;
  String get unknownFormat => _bundle.unknownFormat;
  String get metaDate => _bundle.metaDate;
  String get metaDuration => _bundle.metaDuration;
  String get metaSize => _bundle.metaSize;
  String get metaFormat => _bundle.metaFormat;
  String get playTooltip => _bundle.playTooltip;
  String get pauseTooltip => _bundle.pauseTooltip;
  String get replayTooltip => _bundle.replayTooltip;
  String get queueNavToday => _bundle.queueNavToday;
  String get queueNavLibrary => _bundle.queueNavLibrary;
  String get queueTitle => _bundle.queueTitle;
  String get queueEmptyTitle => _bundle.queueEmptyTitle;
  String get queueEmptyBody => _bundle.queueEmptyBody;
  String get queueStaleBadge => _bundle.queueStaleBadge;
  String get queueDueToday => _bundle.queueDueToday;
  String get queueDueTomorrow => _bundle.queueDueTomorrow;
  String get queueUpNextBadge => _bundle.queueUpNextBadge;
  String get queueSectionTomorrow => _bundle.queueSectionTomorrow;
  String queueOverdue(int n) => _bundle.queueOverdueN.replaceAll('{n}', '$n');
  String get queueNowPlaying => _bundle.queueNowPlaying;
  String get reviewHistoryTitle => _bundle.reviewHistoryTitle;
  String get reviewLastReviewed => _bundle.reviewLastReviewed;
  String get reviewNever => _bundle.reviewNever;
  String get reviewMilestoneReached => _bundle.reviewMilestoneReached;
  String get reviewNoneYet => _bundle.reviewNoneYet;
  String reviewCount(int n) => _bundle.reviewCountN.replaceAll('{n}', '$n');
  String get reviewMarkReviewed => _bundle.reviewMarkReviewed;
  String get reviewUndo => _bundle.reviewUndo;
  String get reviewDueLabel => _bundle.reviewDueLabel;
  String get recordTooltip => _bundle.recordTooltip;
  String get recordSheetTitle => _bundle.recordSheetTitle;
  String get recordStart => _bundle.recordStart;
  String get recordStop => _bundle.recordStop;
  String get recordSaving => _bundle.recordSaving;
  String get recordPermissionDenied => _bundle.recordPermissionDenied;
  String get recordNoFolder => _bundle.recordNoFolder;
  String get recordFailed => _bundle.recordFailed;
  String recordSaved(String name) =>
      _bundle.recordSavedN.replaceAll('{name}', name);
  String get wordLogTitle => _bundle.wordLogTitle;
  String get wordLogTabText => _bundle.wordLogTabText;
  String get wordLogTabImages => _bundle.wordLogTabImages;
  String get wordLogAddText => _bundle.wordLogAddText;
  String get wordLogEditText => _bundle.wordLogEditText;
  String get wordLogAddImage => _bundle.wordLogAddImage;
  String get wordLogTextEmpty => _bundle.wordLogTextEmpty;
  String get wordLogImagesEmpty => _bundle.wordLogImagesEmpty;
  String get wordLogTextDialogHint => _bundle.wordLogTextDialogHint;
  String get wordLogSave => _bundle.wordLogSave;
  String get wordLogCancel => _bundle.wordLogCancel;
  String get wordLogAttachFailed => _bundle.wordLogAttachFailed;
  String get ankiSend => _bundle.ankiSend;
  String get ankiSending => _bundle.ankiSending;
  String get ankiRetry => _bundle.ankiRetry;
  String get ankiNotInstalledTitle => _bundle.ankiNotInstalledTitle;
  String get ankiNotInstalledBody => _bundle.ankiNotInstalledBody;
  String get ankiSendFailed => _bundle.ankiSendFailed;
  String ankiAdded(int n) => _bundle.ankiAddedN.replaceAll('{n}', '$n');
  String ankiSkipped(int n) => _bundle.ankiSkippedN.replaceAll('{n}', '$n');
  String ankiFailed(int n) => _bundle.ankiFailedN.replaceAll('{n}', '$n');
  String ankiPending(int n) => _bundle.ankiPendingN.replaceAll('{n}', '$n');
  String get ankiPendingHint => _bundle.ankiPendingHint;
  String get ankiGotIt => _bundle.ankiGotIt;
  String get tasksTitle => _bundle.tasksTitle;
  String get tasksEmptyTitle => _bundle.tasksEmptyTitle;
  String get tasksEmptyBody => _bundle.tasksEmptyBody;
  String get tasksAdd => _bundle.tasksAdd;
  String get taskFieldTitle => _bundle.taskFieldTitle;
  String get taskFieldDescription => _bundle.taskFieldDescription;
  String get taskFieldDueDate => _bundle.taskFieldDueDate;
  String get taskNoDate => _bundle.taskNoDate;
  String get taskClearDate => _bundle.taskClearDate;
  String get taskSave => _bundle.taskSave;
  String get taskDelete => _bundle.taskDelete;
  String get taskOverdue => _bundle.taskOverdue;
  String taskDueOn(String date) =>
      _bundle.taskDueOnN.replaceAll('{date}', date);

  // The standard Flutter Localizations accessor convention (`AppStrings.of`);
  // VGA's "static method → constructor" lint doesn't fit the lookup pattern.
  // ignore: prefer_constructors_over_static_methods
  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    return strings ?? const AppStrings(Locale('en'));
  }
}

@immutable
class _Bundle {
  const _Bundle({
    required this.recordingsTitle,
    required this.recordingsDetailTitle,
    required this.recordingsNotFound,
    required this.emptyTitle,
    required this.emptyBody,
    required this.emptyHint,
    required this.loading,
    required this.errorTitle,
    required this.retry,
    required this.scanTooltip,
    required this.scanFailed,
    required this.scannedCountN,
    required this.unknownDuration,
    required this.unknownFormat,
    required this.metaDate,
    required this.metaDuration,
    required this.metaSize,
    required this.metaFormat,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.replayTooltip,
    required this.queueNavToday,
    required this.queueNavLibrary,
    required this.queueTitle,
    required this.queueEmptyTitle,
    required this.queueEmptyBody,
    required this.queueStaleBadge,
    required this.queueDueToday,
    required this.queueDueTomorrow,
    required this.queueUpNextBadge,
    required this.queueSectionTomorrow,
    required this.queueOverdueN,
    required this.queueNowPlaying,
    required this.reviewHistoryTitle,
    required this.reviewLastReviewed,
    required this.reviewNever,
    required this.reviewMilestoneReached,
    required this.reviewNoneYet,
    required this.reviewCountN,
    required this.reviewMarkReviewed,
    required this.reviewUndo,
    required this.reviewDueLabel,
    required this.recordTooltip,
    required this.recordSheetTitle,
    required this.recordStart,
    required this.recordStop,
    required this.recordSaving,
    required this.recordPermissionDenied,
    required this.recordNoFolder,
    required this.recordFailed,
    required this.recordSavedN,
    required this.wordLogTitle,
    required this.wordLogTabText,
    required this.wordLogTabImages,
    required this.wordLogAddText,
    required this.wordLogEditText,
    required this.wordLogAddImage,
    required this.wordLogTextEmpty,
    required this.wordLogImagesEmpty,
    required this.wordLogTextDialogHint,
    required this.wordLogSave,
    required this.wordLogCancel,
    required this.wordLogAttachFailed,
    required this.ankiSend,
    required this.ankiSending,
    required this.ankiRetry,
    required this.ankiNotInstalledTitle,
    required this.ankiNotInstalledBody,
    required this.ankiSendFailed,
    required this.ankiAddedN,
    required this.ankiSkippedN,
    required this.ankiFailedN,
    required this.ankiPendingN,
    required this.ankiPendingHint,
    required this.ankiGotIt,
    required this.tasksTitle,
    required this.tasksEmptyTitle,
    required this.tasksEmptyBody,
    required this.tasksAdd,
    required this.taskFieldTitle,
    required this.taskFieldDescription,
    required this.taskFieldDueDate,
    required this.taskNoDate,
    required this.taskClearDate,
    required this.taskSave,
    required this.taskDelete,
    required this.taskOverdue,
    required this.taskDueOnN,
  });

  final String recordingsTitle;
  final String recordingsDetailTitle;
  final String recordingsNotFound;
  final String emptyTitle;
  final String emptyBody;
  final String emptyHint;
  final String loading;
  final String errorTitle;
  final String retry;
  final String scanTooltip;
  final String scanFailed;
  final String scannedCountN;
  final String unknownDuration;
  final String unknownFormat;
  final String metaDate;
  final String metaDuration;
  final String metaSize;
  final String metaFormat;
  final String playTooltip;
  final String pauseTooltip;
  final String replayTooltip;
  final String queueNavToday;
  final String queueNavLibrary;
  final String queueTitle;
  final String queueEmptyTitle;
  final String queueEmptyBody;
  final String queueStaleBadge;
  final String queueDueToday;
  final String queueDueTomorrow;
  final String queueUpNextBadge;
  final String queueSectionTomorrow;
  final String queueOverdueN;
  final String queueNowPlaying;
  final String reviewHistoryTitle;
  final String reviewLastReviewed;
  final String reviewNever;
  final String reviewMilestoneReached;
  final String reviewNoneYet;
  final String reviewCountN;
  final String reviewMarkReviewed;
  final String reviewUndo;
  final String reviewDueLabel;
  final String recordTooltip;
  final String recordSheetTitle;
  final String recordStart;
  final String recordStop;
  final String recordSaving;
  final String recordPermissionDenied;
  final String recordNoFolder;
  final String recordFailed;
  final String recordSavedN;
  final String wordLogTitle;
  final String wordLogTabText;
  final String wordLogTabImages;
  final String wordLogAddText;
  final String wordLogEditText;
  final String wordLogAddImage;
  final String wordLogTextEmpty;
  final String wordLogImagesEmpty;
  final String wordLogTextDialogHint;
  final String wordLogSave;
  final String wordLogCancel;
  final String wordLogAttachFailed;
  final String ankiSend;
  final String ankiSending;
  final String ankiRetry;
  final String ankiNotInstalledTitle;
  final String ankiNotInstalledBody;
  final String ankiSendFailed;
  final String ankiAddedN;
  final String ankiSkippedN;
  final String ankiFailedN;
  final String ankiPendingN;
  final String ankiPendingHint;
  final String ankiGotIt;
  final String tasksTitle;
  final String tasksEmptyTitle;
  final String tasksEmptyBody;
  final String tasksAdd;
  final String taskFieldTitle;
  final String taskFieldDescription;
  final String taskFieldDueDate;
  final String taskNoDate;
  final String taskClearDate;
  final String taskSave;
  final String taskDelete;
  final String taskOverdue;
  final String taskDueOnN;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    final code = locale.languageCode;
    return code == 'en' || code == 'uz';
  }

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

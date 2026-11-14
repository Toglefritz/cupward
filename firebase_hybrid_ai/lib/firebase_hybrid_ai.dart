/// A bridge between Flutter and the Firebase AI Logic hybrid inference SDKs.
library;

export 'src/exceptions/firebase_hybrid_ai_exception.dart';
export 'src/exceptions/firebase_not_initialized_exception.dart';
export 'src/exceptions/hybrid_ai_not_supported_exception.dart';
export 'src/firebase_hybrid_ai.dart';
// The data types are declared in pigeon/messages.dart and generated into this file. Only they are exported. The host
// API class in the same file is an implementation detail.
export 'src/messages.g.dart'
    show OnDeviceModelAvailability, OnDeviceModelCategory, OnDeviceModelDownloadProgress, OnDeviceModelStatus;
export 'src/platform/firebase_hybrid_ai_platform.dart';

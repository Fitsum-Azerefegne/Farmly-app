export 'voice_controller_stub.dart'
    if (dart.library.html) 'voice_controller_web.dart'
    if (dart.library.io) 'voice_controller_mobile.dart';

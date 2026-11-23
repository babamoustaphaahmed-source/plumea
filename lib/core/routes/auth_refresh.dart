import 'dart:async';

import 'package:flutter/foundation.dart';

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
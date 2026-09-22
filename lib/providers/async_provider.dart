import 'package:flutter/foundation.dart';
import '../services/app_error.dart';

class AsyncProvider extends ChangeNotifier {
  bool saving = false, disposed = false;
  String? saveError;
  void changed() {
    if (!disposed) notifyListeners();
  }

  Future<bool> save(Future<void> Function() action) async {
    if (saving || disposed) return false;
    saving = true;
    saveError = null;
    changed();
    try {
      await action();
      return true;
    } catch (e) {
      saveError = errorMessage(e);
      return false;
    } finally {
      saving = false;
      changed();
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

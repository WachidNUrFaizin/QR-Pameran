class ScanProcessingGuard {
  bool _isProcessing = false;
  int _sessionSequence = 0;
  int? _activeSession;

  int beginSession() {
    final session = ++_sessionSequence;
    _activeSession = session;
    return session;
  }

  void endSession(int session) {
    if (_activeSession == session) {
      _activeSession = null;
    }
  }

  bool isSessionActive(int session) => _activeSession == session;

  Future<T?> run<T>(Future<T> Function() action) async {
    if (_isProcessing) {
      return null;
    }

    _isProcessing = true;
    try {
      return await action();
    } finally {
      _isProcessing = false;
    }
  }

  Future<T?> runForSession<T>(int session, Future<T> Function() action) async {
    if (!isSessionActive(session)) {
      return null;
    }

    final result = await run(action);
    return isSessionActive(session) ? result : null;
  }
}

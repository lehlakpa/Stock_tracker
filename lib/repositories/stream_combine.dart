import 'dart:async';

/// Each consumer owns and cancels its source subscriptions.
Stream<List<Object?>> combineStreams(List<Stream<Object?>> sources) =>
    Stream.multi((controller) {
      if (sources.isEmpty) {
        controller.add(const []);
        controller.close();
        return;
      }
      final values = List<Object?>.filled(sources.length, null);
      final ready = List<bool>.filled(sources.length, false);
      final subscriptions = <StreamSubscription<Object?>>[];
      var remaining = sources.length;
      for (var i = 0; i < sources.length; i++) {
        final index = i;
        subscriptions.add(
          sources[i].listen(
            (value) {
              values[index] = value;
              ready[index] = true;
              if (ready.every((v) => v)) {
                controller.add(List<Object?>.unmodifiable(values));
              }
            },
            onError: controller.addError,
            onDone: () {
              remaining--;
              if (!ready[index] || remaining == 0) {
                controller.close();
              }
            },
          ),
        );
      }
      controller.onCancel = () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
      };
    });

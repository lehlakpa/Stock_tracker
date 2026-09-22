import 'dart:math';

String newOperationId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0xFFFFFFFF)}-${Random.secure().nextInt(0xFFFFFFFF)}';

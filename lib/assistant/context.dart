// What the assistant knows about the farmer's current field. The Shell sets
// [analysis] when a field is open, so the assistant can answer from the
// same NASA figures the screens show.
import 'package:flutter/foundation.dart';

import '../analysis.dart';

class AssistantContext {
  AssistantContext._();
  static final analysis = ValueNotifier<Analysis?>(null);
  static final chatOpen = ValueNotifier<bool>(false);
}

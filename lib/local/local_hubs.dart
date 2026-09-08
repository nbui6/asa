/// The one seam a fork writes into — see `FOR-YOUR-FORK.md` for the full
/// deal this is part of.
///
/// Nothing in `core/` or `hubs/` ever imports this file. `main.dart` is
/// the one registration point, so a fork can add a screen here without
/// touching anything of ours, and a merge from upstream never conflicts
/// with it.
library;

import 'package:flutter/widgets.dart';

/// Extra hub screens a fork wants alongside Asa's own. Empty by default —
/// this file changes nothing about what ships from this repository.
const List<WidgetBuilder> localHubs = [];

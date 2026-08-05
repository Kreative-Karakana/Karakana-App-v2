import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared orientation/system-UI handling for hand-rolled fullscreen video
/// players (e.g. course intro and lesson video). Locks to landscape with an
/// immersive UI on entry, and restores portrait + edge-to-edge UI on exit.
///
/// On iOS, `UIViewController.supportedInterfaceOrientations` is invalidated
/// asynchronously via `setNeedsUpdateOfSupportedInterfaceOrientations()`.
/// Requesting a *restrictive* orientation list directly can be validated by
/// UIKit against the stale, not-yet-invalidated list and rejected with
/// `UISceneErrorDomain Code=101` ("requested X; supported Y") — confirmed
/// via device testing. Resetting to an unrestricted list first forces that
/// invalidation to start.
///
/// Awaiting the platform-channel round trip alone is *not* enough to know
/// the invalidation has actually been processed by UIKit — that happens on
/// a later run-loop turn. Without a real settle delay, a restrictive lock
/// sent immediately after the reset can itself be silently dropped, which
/// (also confirmed via device testing) can leave the *entire app* stuck in
/// whatever orientation the device physically was in when the reset landed
/// — not just the video screen. [_iosOrientationSettleDelay] gives UIKit
/// that turn before the real request is sent.
mixin FullscreenVideoOrientation<T extends StatefulWidget> on State<T> {
  bool _orientationRestored = false;

  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const _portrait = [DeviceOrientation.portraitUp];
  static const _iosOrientationSettleDelay = Duration(milliseconds: 150);

  Future<void> _applyOrientations(List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(const []);
    await Future.delayed(_iosOrientationSettleDelay);
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Locks to landscape + immersive UI.
  Future<void> enterFullscreenOrientation() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await _applyOrientations(_landscape);
  }

  /// Restores portrait + edge-to-edge UI. Idempotent — safe to call from
  /// both `PopScope` and `dispose()` without re-triggering the platform
  /// calls a second time. Deliberately does not check `mounted`: this is
  /// commonly called from `dispose()`, where `mounted` is already false by
  /// the time the settle delay above elapses — skipping the call there
  /// would leave the app stuck exactly like the bug this fixes.
  Future<void> restorePortraitOrientation() async {
    if (_orientationRestored) return;
    _orientationRestored = true;
    await _applyOrientations(_portrait);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

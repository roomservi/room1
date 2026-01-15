import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages screen state and caching to ensure seamless transitions
/// without reloading data when switching between screens.
class ScreenManager {
  static const String _lastScreenKey = 'last_screen_index';
  static const String _screenCachePrefix = 'screen_cache_';

  /// Cached screen widgets - keeps them in memory to prevent reload
  static final Map<int, Widget> _screenCache = {};

  /// Track which screens have been initialized
  static final Map<int, bool> _screenInitialized = {};

  /// Last known screen index
  static int _lastScreenIndex = 0;

  /// Get the last viewed screen index from SharedPreferences
  static Future<int> getLastScreenIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastScreenIndex = prefs.getInt(_lastScreenKey) ?? 0;
      return _lastScreenIndex;
    } catch (e) {
      debugPrint('Error loading last screen: $e');
      return 0;
    }
  }

  /// Save the current screen index to SharedPreferences
  static Future<void> saveScreenIndex(int index) async {
    try {
      _lastScreenIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastScreenKey, index);
    } catch (e) {
      debugPrint('Error saving screen index: $e');
    }
  }

  /// Register a screen widget for caching
  static void cacheScreen(int screenIndex, Widget screenWidget) {
    _screenCache[screenIndex] = screenWidget;
    _screenInitialized[screenIndex] = true;
  }

  /// Retrieve cached screen widget
  static Widget? getCachedScreen(int screenIndex) {
    return _screenCache[screenIndex];
  }

  /// Check if a screen has been initialized
  static bool isScreenInitialized(int screenIndex) {
    return _screenInitialized[screenIndex] ?? false;
  }

  /// Pre-initialize screens that are likely to be used
  /// Call this during app startup to preload screens
  static void preloadScreens(List<Widget> screens) {
    for (int i = 0; i < screens.length; i++) {
      if (!_screenInitialized[i]!) {
        cacheScreen(i, screens[i]);
      }
    }
  }

  /// Clear cache for a specific screen (useful for forcing refresh)
  static void clearScreenCache(int screenIndex) {
    _screenCache.remove(screenIndex);
    _screenInitialized[screenIndex] = false;
  }

  /// Clear all screen caches
  static void clearAllCache() {
    _screenCache.clear();
    _screenInitialized.clear();
  }

  /// Get the current last screen index
  static int get lastScreenIndex => _lastScreenIndex;

  /// Get cache size info for debugging
  static Map<String, dynamic> getCacheInfo() {
    return {
      'cached_screens': _screenCache.length,
      'initialized_screens': _screenInitialized.length,
      'last_index': _lastScreenIndex,
    };
  }
}

/// Wrapper widget that automatically keeps screen state alive
class CachedScreen extends StatefulWidget {
  final int screenIndex;
  final Widget child;
  final VoidCallback? onScreenReady;

  const CachedScreen({
    required this.screenIndex,
    required this.child,
    this.onScreenReady,
    super.key,
  });

  @override
  State<CachedScreen> createState() => _CachedScreenState();
}

class _CachedScreenState extends State<CachedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // Mark screen as initialized and cache it
    ScreenManager.cacheScreen(widget.screenIndex, widget.child);
    widget.onScreenReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

/// Helper class to manage screen transitions with caching
class ScreenTransitionManager {
  /// Create a cached screen with automatic state preservation
  static Widget createCachedScreen({
    required int screenIndex,
    required Widget child,
    VoidCallback? onScreenReady,
  }) {
    return CachedScreen(
      screenIndex: screenIndex,
      child: child,
      onScreenReady: onScreenReady,
    );
  }

  /// Create a PageView that supports screen caching
  static Widget createCachedPageView({
    required List<Widget> screens,
    required PageController controller,
    required ValueChanged<int> onPageChanged,
    bool enableCache = true,
  }) {
    return PageView(
      controller: controller,
      onPageChanged: (index) {
        if (enableCache) {
          ScreenManager.saveScreenIndex(index);
        }
        onPageChanged(index);
      },
      children:
          enableCache
              ? screens
                  .asMap()
                  .entries
                  .map(
                    (entry) => CachedScreen(
                      screenIndex: entry.key,
                      child: entry.value,
                    ),
                  )
                  .toList()
              : screens,
    );
  }
}

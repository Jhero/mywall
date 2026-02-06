import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'about_screen.dart';
import 'rate_us_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey _themeMenuKey = GlobalKey();
  final GlobalKey _notifKey = GlobalKey();
  final GlobalKey _reloadKey = GlobalKey();
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _favoritesNavKey = GlobalKey();
  final GlobalKey _aboutNavKey = GlobalKey();
  final GlobalKey _rateNavKey = GlobalKey();

  late final List<Widget> _screens = [
    MyHomePage(
      tourThemeMenuKey: _themeMenuKey,
      tourNotificationKey: _notifKey,
      tourReloadKey: _reloadKey,
    ),
    const FavoritesScreen(),
    const AboutScreen(),
    const RateUsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartProductTour();
    });
  }

  Future<void> _maybeStartProductTour() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_completed_product_tour') ?? false;
    if (seen) return;
    _startProductTour();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _entryEnsureVisible();
      }
    });
  }

  void _startProductTour() {
    final steps = [
      _TourStep(
        key: _notifKey,
        title: 'Notifications',
        description: 'Open notifications and manage unread items.',
      ),
      _TourStep(
        key: _themeMenuKey,
        title: 'Themes',  
        description: 'Change app theme with this menu.',
      ),
      _TourStep(
        key: _reloadKey,
        title: 'Reload',
        description: 'Refresh galleries and data.',
      ),
      _TourStep(
        key: _favoritesNavKey,
        title: 'Favorites',
        description: 'See wallpapers you like here.',
      ),
      _TourStep(
        key: _aboutNavKey,
        title: 'About',
        description: 'Learn about the app here.',
      ),
      _TourStep(
        key: _rateNavKey,
        title: 'Rate Us',
        description: 'Share feedback and rate the app.',
      ),
    ];
    final overlay = _ProductTourOverlay(context: context, steps: steps, onFinish: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_product_tour', true);
    });
    overlay.show();
  }

  void _entryEnsureVisible() {
    // No-op hook; overlay manages its own visibility. Kept for future tweaks.
  }

  Future<void> _resetAndStartProductTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_completed_product_tour');
    _startProductTour();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,

        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: _homeNavKey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, key: _favoritesNavKey),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info, key: _aboutNavKey),
            label: 'About',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onLongPress: _resetAndStartProductTour,
              child: Icon(Icons.star, key: _rateNavKey),
            ),
            label: 'Rate Us',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        onTap: _onItemTapped,
      ),
    );
  }

}

class _TourStep {
  final GlobalKey key;
  final String title;
  final String description;
  _TourStep({required this.key, required this.title, required this.description});
}

class _ProductTourOverlay {
  final BuildContext context;
  final List<_TourStep> steps;
  final Future<void> Function() onFinish;
  OverlayEntry? _entry;
  int _index = 0;
  _ProductTourOverlay({required this.context, required this.steps, required this.onFinish});

  void show() {
    _entry = OverlayEntry(builder: (ctx) {
      return _buildOverlay(ctx);
    });
    Overlay.of(context).insert(_entry!);
  }

  void _next() async {
    if (_index < steps.length - 1) {
      _index++;
      _entry?.markNeedsBuild();
    } else {
      await onFinish();
      _entry?.remove();
      _entry = null;
    }
  }

  void _prev() {
    if (_index > 0) {
      _index--;
      _entry?.markNeedsBuild();
    }
  }

  void _skip() async {
    await onFinish();
    _entry?.remove();
    _entry = null;
  }

  Widget _buildOverlay(BuildContext ctx) {
    final step = steps[_index];
    final renderObject = step.key.currentContext?.findRenderObject() as RenderBox?;
    Rect targetRect;
    if (renderObject != null) {
      final offset = renderObject.localToGlobal(Offset.zero);
      targetRect = offset & renderObject.size;
    } else {
      targetRect = Rect.fromLTWH(
        MediaQuery.of(ctx).size.width * 0.5 - 40,
        MediaQuery.of(ctx).size.height * 0.5 - 40,
        80,
        80,
      );
    }
    final theme = Theme.of(ctx);
    final screenSize = MediaQuery.of(ctx).size;
    final nearBottom = targetRect.bottom > screenSize.height - 120;
    final double cardWidth = (screenSize.width - 32).clamp(220.0, 280.0);
    const double popupHeight = 120;
    final double left = (targetRect.center.dx - cardWidth / 2)
        .clamp(16.0, screenSize.width - 16.0 - cardWidth);
    final double top = nearBottom
        ? (targetRect.top - popupHeight - 12)
        : (targetRect.bottom + 12);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
        Positioned(
          left: targetRect.left - 12,
          top: targetRect.top - 12,
          width: targetRect.width + 24,
          height: targetRect.height + 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: cardWidth,
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(step.description, style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: _skip, child: const Text('Skip')),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _index > 0 ? _prev : null,
                            child: const Text('Back'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _next,
                            child: Text(_index < steps.length - 1 ? 'Next' : 'Done'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

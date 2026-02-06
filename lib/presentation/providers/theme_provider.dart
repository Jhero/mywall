import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _theme = AppTheme.lightTheme;
  ThemeData get theme => _theme;

  void setThemeByKey(String key) {
    switch (key) {
      case 'dark':
        _theme = AppTheme.darkTheme;
        break;
      case 'pink':
        _theme = AppTheme.pinkTheme;
        break;
      case 'blue':
        _theme = AppTheme.blueTheme;
        break;
      case 'normal':
      default:
        _theme = AppTheme.lightTheme;
        break;
    }
    notifyListeners();
  }
}

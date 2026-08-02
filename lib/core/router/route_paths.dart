/// Route path constants (12_NAVIGATION.md). Never build routes with
/// raw string literals scattered across the app — reference these.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String lists = '/lists';
  static const String listDetail = '/lists/detail/:id';
  static const String shoppingMode = '/shopping-mode/:id';

  static const String family = '/family';
  static const String familyMembers = '/family/members';
  static const String familyInvite = '/family/invite';

  static const String reports = '/reports';

  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsDeveloper = '/settings/developer';
}

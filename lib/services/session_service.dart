import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String lastEmailKey = 'last_email';
  static const String sessionLoggedInKey = 'session_logged_in';
  static const String sessionUserNameKey = 'session_user_name';

  Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastEmailKey);
  }

  Future<void> saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastEmailKey, email);
  }

  Future<void> clearLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastEmailKey);
  }

  Future<void> saveLoginSession({required String userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionLoggedInKey, true);
    await prefs.setString(sessionUserNameKey, userName);
  }

  Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionLoggedInKey);
    await prefs.remove(sessionUserNameKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sessionLoggedInKey) ?? false;
  }

  Future<String?> getSessionUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(sessionUserNameKey);
  }
}

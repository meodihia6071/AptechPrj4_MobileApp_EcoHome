class AuthSession {
  AuthSession._();

  static String? token;
  static String? accountId;
  static String? fullName;

  static void save(Map<String, dynamic> account) {
    token = account['token']?.toString();
    accountId = account['accountId']?.toString();
    fullName = account['fullName']?.toString();
  }

  static void clear() {
    token = null;
    accountId = null;
    fullName = null;
  }
}

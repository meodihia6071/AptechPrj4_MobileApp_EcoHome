class AuthSession {
  AuthSession._();

  static String? token;
  static String? accountId;
  static String? residentId;
  static String? fullName;

  static void save(Map<String, dynamic> account) {
    token = account['token']?.toString();
    accountId = account['accountId']?.toString();
    final resident = account['resident'];
    residentId = resident is Map ? resident['residentId']?.toString() : null;
    fullName = account['fullName']?.toString();
  }

  static void clear() {
    token = null;
    accountId = null;
    residentId = null;
    fullName = null;
  }
}

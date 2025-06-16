List<Language> languageList = [Language(), Khmer()];

class Language {
  String get code => "EN";

  String get login => "Log In";

  String get logout => "Logout";

  String get deleteMyAccount => "Delete My Account";

  String get removeAccount => "Delete Account";

  String get msgRemoveAccount =>
      "Would you really like to delete your account?";

  String get register => " Register";
}

class Khmer implements Language {
  @override
  String get code => "KH";

  @override
  String get login => "ចូលប្រើប្រាស់";

  @override
  String get logout => "ចាកចេញ";

  @override
  String get deleteMyAccount => "ធ្វើការលុបគណនី";

  @override
  String get removeAccount => "ធ្វើការលុបគណនី";

  @override
  String get msgRemoveAccount => "តើអ្នកចង់លុបគណនីរបស់អ្នកមែនទេ?";

  @override
  String get register => "ចុះឈ្មោះ";
}

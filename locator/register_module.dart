@module
abstract class RegisterModule {
  @singleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;

  @singleton
  @preResolve
  Future<SharedPreferences> get sharedPref => SharedPreferences.getInstance();

  @singleton
  @preResolve
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();
}

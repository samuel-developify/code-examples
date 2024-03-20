final httpServiceProvider = Provider<HttpService>((ref) {
  final AuthService authService = ref.watch(authServiceProvider);
  final String? accessToken = ref.watch(accessTokenProvider);

  return HttpService(ref, authService, accessToken);
});

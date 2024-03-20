class HttpService {
  final Ref _ref;
  final AuthService _authService;
  final String? _accessToken;

  HttpService(this._ref, this._authService, this._accessToken);

  Future<dynamic> get(String url) async {
    return _sendRequest(url, HttpMethod.GET);
  }

  Future<dynamic> post(String url, [Serializable? serializable]) async {
    final String? body = serializable == null ? null : json.encode(serializable.toJson());

    return _sendRequest(url, HttpMethod.POST, body);
  }

  Future<dynamic> put(String url, Serializable serializable) async {
    final body = json.encode(serializable.toJson());

    return _sendRequest(url, HttpMethod.PUT, body);
  }

  Map<String, String> get _headers => {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.authorizationHeader: 'Bearer $_accessToken',
      };

  Future<dynamic> _sendRequest(
    String url,
    HttpMethod method, [
    String? body,
  ]) async {
    Future<dynamic> request() async {
      final Uri uri = Uri.parse(url);
      final http.Response response = await switch (method) {
        HttpMethod.GET => http.get(uri, headers: _headers),
        HttpMethod.POST => http.post(uri, body: body, headers: _headers),
        HttpMethod.PUT => http.put(uri, body: body, headers: _headers),
      };

      if (response.statusCode >= HttpStatus.badRequest) {
        if (response.statusCode == HttpStatus.unauthorized) {
          throw InvalidAccessTokenException();
        } else {
          throw InvalidResponseCodeException(response.statusCode);
        }
      }

      return jsonDecode(response.body);
    }

    try {
      return await request();
    } on InvalidResponseCodeException catch (e, st) {
      await Sentry.captureMessage(
        'HttpClient - invalid response code',
        level: SentryLevel.error,
        params: [
          'REST method -> $method',
          'request url -> $url',
          'request body -> ${body ?? 'empty body'}',
          'response code -> ${e.statusCode}',
          'stack trace -> $st',
        ],
      );
      rethrow;
    } on InvalidAccessTokenException {
      final bool successfulRefresh = await _authService.refresh();

      if (!successfulRefresh) {
        _redirectToLogin();
        rethrow;
      }

      return request();
    }
  }

  void _redirectToLogin() {
    final goRouter = _ref.read(goRouterProvider);

    while (goRouter.canPop()) {
      goRouter.pop();
    }

    goRouter.goNamed(AppRoute.login.name);
  }
}

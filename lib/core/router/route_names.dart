class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String requests = 'requests';
  static const String createRequest = 'createRequest';
  static const String requestDetail = 'requestDetail';
  static const String donors = 'donors';
  static const String hospitals = 'hospitals';
  static const String profile = 'profile';

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String homePath = '/';
  static const String requestsPath = '/requests';
  static const String createRequestPath = '/requests/create';
  static const String requestDetailPath = '/requests/:requestId';
  static const String donorsPath = '/donors';
  static const String hospitalsPath = '/hospitals';
  static const String profilePath = '/profile';

  static String requestDetailRoute(String requestId) =>
      '/requests/$requestId';
}


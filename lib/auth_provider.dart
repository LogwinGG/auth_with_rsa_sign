import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

final authProvider = AsyncNotifierProvider.autoDispose<AuthProvider, String>(AuthProvider.new);

class AuthProvider extends AutoDisposeAsyncNotifier<String> {
  @override
  Future<String> build() async => '';

  Future<String?> authWithApple() async {
    final response = await AuthService().signInWithApple();
    state = AsyncData(response??'');
    return response;
  }
}
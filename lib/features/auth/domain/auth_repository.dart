abstract class AuthRepository {
  Stream<String?> get authStateChanges;
  String? get currentUser;
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
}

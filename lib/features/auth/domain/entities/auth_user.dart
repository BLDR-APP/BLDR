/// Usuário autenticado — entidade de domínio, sem dependência de Supabase.
class AuthUser {
  final String id;
  final String? email;
  final String? fullName;
  final bool emailConfirmed;

  const AuthUser({
    required this.id,
    this.email,
    this.fullName,
    this.emailConfirmed = false,
  });
}

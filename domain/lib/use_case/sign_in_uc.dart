import 'package:domain/data_repository/auth_data_repository.dart';
import 'package:domain/use_case/use_case.dart';
import 'package:meta/meta.dart';

class SignInUC extends UseCase<SignInUCParams, void> {
  SignInUC({
    @required this.authRepository,
  })  : assert(authRepository != null);

  final AuthDataRepository authRepository;

  @override
  Future<void> getRawFuture({SignInUCParams params}) =>
      authRepository.signIn(params.password);
}

class SignInUCParams {
  const SignInUCParams({
    @required this.password,
  })  :assert(password != null);

  final String password;
}

import 'package:domain/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_diary/presentation/auth/sign_in/sign_in_models.dart';
import 'package:personal_diary/presentation/common/input_status_vm.dart';
import 'package:personal_diary/presentation/common/subscription_utils.dart';
import 'package:domain/use_case/validate_password_uc.dart';
import 'package:domain/use_case/get_user_name_uc.dart';
import 'package:domain/use_case/sign_in_uc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:personal_diary/presentation/common/view_utils.dart';

class SignInBloc with SubscriptionBag {
  SignInBloc({
    @required this.validatePasswordFormatUC,
    @required this.signInUC,
    @required this.getUserNameUC,
  })  : assert(validatePasswordFormatUC != null),
        assert(signInUC != null),
        assert(getUserNameUC != null) {
    _onPasswordFocusLostSubject
        .listen(
          (_) => _validatePassword(_passwordInputStatusSubject),
        )
        .addTo(subscriptionsBag);

    _onSignInSubject
        .flatMap(
          (_) => Future.wait([
            _validatePassword(_passwordInputStatusSubject),
          ]).asStream(),
        )
        .flatMap(
          (_) => _signIn(),
        )
        .listen(_onNewStateSubject.add)
        .addTo(subscriptionsBag);

    _checkSignInFlow().listen(_onNewStateSubject.add).addTo(subscriptionsBag);
  }

  final ValidatePasswordUC validatePasswordFormatUC;
  final SignInUC signInUC;
  final GetUserNameUC getUserNameUC;

  // Sign in
  final _onSignInSubject = PublishSubject<void>();

  Sink<void> get onSignInSink => _onSignInSubject.sink;

  // State
  final _onNewStateSubject = BehaviorSubject<SignInState>();

  Stream<SignInState> get onNewState => _onNewStateSubject.stream;

  // Actions
  final _onNewActionSubject = PublishSubject<SignInAction>();

  Stream<SignInAction> get onNewAction => _onNewActionSubject.stream;

  // Password
  final _passwordInputStatusSubject = BehaviorSubject<InputStatusVM>();

  Stream<InputStatusVM> get passwordInputStatusStream =>
      _passwordInputStatusSubject.stream;

  final _onPasswordChangedSubject = BehaviorSubject<String>();

  Sink<String> get onPasswordChangedSink => _onPasswordChangedSubject.sink;

  String get _passwordValue => _onPasswordChangedSubject.stream.value;

  final _onPasswordFocusLostSubject = PublishSubject<void>();

  Sink<void> get onPasswordFocusLostSink => _onPasswordFocusLostSubject.sink;

   // Values
  String _userName;

  // Functions
  Future<void> _validatePassword(Sink<InputStatusVM> sink) =>
      validatePasswordFormatUC
          .getFuture(
            params: ValidatePasswordUCParams(password: _passwordValue),
          )
          .addStatusToSink(sink);

  Stream<SignInState> _checkSignInFlow() async* {
    try {
      _userName = await getUserNameUC.getFuture();
      _onNewStateSubject.add(
        SignInFlow(
          userName: _userName,
        ),
      );
    } catch (error) {
      _onNewStateSubject.add(
        SignInFlow(),
      );
    }
  }

  Stream<SignInState> _signIn() async* {
    yield Loading();

    try {
      await signInUC.getFuture(
        params: SignInUCParams(
          password: _passwordValue,
        ),
      );

      _onNewActionSubject.add(ShowMainContent());
    } catch (error) {
      yield SignInFlow(
        userName: _userName,
      );

      SignInActionError signInActionError;

      // Senha está errada
      if (error is InvalidCredentialsException) {
        signInActionError = ShowInvalidCredentialsError();
      } else if (error is NoUserCreatedException) {
        // Não tem usuário criado
        signInActionError = NoUserCreatedError();
      } else {
        // Erro genérico
        signInActionError = ShowGenericError();
      }

      _onNewActionSubject.add(
        signInActionError,
      );
    }
  }

  void dispose() {
    _onNewActionSubject.close();
    _onNewStateSubject.close();
    _passwordInputStatusSubject.close();
    _onPasswordChangedSubject.close();
    _onPasswordFocusLostSubject.close();
    super.disposeAll();
  }
}

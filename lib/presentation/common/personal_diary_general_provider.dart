import 'package:domain/data_repository/auth_data_repository.dart';
import 'package:domain/use_case/get_user_name_uc.dart';
import 'package:domain/use_case/sign_in_uc.dart';
import 'package:domain/use_case/sign_up_uc.dart';
import 'package:domain/use_case/validate_confirm_password_uc.dart';
import 'package:domain/use_case/validate_password_uc.dart';
import 'package:domain/use_case/validate_username_uc.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:personal_diary/data/cache/auth_cds.dart';
import 'package:personal_diary/data/repository/auth_repository.dart';
import 'package:personal_diary/data/secure/auth_sds.dart';
import 'package:personal_diary/presentation/auth/sign_in/sign_in_page.dart';
import 'package:personal_diary/presentation/auth/sign_up/sign_up_page.dart';
import 'package:personal_diary/presentation/common/route_name_builder.dart';
import 'package:personal_diary/presentation/home_screen.dart';
import 'package:personal_diary/presentation/post_list/post_list_page.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rxdart/rxdart.dart';

import 'navigation_utils.dart';

class PersonalDiaryGeneralProvider extends StatelessWidget {
  const PersonalDiaryGeneralProvider({
    @required this.child,
  }) : assert(child != null);

  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<FlutterSecureStorage>(
            create: (_) => const FlutterSecureStorage(),
          ),
          ..._buildStreamProviders(),
          ..._buildCDSProviders(),
          ..._buildSDSProviders(),
          ..._buildRepositoryProviders(),
          ..._buildUseCaseProviders(),
          ..._buildRouteFactory(),
        ],
        child: child,
      );

  List<SingleChildWidget> _buildRouteFactory() => [
        Provider<Router>(
          create: (context) => Router()
            ..define(
              '/',
              handler: Handler(
                handlerFunc: (context, params) => SignInPage.create(),
              ),
            )
            ..define(
              RouteNameBuilder.homePath,
              handler: Handler(
                handlerFunc: (context, params) => HomeScreen(),
              ),
            )
            ..define(
              RouteNameBuilder.signInPath,
              transitionType: TransitionType.native,
              handler: Handler(
                handlerFunc: (context, params) => SignInPage.create(),
              ),
            )
            ..define(
              RouteNameBuilder.signUpPath,
              transitionType: TransitionType.native,
              handler: Handler(
                handlerFunc: (context, params) => SignUpPage.create(),
              ),
            )
            ..define(
              RouteNameBuilder.postListPath,
              transitionType: TransitionType.native,
              handler: Handler(
                handlerFunc: (context, params) => PostListPage(),
              ),
            ),
        ),
        //Com a atualização do Flutter, o método "generator" do Router ficou com
        //bugs. Para resolver isso, criei uma extension chamada
        // routeGeneratorFactory, com isso eu posso utilizar o meu generator
        // sempre que precisar.
        ProxyProvider<Router, RouteFactory>(
          update: (context, router, _) =>
              (settings) => router.routeGeneratorFactory(context, settings),
        ),
      ];

  List<SingleChildWidget> _buildStreamProviders() => [
        Provider<PublishSubject<void>>(
          create: (_) => PublishSubject<void>(),
          dispose: (context, playersSubject) => playersSubject.close(),
        ),
      ];

  List<SingleChildWidget> _buildCDSProviders() => [
        ProxyProvider0<AuthCDS>(
          update: (_, __) => AuthCDS(),
        ),
      ];

  List<SingleChildWidget> _buildSDSProviders() => [
        ProxyProvider<FlutterSecureStorage, AuthSDS>(
          update: (_, secureStorage, __) =>
              AuthSDS(secureStorage: secureStorage),
        ),
      ];

  List<SingleChildWidget> _buildRepositoryProviders() => [
        ProxyProvider2<AuthSDS, AuthCDS, AuthDataRepository>(
          update: (_, authSDS, authCDS, __) => AuthRepository(
            authSDS: authSDS,
            authCDS: authCDS,
          ),
        ),
      ];

  List<SingleChildWidget> _buildUseCaseProviders() => [
        Provider<ValidateUsernameFormatUC>(
          create: (_) => ValidateUsernameFormatUC(),
        ),
        Provider<ValidatePasswordUC>(
          create: (_) => ValidatePasswordUC(),
        ),
        Provider<ValidateConfirmPasswordUC>(
          create: (_) => ValidateConfirmPasswordUC(),
        ),
        ProxyProvider<AuthDataRepository, SignInUC>(
          update: (_, authRepository, __) => SignInUC(
            authRepository: authRepository,
          ),
        ),
        ProxyProvider<AuthDataRepository, SignUpUC>(
          update: (_, authRepository, __) => SignUpUC(
            authRepository: authRepository,
          ),
        ),
        ProxyProvider<AuthDataRepository, GetUserNameUC>(
          update: (_, authRepository, __) => GetUserNameUC(
            authRepository: authRepository,
          ),
        ),
      ];
}

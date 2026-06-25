import 'package:bloc/bloc.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/usecases/sign_in_with_email_and_password.dart';
import '../../domain/usecases/sign_up_with_email_and_password.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required SignUpWithEmailAndPassword signUp,
    required SignInWithEmailAndPassword signIn,
  }) : _signUp = signUp,
       _signIn = signIn,
       super(const AuthState());

  final SignUpWithEmailAndPassword _signUp;
  final SignInWithEmailAndPassword _signIn;
  String _name = '';
  String _email = '';
  String _password = '';

  void changeMode(AuthMode mode) => emit(AuthState(mode: mode));

  void updateName(String name) => _name = name;

  void updateEmail(String email) => _email = email;

  void updatePassword(String password) => _password = password;

  Future<void> submit() async {
    final failure = _validateInputs();
    if (failure != null) return _emitFailure(failure.message);
    emit(state.copyWith(status: AuthStatus.submitting));
    final authUserOrFailure = state.mode == AuthMode.signUp
        ? await _signUp(_signUpParams())
        : await _signIn(_signInParams());
    authUserOrFailure.when(
      (_) => emit(state.copyWith(status: AuthStatus.success)),
      (failure) => _emitFailure(failure.message),
    );
  }

  AuthFailure? _validateInputs() {
    if (state.mode == AuthMode.signUp && _name.trim().length < 2) {
      return const AuthFailure(AuthFailureKind.invalidName);
    }
    if (EmailAddress.tryCreate(_email) == null) {
      return const AuthFailure(AuthFailureKind.invalidEmail);
    }
    if (_password.length < 6) {
      return const AuthFailure(AuthFailureKind.weakPassword);
    }
    return null;
  }

  SignUpParams _signUpParams() {
    return SignUpParams(
      name: _name,
      email: EmailAddress.tryCreate(_email)!,
      password: _password,
    );
  }

  SignInParams _signInParams() {
    return SignInParams(
      email: EmailAddress.tryCreate(_email)!,
      password: _password,
    );
  }

  void _emitFailure(String message) {
    emit(state.copyWith(status: AuthStatus.failure, message: message));
  }
}

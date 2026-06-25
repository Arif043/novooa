import 'package:bloc/bloc.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/usecases/sign_up_with_email_and_password.dart';
import 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required SignUpWithEmailAndPassword signUp})
    : _signUp = signUp,
      super(const SignUpInitial());

  final SignUpWithEmailAndPassword _signUp;
  String _name = '';
  String _email = '';
  String _password = '';

  void updateName(String name) => _name = name;

  void updateEmail(String email) => _email = email;

  void updatePassword(String password) => _password = password;

  Future<void> submit() async {
    final failure = _validateInputs();
    if (failure != null) {
      emit(SignUpFailure(failure.message));
      return;
    }
    emit(const SignUpSubmitting());
    final appUserOrFailure = await _signUp(_buildParams());
    appUserOrFailure.when(
      (_) => emit(const SignUpSuccess()),
      (failure) => emit(SignUpFailure(failure.message)),
    );
  }

  AuthFailure? _validateInputs() {
    if (_name.trim().length < 2) {
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

  SignUpParams _buildParams() {
    return SignUpParams(
      name: _name,
      email: EmailAddress.tryCreate(_email)!,
      password: _password,
    );
  }
}

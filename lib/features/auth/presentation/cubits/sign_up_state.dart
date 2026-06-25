sealed class SignUpState {
  const SignUpState();
}

class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

class SignUpSubmitting extends SignUpState {
  const SignUpSubmitting();
}

class SignUpSuccess extends SignUpState {
  const SignUpSuccess();
}

class SignUpFailure extends SignUpState {
  const SignUpFailure(this.message);

  final String message;
}

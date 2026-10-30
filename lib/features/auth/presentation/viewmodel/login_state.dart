import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState({
    this.employeeId = '',
    this.password = '',
    this.isSubmitting = false,
    this.submitError,
    this.success = false,
  });

  final String employeeId;
  final String password;
  final bool isSubmitting;
  final String? submitError;
  final bool success;

  bool get canSubmit =>
      employeeId.trim().isNotEmpty && password.isNotEmpty && !isSubmitting;

  LoginState copyWith({
    String? employeeId,
    String? password,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? success,
  }) {
    return LoginState(
      employeeId: employeeId ?? this.employeeId,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    password,
    isSubmitting,
    submitError,
    success,
  ];
}

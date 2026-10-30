import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginEmployeeIdChanged extends LoginEvent {
  const LoginEmployeeIdChanged(this.employeeId);

  final String employeeId;

  @override
  List<Object?> get props => [employeeId];
}

class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

class LoginSubmitRequested extends LoginEvent {
  const LoginSubmitRequested();
}

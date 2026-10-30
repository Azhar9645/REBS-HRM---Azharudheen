import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({AuthRepository? repository})
    : _repository = repository ?? AuthRepository(),
      super(const LoginState()) {
    on<LoginEmployeeIdChanged>(_onEmployeeIdChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitRequested>(_onSubmitRequested);
  }

  final AuthRepository _repository;

  void _onEmployeeIdChanged(LoginEmployeeIdChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(employeeId: event.employeeId, clearSubmitError: true));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: event.password, clearSubmitError: true));
  }

  Future<void> _onSubmitRequested(
    LoginSubmitRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      await _repository.login(
        employeeId: state.employeeId.trim(),
        password: state.password,
      );
      emit(state.copyWith(isSubmitting: false, success: true));
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: "Couldn't reach the server. Check your connection and try again.",
        ),
      );
    }
  }
}

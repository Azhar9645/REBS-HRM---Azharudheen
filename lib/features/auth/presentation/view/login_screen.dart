import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bottom_nav_bar/nav_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../viewmodel/login_bloc.dart';
import '../viewmodel/login_event.dart';
import '../viewmodel/login_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LoginBloc(), child: const _LoginView());
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: BlocConsumer<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state.success) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const NavBar()),
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              final bloc = context.read<LoginBloc>();

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 56,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.badge_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'REBS HRMS',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.screenTitle,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to manage attendance & leave',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 32),
                          SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Employee ID',
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: state.employeeId,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) =>
                                      bloc.add(LoginEmployeeIdChanged(value)),
                                  decoration: const InputDecoration(
                                    hintText: 'ID',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Password',
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 8),
                                _PasswordField(
                                  value: state.password,
                                  onChanged: (value) =>
                                      bloc.add(LoginPasswordChanged(value)),
                                  onSubmitted: state.canSubmit
                                      ? () => bloc.add(
                                          const LoginSubmitRequested(),
                                        )
                                      : null,
                                ),
                                if (state.submitError != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.rejectedBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.rejected,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            state.submitError!,
                                            style: const TextStyle(
                                              color: AppColors.rejected,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  label: state.isSubmitting
                                      ? 'Signing in…'
                                      : 'Sign in',
                                  onPressed: state.canSubmit
                                      ? () => bloc.add(
                                          const LoginSubmitRequested(),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: widget.value,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../../common/tools/flash.dart';
import '../../../../models/user_model.dart';
import '../../../../services/index.dart';
import '../../../../widgets/common/common_safe_area.dart';
import '../../../../widgets/common/loading_body.dart';

class ShopifyChangePasswordScreen extends StatefulWidget {
  const ShopifyChangePasswordScreen({super.key});

  @override
  State<ShopifyChangePasswordScreen> createState() =>
      _ShopifyChangePasswordScreenState();
}

class _ShopifyChangePasswordScreenState
    extends State<ShopifyChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Password requirements validation state
  bool _hasMinLength = false;
  bool _hasUpperLowerCase = false;
  bool _hasNumbersSpecialChars = false;

  @override
  void initState() {
    super.initState();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AutoHideKeyboard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).changePassword),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: LoadingBody(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SecurityNoticeWidget(),
                        const SizedBox(height: 24),
                        _SectionTitleWidget(
                            title: S.of(context).currentPasswordSection),
                        const SizedBox(height: 16),
                        _PasswordFieldWidget(
                          controller: _currentPasswordController,
                          label: S.of(context).currentPassword,
                          isVisible: _showCurrentPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                          validator: _validateCurrentPassword,
                        ),
                        const SizedBox(height: 24),
                        _SectionTitleWidget(
                            title: S.of(context).newPasswordSection),
                        const SizedBox(height: 16),
                        _PasswordFieldWidget(
                          controller: _newPasswordController,
                          label: S.of(context).newPassword,
                          isVisible: _showNewPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                          validator: _validateNewPassword,
                          onChange: _onNewPasswordChanged,
                        ),
                        const SizedBox(height: 16),
                        _PasswordFieldWidget(
                          controller: _confirmPasswordController,
                          label: S.of(context).confirmNewPassword,
                          isVisible: _showConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 16),
                        _PasswordTipsWidget(
                          hasMinLength: _hasMinLength,
                          hasUpperLowerCase: _hasUpperLowerCase,
                          hasNumbersSpecialChars: _hasNumbersSpecialChars,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _ChangePasswordButtonWidget(
                  isLoading: _isLoading,
                  onPressed: _onChangePasswordPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PASSWORD TIPS VALIDATION
  void _validatePasswordTips(String password) {
    setState(() {
      // At least 8 characters
      _hasMinLength = RegExp(r'.{8,}').hasMatch(password);

      // Contains both uppercase and lowercase
      _hasUpperLowerCase = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password);

      // Contains numbers and special characters
      _hasNumbersSpecialChars =
          RegExp(r'(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(password);
    });
  }

  void _onNewPasswordChanged(String value) {
    _validatePasswordTips(value);
  }

  // VALIDATION METHODS
  String? _validateCurrentPassword(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return S.of(context).pleaseEnterCurrentPassword;
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return S.of(context).pleaseEnterNewPassword;
    }
    if (value!.length < 8) {
      return S.of(context).passwordMustBeAtLeast8Characters;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return S.of(context).pleaseConfirmNewPassword;
    }
    if (value != _newPasswordController.text) {
      return S.of(context).confirmPasswordDoesNotMatch;
    }
    return null;
  }

  void _onChangePasswordPressed() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = context.read<UserModel>();
      final currentUser = userModel.user;

      if (currentUser == null) {
        throw Exception(
            'User not found'); // This is internal error, no need to localize
      }

      // Use callback pattern only - no need to await return value
      Services().widget.changePassword(
            email: currentUser.email ?? '',
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            onError: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              unawaited(FlashHelper.errorMessage(context, message: error));
            },
            onSuccess: (user) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              if (user != null) {
                userModel.setUser(user);
              }
              unawaited(
                FlashHelper.message(
                  context,
                  message: S.of(context).changePasswordSuccess,
                ),
              );
              Navigator.of(context)
                  .pop(true); // Return true to indicate password changed
            },
          );
    } catch (e) {
      FlashHelper.errorMessage(
        context,
        message: '${S.of(context).errorOccurred} ${e.toString()}',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// PRIVATE WIDGETS
class _SecurityNoticeWidget extends StatelessWidget {
  const _SecurityNoticeWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).accountSecurity,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.of(context).accountSecurityDescription,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleWidget extends StatelessWidget {
  final String title;

  const _SectionTitleWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PasswordFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final void Function(String)? onChange;

  const _PasswordFieldWidget({
    required this.controller,
    required this.label,
    required this.isVisible,
    required this.onToggleVisibility,
    this.validator,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
      ),
    );
  }
}

class _PasswordTipsWidget extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUpperLowerCase;
  final bool hasNumbersSpecialChars;

  const _PasswordTipsWidget({
    required this.hasMinLength,
    required this.hasUpperLowerCase,
    required this.hasNumbersSpecialChars,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).passwordTips,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        _RequirementItemWidget(
          text: S.of(context).atLeast8Characters,
          isSatisfied: hasMinLength,
        ),
        _RequirementItemWidget(
          text: S.of(context).shouldContainUpperLowercase,
          isSatisfied: hasUpperLowerCase,
        ),
        _RequirementItemWidget(
          text: S.of(context).shouldContainNumbersSpecialChars,
          isSatisfied: hasNumbersSpecialChars,
        ),
      ],
    );
  }
}

class _RequirementItemWidget extends StatelessWidget {
  final String text;
  final bool isSatisfied;

  const _RequirementItemWidget({
    required this.text,
    required this.isSatisfied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isSatisfied
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey('check'),
                    size: 16,
                    color: colorScheme.primary,
                  )
                : const SizedBox(
                    key: ValueKey('empty'),
                    width: 16,
                    height: 16,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSatisfied
                    ? colorScheme.onSurface.withValues(alpha: 0.8)
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ChangePasswordButtonWidget({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CommonSafeArea(
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
          ),
          child: Text(
            S.of(context).changePassword,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

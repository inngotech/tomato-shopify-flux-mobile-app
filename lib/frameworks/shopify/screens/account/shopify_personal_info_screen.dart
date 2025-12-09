import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

import '../../../../common/config.dart';
import '../../../../common/tools/flash.dart';
import '../../../../models/entities/user.dart';
import '../../../../models/user_model.dart';
import '../../../../services/index.dart';
import '../../../../widgets/common/common_safe_area.dart';
import '../../../../widgets/common/loading_body.dart';
import '../../../../widgets/common/phone_number_field_widget.dart';

class ShopifyPersonalInfoScreen extends StatefulWidget {
  const ShopifyPersonalInfoScreen({super.key});

  @override
  State<ShopifyPersonalInfoScreen> createState() =>
      _ShopifyPersonalInfoScreenState();
}

class _ShopifyPersonalInfoScreenState extends State<ShopifyPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  PhoneNumber? _initialPhoneNumber;
  PhoneNumber? _currentPhoneNumber;

  bool _isLoading = false;

  User get user => context.read<UserModel>().user!;

  @override
  void initState() {
    super.initState();

    final user = context.read<UserModel>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    _initializePhoneNumber();
  }

  void _initializePhoneNumber() async {
    final user = context.read<UserModel>().user;
    final phoneNumber = user?.phoneNumber?.trim();

    if (kPhoneNumberConfig.enablePhoneNumberValidation) {
      try {
        if (phoneNumber?.isNotEmpty ?? false) {
          _initialPhoneNumber = await PhoneNumber.getParsablePhoneNumber(
            PhoneNumber(
              dialCode: kPhoneNumberConfig.dialCodeDefault,
              isoCode: kPhoneNumberConfig.countryCodeDefault,
              phoneNumber: phoneNumber,
            ),
          );
        }
        // Default PhoneNumber object for initialization
        _initialPhoneNumber ??= PhoneNumber(
          dialCode: kPhoneNumberConfig.dialCodeDefault,
          isoCode: kPhoneNumberConfig.countryCodeDefault,
        );
        _currentPhoneNumber = _initialPhoneNumber;
      } catch (e) {
        // Fallback to default
        _initialPhoneNumber = PhoneNumber(
          dialCode: kPhoneNumberConfig.dialCodeDefault,
          isoCode: kPhoneNumberConfig.countryCodeDefault,
        );
        _currentPhoneNumber = _initialPhoneNumber;
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AutoHideKeyboard(
      child: Scaffold(
        // backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(S.of(context).personalInformation),
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
                        _SectionTitleWidget(
                            title: S.of(context).basicInformation),
                        const SizedBox(height: 16),
                        _InputFieldWidget(
                          controller: _firstNameController,
                          label: S.of(context).firstName,
                          icon: Icons.person_outline,
                          validator: _validateFirstName,
                        ),
                        const SizedBox(height: 16),
                        _InputFieldWidget(
                          controller: _lastNameController,
                          label: S.of(context).lastName,
                          icon: Icons.person_outline,
                          validator: _validateLastName,
                        ),
                        const SizedBox(height: 24),
                        _SectionTitleWidget(
                            title: S.of(context).contactInformation),
                        const SizedBox(height: 16),
                        _InputFieldWidget(
                          controller: _emailController,
                          label: S.of(context).email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          enabled:
                              false, // Email usually can't be changed in Shopify
                        ),
                        const SizedBox(height: 16),
                        const _DisplayNameFieldWidget(),
                        if (user.isSocial == false) ...[
                          const SizedBox(height: 16),
                          PhoneNumberFieldWidget(
                            phoneController: _phoneController,
                            initialPhoneNumber: _initialPhoneNumber,
                            onPhoneNumberChanged: (phoneNumber) {
                              _currentPhoneNumber = phoneNumber;
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _UpdateButtonWidget(
                  isLoading: _isLoading,
                  onPressed: _onUpdatePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPhoneNumberForUpdate() {
    if (kPhoneNumberConfig.enablePhoneNumberValidation &&
        _currentPhoneNumber != null) {
      return _currentPhoneNumber!.phoneNumber ?? '';
    }
    return _phoneController.text.trim();
  }

  // VALIDATION METHODS
  String? _validateFirstName(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return S.of(context).pleaseEnterFirstName;
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return S.of(context).pleaseEnterLastName;
    }
    return null;
  }

  void _onUpdatePressed() async {
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
        throw Exception('User not found');
      }

      // Create updated user object
      final updatedUser = User.init(
        id: currentUser.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: currentUser.email,
        // Keep original email
        phoneNumber: _phoneController.text.trim(),
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        username: currentUser.username,
        cookie: currentUser.cookie,
        picture: currentUser.picture,
        isSocial: currentUser.isSocial,
      );

      // Update user info through service
      Services().widget.updateUserInfo(
            loggedInUser: updatedUser,
            currentPassword: '',
            // Not needed for personal info update
            userDisplayName:
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            userFirstname: _firstNameController.text.trim(),
            userLastname: _lastNameController.text.trim(),
            userPhone: _getPhoneNumberForUpdate(),
            onError: (error) {
              unawaited(FlashHelper.errorMessage(context, message: error));
            },
            onSuccess: (user) {
              userModel.setUser(user);
              unawaited(
                FlashHelper.message(
                  context,
                  message: S.of(context).updateInformationSuccess,
                ),
              );
              Navigator.of(context).pop();
            },
          );
    } catch (e) {
      unawaited(
        FlashHelper.errorMessage(
          context,
          message: '${S.of(context).errorOccurred} ${e.toString()}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// PRIVATE WIDGETS
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

class _InputFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;

  const _InputFieldWidget({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            // labelText: label,
            prefixIcon: Icon(icon),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            filled: enabled,
            fillColor: enabled
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _DisplayNameFieldWidget extends StatelessWidget {
  const _DisplayNameFieldWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.read<UserModel>().user;
    final displayName = _getUserDisplayName(context, user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(
                Icons.info_outline,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.of(context).displayNameDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _getUserDisplayName(BuildContext context, User? user) {
    if (user?.name?.isNotEmpty == true) {
      return user!.name!;
    }

    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    return S.of(context).noDisplayName;
  }
}

class _UpdateButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _UpdateButtonWidget({
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            S.of(context).updateInformation,
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

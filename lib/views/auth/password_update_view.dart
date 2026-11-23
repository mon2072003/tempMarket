import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/supabase_service.dart';

class PasswordUpdateView extends StatefulWidget {
  const PasswordUpdateView({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<PasswordUpdateView> createState() => _PasswordUpdateViewState();
}

class _PasswordUpdateViewState extends State<PasswordUpdateView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await SupabaseService().changePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.isArabic
                ? '\u{62a}\u{645}\u{20}\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{20}\u{628}\u{646}\u{62c}\u{627}\u{62d}\u{2e}'
                : 'Password updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      } else {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.isArabic
                ? '\u{62a}\u{639}\u{630}\u{631}\u{20}\u{62a}\u{62d}\u{62f}\u{64a}\u{62b}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{2e}'
                : 'Could not update password: $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = loc.isArabic;
    final title = isArabic
        ? '\u{62a}\u{63a}\u{64a}\u{64a}\u{631}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}'
        : 'Change password';
    final newPasswordLabel = isArabic
        ? '\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{20}\u{627}\u{644}\u{62c}\u{62f}\u{64a}\u{62f}\u{629}'
        : 'New password';
    final confirmPasswordLabel = isArabic
        ? '\u{62a}\u{623}\u{643}\u{64a}\u{62f}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{20}\u{627}\u{644}\u{62c}\u{62f}\u{64a}\u{62f}\u{629}'
        : 'Confirm new password';
    final tooShortMessage = isArabic
        ? '\u{64a}\u{62c}\u{628}\u{20}\u{623}\u{646}\u{20}\u{62a}\u{62a}\u{643}\u{648}\u{646}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{20}\u{645}\u{646}\u{20}\u{38}\u{20}\u{623}\u{62d}\u{631}\u{641}\u{20}\u{639}\u{644}\u{649}\u{20}\u{627}\u{644}\u{623}\u{642}\u{644}\u{2e}'
        : 'Use at least 8 characters.';
    final mismatchMessage = isArabic
        ? '\u{643}\u{644}\u{645}\u{62a}\u{627}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{20}\u{63a}\u{64a}\u{631}\u{20}\u{645}\u{62a}\u{637}\u{627}\u{628}\u{642}\u{62a}\u{64a}\u{646}\u{2e}'
        : 'Passwords do not match.';
    final submitLabel = isArabic
        ? '\u{62d}\u{641}\u{638}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}'
        : 'Save password';
    final helperText = isArabic
        ? '\u{627}\u{633}\u{62a}\u{62e}\u{62f}\u{645}\u{20}\u{38}\u{20}\u{623}\u{62d}\u{631}\u{641}\u{20}\u{639}\u{644}\u{649}\u{20}\u{627}\u{644}\u{623}\u{642}\u{644}\u{2e}'
        : 'Choose a password with at least 8 characters.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 32,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          helperText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          textDirection: isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: newPasswordLabel,
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              tooltip: isArabic
                                  ? '\u{625}\u{638}\u{647}\u{627}\u{631}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}'
                                  : 'Show or hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 8)
                              ? tooShortMessage
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscureConfirm,
                          textDirection: isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _busy ? null : _submit(),
                          decoration: InputDecoration(
                            labelText: confirmPasswordLabel,
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              tooltip: isArabic
                                  ? '\u{625}\u{638}\u{647}\u{627}\u{631}\u{20}\u{643}\u{644}\u{645}\u{629}\u{20}\u{627}\u{644}\u{645}\u{631}\u{648}\u{631}'
                                  : 'Show or hide password',
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value != _password.text ? mismatchMessage : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _submit,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(submitLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

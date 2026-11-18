import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import 'auth_layout.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegistered;
  final VoidCallback onSwitchToLogin;
  final VoidCallback? onBackToLanding;

  const RegisterPage({
    super.key,
    required this.onRegistered,
    required this.onSwitchToLogin,
    this.onBackToLanding,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordConfirmation = TextEditingController();
  bool loading = false, obscure = true;
  String? errorKey;
  String? errorRaw;

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        passwordConfirmation.text.isEmpty) {
      setState(() {
        errorKey = 'a_fill_all';
        errorRaw = null;
      });
      return;
    }
    if (password.text != passwordConfirmation.text) {
      setState(() {
        errorKey = 'a_pw_mismatch';
        errorRaw = null;
      });
      return;
    }
    setState(() {
      loading = true;
      errorKey = null;
      errorRaw = null;
    });
    try {
      await ApiService.instance.register(
        name.text.trim(),
        email.text.trim(),
        password.text,
        passwordConfirmation.text,
      );
      // Connexion automatique après l'inscription.
      await ApiService.instance.login(email.text.trim(), password.text);
      if (mounted) widget.onRegistered();
    } catch (e) {
      if (mounted) setState(() => errorRaw = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    passwordConfirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final error = errorKey != null ? context.t(errorKey!) : errorRaw;

    return AuthLayout(
      onBack: widget.onBackToLanding,
      brandTitle: context.t('a_reg_brand'),
      brandChecks: [
        context.t('a_rcheck1'),
        context.t('a_rcheck2'),
        context.t('a_rcheck3'),
      ],
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(
            title: context.t('a_reg_title'),
            subtitle: context.t('a_reg_sub'),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              labelText: context.t('a_name'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: context.t('a_email'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: obscure,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: context.t('a_password8'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordConfirmation,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: context.t('a_confirm'),
              prefixIcon: const Icon(Icons.lock_reset_rounded),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            FormError(error),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: loading ? null : submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)),
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
                  )
                : Text(context.t('a_reg_btn'), style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${context.t('a_have_account')} ',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
              GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: Text(
                  context.t('a_login_btn'),
                  style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

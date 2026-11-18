import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'auth_layout.dart';
import 'forgot_password_dialog.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback? onSwitchToRegister;
  final VoidCallback? onBackToLanding;

  const LoginPage({
    super.key,
    required this.onLogin,
    this.onSwitchToRegister,
    this.onBackToLanding,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false, obscure = true, rememberMe = true;

  /// On garde la clé de traduction (et non le texte) pour que le message
  /// d'erreur change aussi de langue si l'utilisateur bascule FR/EN.
  String? errorKey;
  String? errorRaw;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() {
        errorKey = 'a_login_empty';
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
      await ApiService.instance.login(email.text.trim(), password.text);
      if (mounted) widget.onLogin();
    } catch (e) {
      if (mounted) setState(() => errorRaw = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final error = errorKey != null ? context.t(errorKey!) : errorRaw;

    return AuthLayout(
      onBack: widget.onBackToLanding,
      brandTitle: context.t('a_brand_title'),
      brandChecks: [
        context.t('a_check1'),
        context.t('a_check2'),
        context.t('a_check3'),
      ],
      showChartIllustration: true,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(
            title: context.t('a_login_title'),
            subtitle: context.t('a_login_sub'),
          ),
          const SizedBox(height: 28),
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
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              labelText: context.t('a_password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => rememberMe = !rememberMe),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: (v) => setState(() => rememberMe = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('a_remember'),
                        style: TextStyle(fontSize: 13, color: p.text),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ForgotPasswordDialog(initialEmail: email.text.trim()),
                  );
                },
                child: Text(context.t('a_forgot'), style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            FormError(error),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)),
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
                  )
                : Text(context.t('a_login_btn'), style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(context.t('a_or'), style: TextStyle(color: p.muted, fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => showMessage(context, context.t('a_google_msg')),
            icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: AppColors.primary),
            label: Text(context.t('a_google')),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${context.t('a_no_account')} ',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
              GestureDetector(
                onTap: widget.onSwitchToRegister,
                child: Text(
                  context.t('a_signup_link'),
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

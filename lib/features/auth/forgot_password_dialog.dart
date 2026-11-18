import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_widgets.dart';

enum _OtpStep { email, verifyOtp, resetPassword }

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordDialog({super.key, this.initialEmail});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  _OtpStep _step = _OtpStep.email;

  late final TextEditingController _emailCtrl;
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Étape 1 : Demande du code OTP via POST /auth/password/forgot/
  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Veuillez saisir une adresse email valide.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.post(
        'auth/password/forgot/',
        {'email': email},
        auth: false,
      );

      final detail = res['detail']?.toString() ?? 'Un code OTP a été envoyé à votre email.';
      if (mounted) {
        setState(() {
          _step = _OtpStep.verifyOtp;
          _infoMessage = detail;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Étape 2 : Vérification du code OTP via POST /auth/password/verify-otp/
  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (otp.length != 6 || int.tryParse(otp) == null) {
      setState(() => _error = 'Veuillez saisir le code OTP à 6 chiffres.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.instance.post(
        'auth/password/verify-otp/',
        {'email': email, 'otp': otp},
        auth: false,
      );

      if (mounted) {
        setState(() {
          _step = _OtpStep.resetPassword;
          _infoMessage = 'Code OTP vérifié. Saisissez votre nouveau mot de passe.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Étape 3 : Réinitialisation du mot de passe via POST /auth/password/reset/
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 8) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }

    if (pass != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.instance.post(
        'auth/password/reset/',
        {
          'email': email,
          'otp': otp,
          'password': pass,
          'password_confirmation': confirm,
        },
        auth: false,
      );

      if (mounted) {
        Navigator.pop(context, true);
        showMessage(context, 'Mot de passe réinitialisé avec succès ! Connectez-vous.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          IconBadge(
            icon: Icons.lock_reset_rounded,
            color: p.primary,
            background: p.primarySoft,
            size: 38,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Récupération du compte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_infoMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: TextStyle(fontSize: 12.5, color: p.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ÉTAPE 1 : Email
              if (_step == _OtpStep.email) ...[
                const Text(
                  'Saisissez votre adresse email pour recevoir un code OTP de réinitialisation.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],

              // ÉTAPE 2 : Saisie OTP
              if (_step == _OtpStep.verifyOtp) ...[
                Text(
                  'Un code OTP à 6 chiffres a été envoyé à ${_emailCtrl.text}.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: p.title,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Code OTP (6 chiffres)',
                    hintText: '123456',
                    counterText: '',
                  ),
                ),
              ],

              // ÉTAPE 3 : Nouveau mot de passe
              if (_step == _OtpStep.resetPassword) ...[
                const Text(
                  'Définissez votre nouveau mot de passe sécurisé.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe (8+ caractères)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscurePass,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.expenseSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: p.expense, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () {
                  if (_step == _OtpStep.email) {
                    _requestOtp();
                  } else if (_step == _OtpStep.verifyOtp) {
                    _verifyOtp();
                  } else {
                    _resetPassword();
                  }
                },
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
                )
              : Text(_step == _OtpStep.email
                  ? 'Envoyer l’OTP'
                  : (_step == _OtpStep.verifyOtp ? 'Vérifier l’OTP' : 'Réinitialiser')),
        ),
      ],
    );
  }
}

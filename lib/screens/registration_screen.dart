import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../theme/app_colors.dart';
import 'school_picker_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrazione',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Crea un profilo con i tuoi dati. Subito dopo sceglierai la tua '
            'scuola per ricevere consigli su misura.',
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Nome'),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Inserisci il tuo nome';
                    if (v.length < 2) {
                      return 'Il nome deve avere almeno 2 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: _inputDecoration('Email'),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(v);
                    if (v.isEmpty) return 'Inserisci il tuo indirizzo email';
                    if (!valid) return 'Inserisci un indirizzo email valido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: _inputDecoration('Password'),
                  validator: (value) {
                    final v = value ?? '';
                    final hasLetter = v.contains(RegExp(r'[A-Za-z]'));
                    final hasDigit = v.contains(RegExp(r'\d'));
                    if (v.length < 8) {
                      return 'Almeno 8 caratteri';
                    }
                    if (!hasLetter || !hasDigit) {
                      return 'Usa almeno una lettera e un numero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration('Conferma password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Conferma la password';
                    }
                    if (value != _passwordController.text) {
                      return 'Le password non coincidono';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: c.accent,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Continua'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'La password è salvata solo su questo dispositivo.',
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final c = AppColors.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: c.surface,
      labelStyle: TextStyle(color: c.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await AuthStore.instance.registerManual(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      schoolLevelId: '',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchoolPickerScreen(onSaved: () => _goToHome(context)),
      ),
    );
  }

  static void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

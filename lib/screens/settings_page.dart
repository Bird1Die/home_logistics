import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/unfocus_on_tap.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.canChangePassword,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool canChangePassword;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSavingPassword = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;
    if (password.length < 6) {
      setState(() {
        _message = 'La password deve avere almeno 6 caratteri';
      });
      return;
    }
    if (password != confirmation) {
      setState(() {
        _message = 'Le password non coincidono';
      });
      return;
    }

    setState(() {
      _isSavingPassword = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _message = 'Password aggiornata';
      });
    } on AuthException catch (error) {
      setState(() {
        _message = error.message;
      });
    } catch (_) {
      setState(() {
        _message = 'Password non aggiornata';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: SafeArea(
        child: UnfocusOnTap(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tema dark'),
                value: isDark,
                onChanged: (value) => widget.onThemeModeChanged(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
              const Divider(height: 32),
              Text(
                'Password',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                enabled: widget.canChangePassword,
                decoration: const InputDecoration(
                  labelText: 'Nuova password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                enabled: widget.canChangePassword,
                decoration: const InputDecoration(
                  labelText: 'Conferma password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    widget.canChangePassword ? _changePassword() : null,
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message == 'Password aggiornata'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.canChangePassword && !_isSavingPassword
                    ? _changePassword
                    : null,
                icon: _isSavingPassword
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset_outlined),
                label: const Text('Cambia password'),
              ),
              if (!widget.canChangePassword) ...[
                const SizedBox(height: 8),
                Text(
                  'Disponibile quando accedi con Supabase.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

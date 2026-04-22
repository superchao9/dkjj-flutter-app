import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'captcha_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');

  @override
  void initState() {
    super.initState();
    final tenantName = context.read<AuthController>().tenantName;
    if (tenantName != null && tenantName.isNotEmpty) {
      _tenantNameController.text = tenantName;
    }
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = context.read<AuthController>();
    final repository = context.read<AuthRepository>();
    final captchaVerification = await showCaptchaDialog(
      context,
      repository: repository,
    );
    if (!mounted || captchaVerification == null || captchaVerification.isEmpty) {
      return;
    }
    final success = await controller.login(
      tenantName: _tenantNameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      captchaVerification: captchaVerification,
    );
    if (!mounted) {
      return;
    }
    if (!success && controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06172E), Color(0xFF103A69), Color(0xFF17A4A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        if (!isCompact)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 28),
                              child: _LoginHero(theme: theme),
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment:
                                isCompact ? Alignment.center : Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCompact) ...[
                                          Text(
                                            '低空基础设施管理系统',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '面向巡检、项目建设、设备资产与运行维护的一体化移动端。',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '账号登录',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: const Color(0xFF0C4A6E),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '欢迎回来',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '请输入租户名称、账号与密码完成登录，登录前需要进行安全验证。',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        TextFormField(
                                          controller: _tenantNameController,
                                          decoration: const InputDecoration(
                                            labelText: '租户名称',
                                            hintText: '请输入租户名称',
                                            prefixIcon: Icon(Icons.apartment_outlined),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入租户名称';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _usernameController,
                                          decoration: const InputDecoration(
                                            labelText: '用户名',
                                            hintText: '请输入用户名',
                                            prefixIcon: Icon(Icons.person_outline),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return '请输入用户名';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: '密码',
                                            hintText: '请输入密码',
                                            prefixIcon: Icon(Icons.lock_outline),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return '请输入密码';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '点击登录后会弹出滑动验证码，验证通过后继续登录。',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Consumer<AuthController>(
                                          builder: (context, controller, _) {
                                            return SizedBox(
                                              width: double.infinity,
                                              child: FilledButton(
                                                onPressed:
                                                    controller.isSubmitting ? null : _submit,
                                                style: FilledButton.styleFrom(
                                                  minimumSize: const Size.fromHeight(54),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(18),
                                                  ),
                                                ),
                                                child: controller.isSubmitting
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Text('登录'),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            '移动巡检 · 项目建设 · 运维协同',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '低空基础设施管理系统',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 520,
          child: Text(
            '统一承接巡检工单、项目建设、设备资产与流程审批，让一线团队在移动端也能高效完成日常业务。',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _HeroTag(icon: Icons.flight_takeoff_outlined, text: '巡检任务闭环'),
            _HeroTag(icon: Icons.hub_outlined, text: '设备资产联动'),
            _HeroTag(icon: Icons.approval_outlined, text: '审批流程贯通'),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

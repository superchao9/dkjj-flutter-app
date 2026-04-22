import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

Future<String?> showCaptchaDialog(
  BuildContext context, {
  required AuthRepository repository,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CaptchaDialog(repository: repository),
  );
}

class _CaptchaDialog extends StatefulWidget {
  const _CaptchaDialog({required this.repository});

  final AuthRepository repository;

  @override
  State<_CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<_CaptchaDialog> {
  static const double _imageWidth = 320;
  static const double _imageHeight = 160;
  static const double _serverWidth = 310;
  static const double _pieceWidth = 48;

  CaptchaChallenge? _challenge;
  Uint8List? _backgroundBytes;
  Uint8List? _pieceBytes;
  bool _loading = true;
  bool _verifying = false;
  String? _errorMessage;
  double _sliderValue = 0;

  double get _maxOffset => _imageWidth - _pieceWidth;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _loading = true;
      _verifying = false;
      _errorMessage = null;
      _sliderValue = 0;
    });
    try {
      final challenge = await widget.repository.fetchCaptcha();
      setState(() {
        _challenge = challenge;
        _backgroundBytes = base64Decode(challenge.originalImageBase64);
        _pieceBytes = base64Decode(challenge.jigsawImageBase64);
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _readableMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _verify() async {
    final challenge = _challenge;
    if (challenge == null || _verifying) {
      return;
    }
    setState(() {
      _verifying = true;
      _errorMessage = null;
    });
    final serverX = (_sliderValue * _serverWidth) / _imageWidth;
    try {
      final captchaVerification = await widget.repository.verifyCaptcha(
        challenge: challenge,
        x: double.parse(serverX.toStringAsFixed(2)),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(captchaVerification);
    } catch (error) {
      setState(() {
        _verifying = false;
        _errorMessage = _readableMessage(error);
        _sliderValue = 0;
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        await _loadCaptcha();
      }
    }
  }

  String _readableMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return '验证码校验失败，请重试';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '安全验证',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '向右滑动完成拼图，验证通过后继续登录。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadCaptcha,
                  tooltip: '刷新验证码',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: _imageWidth,
              height: _imageHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD7E2F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildCaptchaCanvas(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _verifying ? '正在校验验证码...' : '拖动滑块完成验证',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF0EA5E9),
                inactiveTrackColor: const Color(0xFFE2E8F0),
                thumbColor: const Color(0xFF0284C7),
                overlayColor: const Color(0x220284C7),
                trackHeight: 8,
              ),
              child: Slider(
                value: _sliderValue.clamp(0, _maxOffset),
                min: 0,
                max: _maxOffset,
                onChanged: (_loading || _verifying)
                    ? null
                    : (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                onChangeEnd: (_loading || _verifying) ? null : (_) => _verify(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _verifying ? null : () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptchaCanvas() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_backgroundBytes == null || _pieceBytes == null) {
      return Center(
        child: Text(
          _errorMessage ?? '验证码加载失败',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _backgroundBytes!,
          fit: BoxFit.cover,
        ),
        Positioned(
          left: _sliderValue,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: SizedBox(
              width: _pieceWidth,
              height: _imageHeight,
              child: Image.memory(
                _pieceBytes!,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

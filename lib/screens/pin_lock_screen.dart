import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

enum PinMode { unlock, setup, change }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinLockScreen({
    super.key,
    this.mode = PinMode.unlock,
    this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _tempSetupPin = '';
  int _setupStep = 1; // 1: Enter new, 2: Confirm new
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final Map<String, String> _digitLetters = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '',
  };

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 14.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _handlePinComplete() async {
    final pin = _enteredPin;

    if (widget.mode == PinMode.unlock) {
      final isValid = await SecurityService.instance.verifyPin(pin);
      if (isValid) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _triggerError('Incorrect Passcode');
      }
    } else if (widget.mode == PinMode.setup || widget.mode == PinMode.change) {
      if (_setupStep == 1) {
        setState(() {
          _tempSetupPin = pin;
          _enteredPin = '';
          _setupStep = 2;
        });
      } else {
        if (pin == _tempSetupPin) {
          await SecurityService.instance.setPin(pin);
          if (mounted) {
            AppToast.success(context, 'Passcode configured successfully!');
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          _triggerError('Passcodes do not match');
          setState(() {
            _setupStep = 1;
            _tempSetupPin = '';
          });
        }
      }
    }
  }

  void _triggerError(String message) {
    _shakeController.forward(from: 0.0);
    setState(() {
      _errorMessage = message;
      _enteredPin = '';
    });
  }

  String _getTitle() {
    if (widget.mode == PinMode.unlock) {
      return 'Enter Passcode';
    }
    if (_setupStep == 1) {
      return 'Set Passcode';
    }
    return 'Verify Passcode';
  }

  String _getSubtitle() {
    if (widget.mode == PinMode.unlock) {
      return 'Your private tasks and notes are locked.';
    }
    if (_setupStep == 1) {
      return 'Enter a 4-digit passcode for this app';
    }
    return 'Re-enter your new passcode to confirm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.mode != PinMode.unlock
          ? AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      // Apple Lock Icon
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 36,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getTitle(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getSubtitle(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // iOS Passcode 4 Dots with shake animation
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                _shakeAnimation.value *
                                    (_shakeAnimation.value % 2 == 0 ? 1 : -1),
                                0),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _enteredPin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? AppTheme.textPrimary : Colors.transparent,
                                border: Border.all(
                                  color: isFilled
                                      ? AppTheme.textPrimary
                                      : const Color(0xFFC7C7CC),
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: AppTheme.accentCoral,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Authentic iOS Keypad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        child: Column(
                          children: [
                            _buildKeypadRow(['1', '2', '3']),
                            const SizedBox(height: 16),
                            _buildKeypadRow(['4', '5', '6']),
                            const SizedBox(height: 16),
                            _buildKeypadRow(['7', '8', '9']),
                            const SizedBox(height: 16),
                            _buildBottomKeypadRow(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildBottomKeypadRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Empty space or Cancel
        const SizedBox(width: 76, height: 76),
        _buildKeypadButton('0'),
        // Backspace Button
        SizedBox(
          width: 76,
          height: 76,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(38),
              onTap: _onBackspace,
              child: const Center(
                child: Icon(
                  Icons.backspace_outlined,
                  color: AppTheme.textPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    final letters = _digitLetters[digit] ?? '';

    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: const Color(0xFFF2F2F7),
        shape: const CircleBorder(),
        child: InkWell(
          borderRadius: BorderRadius.circular(38),
          splashColor: AppTheme.primary.withValues(alpha: 0.15),
          highlightColor: AppTheme.primary.withValues(alpha: 0.08),
          onTap: () => _onKeyPress(digit),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                if (letters.isNotEmpty)
                  Text(
                    letters,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                      height: 1.0,
                    ),
                  )
                else
                  const SizedBox(height: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/profile_number_box.dart';
import '../widgets/profile_mobile_field.dart';
import '../widgets/profile_otp_field.dart';
import '../widgets/profile_orange_button.dart';

class ChangeMobileFlow
    extends StatefulWidget {
  final String currentNumber;
  final ValueChanged<String> onChanged;

  const ChangeMobileFlow({
    super.key,
    required this.currentNumber,
    required this.onChanged,
  });

  @override
  State<ChangeMobileFlow>
      createState() =>
          _ChangeMobileFlowState();
}

class _ChangeMobileFlowState
    extends State<ChangeMobileFlow> {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  static const Color textGrey =
      Color(0xFF707070);

  int step = 1;

  final TextEditingController
      currentOtpController =
      TextEditingController();

  final TextEditingController
      newNumberController =
      TextEditingController();

  final TextEditingController
      confirmNumberController =
      TextEditingController();

  @override
  void dispose() {
    currentOtpController.dispose();
    newNumberController.dispose();
    confirmNumberController.dispose();

    super.dispose();
  }

  // ============================================================
  // GET OTP
  // ============================================================

  void _getCurrentOtp() {
    setState(() {
      step = 2;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        backgroundColor:
            Colors.green,

        content: Text(
          'OTP sent to your current mobile number.',
        ),
      ),
    );
  }

  // ============================================================
  // VERIFY CURRENT OTP
  // ============================================================

  void _verifyCurrentOtp() {
    final String otp =
        currentOtpController.text.trim();

    if (otp.isEmpty) {
      _showError(
        'Please enter OTP.',
      );

      return;
    }

    if (otp.length != 6) {
      _showError(
        'OTP must be exactly 6 digits.',
      );

      return;
    }

    // ----------------------------------------------------------
    // DEMO OTP
    // Later Firebase Phone Auth will be connected here.
    // ----------------------------------------------------------

    if (otp != '123456') {
      _showError(
        'Invalid OTP. Demo OTP is 123456.',
      );

      return;
    }

    setState(() {
      step = 3;
    });
  }

  // ============================================================
  // SAVE NEW NUMBER
  // ============================================================

  void _saveNewNumber() {
    final String newNumber =
        newNumberController.text.trim();

    final String confirmNumber =
        confirmNumberController.text.trim();

    if (newNumber.isEmpty) {
      _showError(
        'Please enter new mobile number.',
      );

      return;
    }

    if (newNumber.length != 10) {
      _showError(
        'Mobile number must be exactly 10 digits.',
      );

      return;
    }

    if (confirmNumber.isEmpty) {
      _showError(
        'Please confirm your mobile number.',
      );

      return;
    }

    if (confirmNumber.length != 10) {
      _showError(
        'Confirm mobile number must be exactly 10 digits.',
      );

      return;
    }

    if (newNumber != confirmNumber) {
      _showError(
        'New mobile number and confirm number do not match.',
      );

      return;
    }

    final String cleanCurrentNumber =
        widget.currentNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final String currentLast10 =
        cleanCurrentNumber.length >= 10
            ? cleanCurrentNumber.substring(
                cleanCurrentNumber.length - 10,
              )
            : cleanCurrentNumber;

    if (newNumber == currentLast10) {
      _showError(
        'New number must be different from current number.',
      );

      return;
    }

    final String formattedNumber =
        '+91 '
        '${newNumber.substring(0, 5)} '
        '${newNumber.substring(5)}';

    widget.onChanged(
      formattedNumber,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        backgroundColor:
            Colors.green,

        content: Text(
          'Mobile number changed successfully.',
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.red.shade700,

        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,

        bottom:
            MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                25,
      ),

      child: AnimatedSwitcher(
        duration:
            const Duration(
          milliseconds: 250,
        ),

        child: _buildStep(),
      ),
    );
  }

  // ============================================================
  // STEP CONTROLLER
  // ============================================================

  Widget _buildStep() {
    if (step == 1) {
      return _currentNumberStep();
    }

    if (step == 2) {
      return _currentOtpStep();
    }

    return _newNumberStep();
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Center(
          child: Container(
            width: 45,
            height: 5,

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade300,

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Container(
              width: 48,
              height: 48,

              decoration:
                  const BoxDecoration(
                color: lightOrange,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.phone_android_rounded,
                color: orange,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      color: textGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _currentNumberStep() {
    return Column(
      key:
          const ValueKey(
        'currentNumber',
      ),

      mainAxisSize:
          MainAxisSize.min,

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _header(
          'Change Mobile Number',
          'First verify your connected mobile number.',
        ),

        ProfileNumberBox(
          title:
              'Connected Mobile Number',
          number:
              widget.currentNumber,
          icon:
              Icons.phone_outlined,
          showVerified: true,
        ),

        const SizedBox(height: 22),

        ProfileOrangeButton(
          text: 'Get OTP',
          onPressed:
              _getCurrentOtp,
        ),

        const SizedBox(height: 10),

        const Center(
          child: Text(
            'OTP will be sent to your connected mobile number.',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              color: textGrey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _currentOtpStep() {
    return Column(
      key:
          const ValueKey(
        'currentOtp',
      ),

      mainAxisSize:
          MainAxisSize.min,

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _header(
          'Verify OTP',
          'Enter the OTP sent to your current number.',
        ),

        ProfileNumberBox(
          title:
              'Connected Mobile Number',
          number:
              widget.currentNumber,
          icon:
              Icons.phone_outlined,
          showVerified: true,
        ),

        const SizedBox(height: 20),

        const Text(
          'Enter OTP',

          style: TextStyle(
            fontWeight:
                FontWeight.w600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 8),

        ProfileOtpField(
          controller:
              currentOtpController,
        ),

        const SizedBox(height: 8),

        const Text(
          'Demo OTP: 123456',

          style: TextStyle(
            color: orange,
            fontSize: 13,
            fontWeight:
                FontWeight.w500,
          ),
        ),

        const SizedBox(height: 20),

        ProfileOrangeButton(
          text: 'Verify OTP',
          onPressed:
              _verifyCurrentOtp,
        ),

        const SizedBox(height: 8),

        Center(
          child: TextButton(
            onPressed:
                _getCurrentOtp,

            style:
                TextButton.styleFrom(
              foregroundColor:
                  orange,
            ),

            child: const Text(
              'Resend OTP',

              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 3
  // ============================================================

  Widget _newNumberStep() {
    return SingleChildScrollView(
      key:
          const ValueKey(
        'newNumber',
      ),

      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _header(
            'New Mobile Number',
            'Enter and confirm your new mobile number.',
          ),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              13,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEFFAF1,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),

              border: Border.all(
                color:
                    Colors.green.shade200,
              ),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 22,
                ),

                SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'Current mobile number verified successfully.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ProfileMobileField(
            controller:
                newNumberController,
            label:
                'New Mobile Number',
            hint:
                'Enter 10 digit mobile number',
            icon:
                Icons.phone_outlined,
          ),

          const SizedBox(height: 15),

          ProfileMobileField(
            controller:
                confirmNumberController,
            label:
                'Confirm Mobile Number',
            hint:
                'Re-enter 10 digit mobile number',
            icon:
                Icons.phone_iphone_outlined,
          ),

          const SizedBox(height: 22),

          ProfileOrangeButton(
            text: 'Save',
            onPressed:
                _saveNewNumber,
          ),

          const SizedBox(height: 9),

          const Center(
            child: Text(
              'Both mobile numbers must match.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: textGrey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

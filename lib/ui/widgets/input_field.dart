import 'package:flutter/material.dart';

import '../../shared/theme.dart';

class InputField extends StatefulWidget {
  const InputField({
    super.key,
    required this.textController,
    required this.hintText,
    this.isPassword = false,
  });

  final TextEditingController textController;
  final String hintText;
  final bool isPassword;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.textController,
          obscureText: widget.isPassword ? isObscure : false,
          obscuringCharacter: '●',
          style: bodyLText.copyWith(
              fontWeight: isObscure ? bold : medium, color: blackColor),
          cursorColor: blackColor,
          decoration: InputDecoration(
            suffixIcon: Visibility(
              visible: widget.isPassword,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isObscure = !isObscure;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Icon(
                    isObscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: grayColor400,
                  ),
                ),
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            filled: true,
            fillColor: grayColor25,
            labelText: widget.hintText,
            labelStyle:
                bodyLText.copyWith(fontWeight: medium, color: grayColor200),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: grayColor50, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: grayColor50, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: grayColor50, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

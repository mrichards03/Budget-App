import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableAmount extends StatefulWidget {
  final double amount;
  final Function(double) onSave;
  final TextAlign textAlign;
  final TextStyle? style;

  const EditableAmount({
    super.key,
    required this.amount,
    required this.onSave,
    this.textAlign = TextAlign.right,
    this.style,
  });

  @override
  State<EditableAmount> createState() => _EditableAmountState();
}

class _EditableAmountState extends State<EditableAmount> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.amount.toStringAsFixed(2));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditableAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text when amount changes (but not while editing)
    if (oldWidget.amount != widget.amount && !_isEditing) {
      _controller.text = widget.amount.toStringAsFixed(2);
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _saveAmount();
    }
  }

  void _saveAmount() {
    final newValue = double.tryParse(_controller.text);
    if (newValue != null && newValue != widget.amount) {
      widget.onSave(newValue);
    }
    setState(() {
      _isEditing = false;
      _controller.text = widget.amount.toStringAsFixed(2);
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return GestureDetector(
        onTap: _startEditing,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.transparent,
            ),
            child: Text(
              '\$${widget.amount.toStringAsFixed(2)}',
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 100,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: widget.textAlign,
          style: widget.style,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            isDense: true,
          ),
          onSubmitted: (_) => _saveAmount(),
        ),
      ),
    );
  }
}

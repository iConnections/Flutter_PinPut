import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pin_put/pin_put.dart';
import 'package:flutter/foundation.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class PinPutState extends State<PinPut>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  ValueNotifier<String>? _textControllerValue;

  int get selectedIndex => _controller!.value.text.length;

  late Animation _cursorAnimation;
  AnimationController? _cursorAnimationController;

  @override
  void initState() {
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _textControllerValue = ValueNotifier<String>(_controller!.value.text);
    _controller?.addListener(_textChangeListener);
    _focusNode?.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.withCursor) {
      _cursorAnimationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 500));
      _cursorAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          curve: Curves.linear, parent: _cursorAnimationController!));

      _cursorAnimationController!.addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _cursorAnimationController!.repeat(reverse: true);
        }
      });
      _cursorAnimationController!.forward();
    }

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _textChangeListener() {
    final pin = _controller!.value.text;
    if (pin != _textControllerValue!.value) {
      try {
        _textControllerValue!.value = pin;
      } catch (e) {
        _textControllerValue = ValueNotifier(_controller!.value.text);
      }
      if (pin.length == widget.fieldsCount) widget.onSubmit?.call(pin);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller!.dispose();
    if (widget.focusNode == null) _focusNode!.dispose();

    _cursorAnimationController?.dispose();
    _textControllerValue?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (appLifecycleState == AppLifecycleState.resumed ||
        widget.checkClipboard) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text?.length == widget.fieldsCount) {
      widget.onClipboardFound?.call(clipboardData!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _hiddenTextField,
        _fields,
      ],
    );
  }

  void _handleTap() {
    final focus = FocusScope.of(context);
    if (_focusNode!.hasFocus) _focusNode!.unfocus();
    if (focus.hasFocus) focus.unfocus();
    focus.requestFocus(FocusNode());
    Future.delayed(Duration.zero, () => focus.requestFocus(_focusNode));
    if (widget.onTap != null) widget.onTap!();
  }

  Widget get _hiddenTextField {
    return TextFormField(
      controller: _controller,
      onTap: widget.onTap,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      focusNode: _focusNode,
      enabled: widget.enabled,
      enableSuggestions: false,
      autofocus: widget.autofocus,
      readOnly: !widget.useNativeKeyboard,
      obscureText: widget.obscureText != null,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      keyboardAppearance: widget.keyboardAppearance,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      enableInteractiveSelection: false,
      maxLength: widget.fieldsCount,
      showCursor: false,
      scrollPadding: EdgeInsets.zero,
      decoration: widget.inputDecoration,
      style: widget.textStyle != null
          ? widget.textStyle!.copyWith(color: Colors.transparent)
          : const TextStyle(color: Colors.transparent),
    );
  }

  Widget get _fields {
    return ValueListenableBuilder<String>(
      valueListenable: _textControllerValue!,
      builder: (BuildContext context, value, Widget? child) {
        return GestureDetector(
          onTap: _handleTap,
          child: Row(
            mainAxisSize: widget.mainAxisSize,
            mainAxisAlignment: widget.fieldsAlignment,
            children: _buildFieldsWithSeparator(),
          ),
        );
      },
    );
  }

  List<Widget> _buildFieldsWithSeparator() {
    final fields = Iterable<int>.generate(widget.fieldsCount).map((index) {
      return _getField(index);
    }).toList();

    for (final int i in widget.separatorPositions) {
      if (i <= widget.fieldsCount) {
        final List<int> smaller =
            widget.separatorPositions.where((int d) => d < i).toList();
        fields.insert(i + smaller.length, widget.separator);
      }
    }

    return fields;
  }

  Widget _getField(int index) {
    final String pin = _controller!.value.text;
    return Stack(
      children: [
        Stack(
          children: [
            Container(
              decoration:  BoxDecoration(
                      color: widget.isDark ? Color(0xff1C212B) : Colors.white,
                      boxShadow: [ widget.isDark ? BoxShadow(
  color: Color.fromRGBO(28, 31, 38, 0.81),
  offset: Offset(2, 4),
  blurRadius: 20,
) : BoxShadow(
  color: Color.fromRGBO(121, 98, 249, 0.13),
  offset: Offset(2, 4),
  blurRadius: 12,
),],
                      borderRadius: BorderRadius.circular(8),
                    ),
              constraints: BoxConstraints(
                minWidth: widget.eachFieldWidth,
                minHeight: widget.eachFieldHeight,
              ),
              child: Container(
        
                  ),
            ),
            kIsWeb ? Container() : CustomPaint(
              painter: CustomBorderGradientPainter(
                strokeWidth: 1,
                radius: 8,
                gradient: LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [
    Color(0xffAEF3FF),
    Color(0xff8840A0),
  ],
)
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: BoxConstraints(minWidth: widget.eachFieldWidth, minHeight: widget.eachFieldHeight,),
              ),
            ),
          ],
        ),
        AnimatedContainer(
      width: widget.eachFieldWidth,
      height: widget.eachFieldHeight,
      alignment: widget.eachFieldAlignment,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      padding: widget.eachFieldPadding,
      margin: widget.eachFieldMargin,
      constraints: widget.eachFieldConstraints,
      decoration: _fieldDecoration(index),
      child: AnimatedSwitcher(
        switchInCurve: widget.animationCurve,
        switchOutCurve: widget.animationCurve,
        duration: widget.animationDuration,
        transitionBuilder: (child, animation) {
          return _getTransition(child, animation);
        },
        child: _buildFieldContent(index, pin),
      ),
    ),
      ],
    );
  }

  Widget _buildFieldContent(int index, String pin) {
    if (index < pin.length) {
      return Text(
        widget.obscureText ?? pin[index],
        key: ValueKey<String>(index < pin.length ? pin[index] : ''),
        style: widget.textStyle,
      );
    }

    final isActiveField = index == pin.length;
    final focused = _focusNode!.hasFocus || !widget.useNativeKeyboard;

    if (widget.withCursor && isActiveField && focused) {
      return _buildCursor();
    }

    if (widget.preFilledWidget != null)
      return SizedBox(
        key: ValueKey<String>(index < pin.length ? pin[index] : ''),
        child: widget.preFilledWidget,
      );
    return Text(
      '',
      key: ValueKey<String>(index < pin.length ? pin[index] : ''),
      style: widget.textStyle,
    );
  }

  BoxDecoration? _fieldDecoration(int index) {
    if (!widget.enabled) return widget.disabledDecoration;
    if (index < selectedIndex &&
        (_focusNode!.hasFocus || !widget.useNativeKeyboard)) {
      return widget.submittedFieldDecoration;
    }
    if (index == selectedIndex &&
        (_focusNode!.hasFocus || !widget.useNativeKeyboard)) {
      return widget.selectedFieldDecoration;
    }
    return widget.followingFieldDecoration;
  }

  Widget _getTransition(Widget child, Animation animation) {
    switch (widget.pinAnimationType) {
      case PinAnimationType.none:
        return child;
      case PinAnimationType.fade:
        return FadeTransition(
          opacity: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.scale:
        return ScaleTransition(
          scale: animation as Animation<double>,
          child: child,
        );
      case PinAnimationType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: widget.slideTransitionBeginOffset ?? Offset(0.8, 0),
            end: Offset.zero,
          ).animate(animation as Animation<double>),
          child: child,
        );
      case PinAnimationType.rotation:
        return RotationTransition(
          turns: animation as Animation<double>,
          child: child,
        );
    }
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _cursorAnimationController!,
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: _cursorAnimation.value,
            child: widget.cursor ?? Text('|', style: widget.textStyle),
          ),
        );
      },
    );
  }
}

class CustomBorderGradientPainter extends CustomPainter {
  final Paint _paint = Paint()..color = Colors.white;
  final double radius;
  final double strokeWidth;
  final Gradient? gradient;
  final bool bold;
  final bool disabled;

  CustomBorderGradientPainter({
     this.strokeWidth = 1,
     this.radius = 8,
     this.gradient,
    this.bold = false,
    this.disabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // create outer rectangle equals size
    Rect outerRect = Offset.zero & size;
    var outerRRect =
        RRect.fromRectAndRadius(outerRect, Radius.circular(radius));

    // create inner rectangle smaller by strokeWidth
    Rect innerRect = Rect.fromLTWH(strokeWidth, strokeWidth,
        size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    var innerRRect = RRect.fromRectAndRadius(
        innerRect, Radius.circular(radius - strokeWidth));

    // apply gradient shader
    if (!bold || disabled) {
      _paint.shader = gradient?.createShader(outerRect);
    }

    // create difference between outer and inner paths and draw it
    Path path1 = Path()..addRRect(outerRRect);
    Path path2 = Path()..addRRect(innerRRect);
    var path = Path.combine(PathOperation.difference, path1, path2);
    // canvas.rotate(math.pi / 2);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}

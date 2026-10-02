import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Tap fuori da un campo chiuso = la tastiera scende, su ogni piattaforma.
///
/// Va montato una volta sola, in `MathApp.builder`: `EditableText` passa
/// [EditableTextTapOutsideIntent] solo quando il campo ha il focus e le sue
/// azioni sono `Action.overridable`, quindi un `Actions` più in alto nell'albero
/// vince per tutte le schermate, i dialog e gli overlay.
///
/// Il default di Flutter (`_EditableTextTapOutsideAction`) chiama `unfocus` su
/// desktop e sul web, ma **non** sui telefoni quando il tap arriva col dito:
/// da li è nato questo widget.
///
/// Serve distinguere il tap dallo scroll, quindi non basta `unfocus` al tap
/// down: si tiene il `PointerDownEvent` e si chiude al tap up solo se il dito
/// non è andato lontano. È la regola dell'esempio del framework
/// (`editable_text_tap_up_outside_intent`): scrollare la pagina non deve
/// spaventare via la tastiera.
class DismissKeyboard extends StatefulWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  State<DismissKeyboard> createState() => _DismissKeyboardState();
}

class _DismissKeyboardState extends State<DismissKeyboard> {
  PointerDownEvent? _pointerDown;

  void _onTapOutside(EditableTextTapOutsideIntent intent) {
    _pointerDown = intent.pointerDownEvent;
  }

  void _onTapUpOutside(EditableTextTapUpOutsideIntent intent) {
    final down = _pointerDown;
    _pointerDown = null;
    if (down == null) return;
    final moved = (down.position - intent.pointerUpEvent.position).distance;
    if (moved < kTouchSlop) intent.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: _onTapOutside,
            ),
        EditableTextTapUpOutsideIntent:
            CallbackAction<EditableTextTapUpOutsideIntent>(
              onInvoke: _onTapUpOutside,
            ),
      },
      child: widget.child,
    );
  }
}

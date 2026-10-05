import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'press_tracker.dart';

enum AppButtonVariant {
  /// Indaco pieno, testo bianco: l'azione principale della schermata.
  primary,

  /// Giallo pieno, testo inchiostro: un'azione che continua o che va su un
  /// fondo indaco.
  secondary,

  /// Bianco con il bordo indaco: l'alternativa accanto a un [primary].
  outline,
}

/// Il bottone del design: una pillola in Outfit sollevata da un gradino di
/// colore pieno sotto, non da un'ombra sfumata.
///
/// Premuto, il bottone scende di tutto il gradino e il gradino sparisce, poi al
/// rilascio torna su ([AppMotion.fast], `easeOut`): è l'unico movimento, e dice
/// che il tocco è arrivato. Disabilitato resta giù, grigio caldo e senza
/// gradino. Col movimento ridotto il cambio è istantaneo.
///
/// L'altezza totale è [height] più il gradino ([depth]): il gradino sta dentro
/// lo spazio del bottone, così non tocca quello che c'è sotto, e la faccia si
/// sposta con una traslazione, che non rifà il layout.
class AppButton extends StatefulWidget {
  /// Altezza del gradino sotto la faccia del bottone.
  static const double depth = 5;

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Allarga il bottone a tutta riga.
  final bool expand;

  /// Mostra la rotella al posto del testo e non accetta tocchi.
  final bool busy;

  /// Altezza della faccia, senza il gradino.
  final double height;

  /// Il testo del suggerimento quando il bottone ha solo l'icona.
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
    this.busy = false,
    this.height = 52,
    this.tooltip,
  }) : assert(label != null || icon != null);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  // La pressione parte col dito, non quando l'`InkWell` decide che è un tocco:
  // vedi `PressTracker`.
  late final PressTracker _press = PressTracker(
    (value) => setState(() => _pressed = value),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (face, ink, deep) = !_enabled && !widget.busy
        ? (c.disabled, c.onDisabled, c.disabled)
        : switch (widget.variant) {
            AppButtonVariant.primary => (c.accent, Colors.white, c.accentDeep),
            AppButtonVariant.secondary => (
              c.yellow,
              c.textPrimary,
              c.yellowDeep,
            ),
            AppButtonVariant.outline => (c.surface, c.accent, c.accent),
          };
    _press.hold = AppMotion.duration(context, AppMotion.fast);
    final raised = _enabled || widget.busy;
    // Giù quando è premuto, e da disabilitato: senza gradino, schiacciato.
    final down = !raised || _pressed;
    final shape = BorderRadius.circular(widget.height);
    final fontSize = widget.height >= 50
        ? AppText.titleLarge
        : AppText.titleMedium;
    final label = widget.label;

    Widget content = widget.busy
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: ink),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) Icon(widget.icon, size: 22, color: ink),
              if (widget.icon != null && label != null)
                const SizedBox(width: 8),
              if (label != null)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppText.headingFont,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
            ],
          );
    content = SizedBox(
      height: widget.height,
      width: widget.expand ? double.infinity : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: label == null ? 14 : 24),
        child: Center(widthFactor: 1, child: content),
      ),
    );

    Widget button = Semantics(
      button: true,
      enabled: _enabled,
      label: label == null ? widget.tooltip : null,
      child: Padding(
        // Lo spazio del gradino sotto la faccia: l'altezza totale non cambia
        // mai, premuto o no.
        padding: const EdgeInsets.only(bottom: AppButton.depth),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.fast),
          curve: AppMotion.standard,
          transform: Matrix4.translationValues(
            0,
            down ? AppButton.depth : 0,
            0,
          ),
          width: widget.expand ? double.infinity : null,
          // Il bordo del contorno sta davanti e non nella decorazione, che lo
          // aggiungerebbe all'altezza.
          foregroundDecoration:
              widget.variant == AppButtonVariant.outline && raised
              ? BoxDecoration(
                  borderRadius: shape,
                  border: Border.all(color: c.accent, width: 3),
                )
              : null,
          decoration: BoxDecoration(
            color: face,
            borderRadius: shape,
            boxShadow: [
              if (raised)
                BoxShadow(
                  color: deep,
                  offset: Offset(0, down ? 0 : AppButton.depth),
                ),
            ],
          ),
          child: Listener(
            onPointerDown: _enabled ? (_) => _press.down() : null,
            onPointerUp: _enabled ? (_) => _press.up() : null,
            onPointerCancel: _enabled ? (_) => _press.up() : null,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: shape,
                onTap: _enabled ? widget.onPressed : null,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
    if (label == null && widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

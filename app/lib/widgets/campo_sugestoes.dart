import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../util/format.dart';

/// Campo de texto com sugestões (chips) logo abaixo, filtradas pelo que foi
/// digitado (ignora acento/caixa). Tocar numa sugestão preenche o campo. Usado
/// para postos (histórico do usuário) e oficinas.
class CampoSugestoes extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final List<String> sugestoes;
  final Color cor;
  final int max;

  const CampoSugestoes({
    super.key,
    required this.controller,
    required this.label,
    required this.sugestoes,
    this.hint,
    this.cor = AppColors.accent,
    this.max = 6,
  });

  @override
  State<CampoSugestoes> createState() => _CampoSugestoesState();
}

class _CampoSugestoesState extends State<CampoSugestoes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  List<String> get _matches {
    final termo = semAcento(widget.controller.text.trim());
    // sem texto: mostra os mais recentes; com texto: filtra por "contém".
    final base = termo.isEmpty
        ? widget.sugestoes
        : widget.sugestoes.where((s) => semAcento(s).contains(termo));
    final out = <String>[];
    for (final s in base) {
      if (s.trim().isEmpty) continue;
      if (semAcento(s) == termo) continue; // já é exatamente o digitado
      if (!out.contains(s)) out.add(s);
      if (out.length >= widget.max) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
        ),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matches
                .map((s) => ActionChip(
                      label: Text(s),
                      backgroundColor: AppColors.surface2,
                      labelStyle: TextStyle(color: widget.cor, fontSize: 12.5),
                      side: const BorderSide(color: AppColors.line),
                      onPressed: () {
                        widget.controller.text = s;
                        widget.controller.selection = TextSelection.collapsed(
                            offset: widget.controller.text.length);
                      },
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

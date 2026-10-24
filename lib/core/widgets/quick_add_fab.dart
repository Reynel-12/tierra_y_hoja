import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_icons.dart';
import '../design/app_tokens.dart';
import '../design/app_typography.dart';
import 'dialogs.dart';

/// Acción rápida global: abre un bottom sheet para registrar en menos de 3 toques.
class QuickAddFab extends StatelessWidget {
  const QuickAddFab({
    super.key,
    required this.onAddApplication,
    required this.onAddTask,
    required this.onAddIncident,
    required this.onAddExpense,
    this.label = 'Registrar',
  });

  final VoidCallback onAddApplication;
  final VoidCallback onAddTask;
  final VoidCallback onAddIncident;
  final VoidCallback onAddExpense;
  final String label;

  void _showSheet(BuildContext context) {
    showAppSheet<void>(
      context,
      title: '¿Qué desea registrar?',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuickAddTile(
            icon: AppIcons.application,
            title: 'Aplicación de insumo',
            subtitle: 'Fertilizantes, foliares, insecticidas, enmiendas',
            onTap: () {
              Navigator.of(sheetContext).pop();
              onAddApplication();
            },
          ),
          const SizedBox(height: AppSpace.sm),
          _QuickAddTile(
            icon: AppIcons.task,
            title: 'Labor cultural',
            subtitle: 'Preparación, deshierbe, aporco, poda, riegos',
            onTap: () {
              Navigator.of(sheetContext).pop();
              onAddTask();
            },
          ),
          const SizedBox(height: AppSpace.sm),
          _QuickAddTile(
            icon: AppIcons.pest,
            title: 'Plaga o evento climático',
            subtitle: 'Aparición de plagas, roya, sequía, lluvia, granizo',
            onTap: () {
              Navigator.of(sheetContext).pop();
              onAddIncident();
            },
          ),
          const SizedBox(height: AppSpace.sm),
          _QuickAddTile(
            icon: AppIcons.costs,
            title: 'Compra o gasto',
            subtitle: 'Semillas, insumos comprados, pago de jornales',
            onTap: () {
              Navigator.of(sheetContext).pop();
              onAddExpense();
            },
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSheet(context),
          borderRadius: AppRadius.pill,
          child: Container(
            height: AppSize.primaryAction,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: AppRadius.pill,
              boxShadow: AppShadow.level2(c.ink),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.add, color: c.onPrimary, size: AppSize.iconMd),
                const SizedBox(width: AppSpace.sm),
                Text(
                  label,
                  style: t.label.copyWith(color: c.onPrimary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.quickAddTile),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.control,
            border: Border.all(color: c.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: c.primary, size: AppSize.iconMd),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: t.title.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.bodySm),
                  ],
                ),
              ),
              Icon(AppIcons.forward, size: AppSize.iconSm, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

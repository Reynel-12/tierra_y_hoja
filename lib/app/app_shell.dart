import 'package:flutter/material.dart';

import '../core/design/app_icons.dart';
import '../core/widgets/quick_add_fab.dart';
import '../features/activities/views/incident_form_view.dart';
import '../features/activities/views/task_form_view.dart';
import '../features/costs/views/expense_form_view.dart';
import '../features/cycles/views/cycle_list_view.dart';
import '../features/field_log/views/application_form_view.dart';
import '../features/history/views/experience_search_view.dart';
import '../features/home/views/home_view.dart';
import '../features/more/views/more_view.dart';
import '../features/plots/views/plot_list_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _views = <Widget>[
    HomeView(),
    CycleListView(),
    PlotListView(),
    ExperienceSearchView(),
    MoreView(),
  ];

  void _onAddApplication(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ApplicationFormView(),
      ),
    );
  }

  void _onAddTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TaskFormView(),
      ),
    );
  }

  void _onAddIncident(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const IncidentFormView(),
      ),
    );
  }

  void _onAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ExpenseFormView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      floatingActionButton: _currentIndex != 4 // No tapar en más
          ? QuickAddFab(
              onAddApplication: () => _onAddApplication(context),
              onAddTask: () => _onAddTask(context),
              onAddIncident: () => _onAddIncident(context),
              onAddExpense: () => _onAddExpense(context),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            selectedIcon: Icon(AppIcons.homeActive),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.cycle),
            selectedIcon: Icon(AppIcons.cycleActive),
            label: 'Siembras',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.plot),
            selectedIcon: Icon(AppIcons.plotActive),
            label: 'Lotes',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.history),
            selectedIcon: Icon(AppIcons.historyActive),
            label: 'Memoria',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.more),
            selectedIcon: Icon(AppIcons.moreActive),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

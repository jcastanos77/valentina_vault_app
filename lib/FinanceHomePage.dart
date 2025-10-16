import 'package:flutter/material.dart';
import 'package:valentinas_vault/Tabs/Goal_page.dart';
import 'package:valentinas_vault/Tabs/Home_page.dart';
import 'package:valentinas_vault/Tabs/Stats_page.dart';

import 'Tabs/Trasaction_page.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({Key? key}) : super(key: key);

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(),
      TrasactionPage(),
      GoalPage(),
      StatsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Metas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}
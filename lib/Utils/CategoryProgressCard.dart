import 'package:flutter/material.dart';
import 'package:valentinas_vault/Utils/ui_helpers.dart';

import 'ModernCard.dart';

class CategoryProgressCard extends StatelessWidget {
  final String category;
  final double budget;
  final double spent;
  final double porcentage;

  const CategoryProgressCard(
      this.category,
      this.budget,
      this.spent,
      this.porcentage,
      {super.key}
      );

  static const Map<String, Color> categoryColors = {
    'basicos': Color(0xFF27AE60),
    'ahorro': Color(0xFF3498DB),
    'lujos': Color(0xFFE74C3C),
  };


  static const Map<String, IconData> categoryIcons = {
    'basicos': Icons.home_rounded,
    'ahorro': Icons.savings_rounded,
    'lujos': Icons.shopping_bag_rounded,
  };

  @override
  Widget build(BuildContext context) {
    double remaining = budget - spent;
    Color categoryColor = categoryColors[category]!;
    IconData categoryIcon = categoryIcons[category]!;

    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category == 'basicos' ? 'Necesidades' :
                      category == 'ahorro' ? 'Ahorros' : 'Lujos',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Disponible: \$${formatNumber(remaining)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: remaining >= 0 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${porcentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: (porcentage / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor.withOpacity(0.7), categoryColor],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presupuesto',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Gastado',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${formatNumber(budget)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '\$${formatNumber(spent)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

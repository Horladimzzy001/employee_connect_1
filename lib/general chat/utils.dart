// utils.dart
import 'package:flutter/material.dart';

Color getStatusColor(String status) {
  switch (status) {
    case 'Full Employee':
      return Colors.green; // 🟢
    case 'Contract Employee':
      return Colors.yellow; // 🟡
    case 'Intern Employee':
      return Colors.blue; // 🔵
    case 'Mentor/Advisor':
      return Colors.purple; // 🟣
    case 'Former Employee':
      return Colors.black; // ⚫
    case 'Fired Employee':
      return Colors.red; // 🔴
    case 'Client':
    case 'Visitor':
      return Colors.orange; // 🟠
    default:
      return Colors.grey; // Default color for unknown status
  }
}

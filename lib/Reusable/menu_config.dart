import 'package:flutter/material.dart';

class MenuConfig {
  final int id;
  final String name;
  final bool enable;
  final IconData icon;

  MenuConfig({
    required this.id,
    required this.name,
    required this.enable,
    required this.icon,
  });
}

List<MenuConfig> appMenus = [
  MenuConfig(id: 0, name: "Home", enable: true, icon: Icons.home_outlined),
  MenuConfig(id: 1, name: "Orders", enable: true, icon: Icons.shopping_cart_outlined),
  MenuConfig(id: 2, name: "Report", enable: true, icon: Icons.note_alt_outlined),
  MenuConfig(id: 3, name: "Stockin", enable: true, icon: Icons.inventory),
  MenuConfig(id: 4, name: "Products", enable: true, icon: Icons.note_alt_outlined),
];

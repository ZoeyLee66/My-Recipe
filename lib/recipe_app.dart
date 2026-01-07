import 'package:flutter/material.dart';
import 'package:assignment/my_recipe_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:assignment/recipe_list_page.dart';
import 'package:assignment/add_recipe_page.dart';

class RecipeApp extends StatefulWidget {
  @override
  _RecipeAppState createState() => _RecipeAppState();
}

class _RecipeAppState extends State<RecipeApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MyRecipePage(),
    AddRecipePage(),
    RecipeListPage(),
  ];

  final List<NavItem> _items = const [
    NavItem(
      selectedIcon: 'assets/icons/mypage_w.svg',
      unselectedIcon: 'assets/icons/mypage_dark.svg',
      label: 'MY PAGE',
      unselectedTextColor: Color(0xFF0F4635),
    ),
    NavItem(
      selectedIcon: 'assets/icons/add_recipe_w.svg',
      unselectedIcon: 'assets/icons/add_recipe_dark.svg',
      label: 'ADD RECIPE',
      unselectedTextColor: Color(0xFF0F4635),
    ),
    NavItem(
      selectedIcon: 'assets/icons/recipe_w.svg',
      unselectedIcon: 'assets/icons/recipe_dark.svg',
      label: 'RECIPE',
      unselectedTextColor: Color(0xFF0F4635),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF197458),
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0),
          _buildBottomNavItem(1),
          _buildBottomNavItem(2),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index) {
    final selected = _selectedIndex == index;
    final item = _items[index];

    final String assetPath = selected ? item.selectedIcon : item.unselectedIcon;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          SvgPicture.asset(
            assetPath,
            width: 30,
            height: 30,
            colorFilter: selected
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(height: 4),
          // 텍스트
          Text(
            item.label,
            style: GoogleFonts.jomhuria(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              color: selected ? Colors.white : item.unselectedTextColor,
              height: 0.9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem {
  final String selectedIcon;
  final String unselectedIcon;
  final String label;
  final Color unselectedTextColor;
  const NavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    required this.unselectedTextColor,
  });
}

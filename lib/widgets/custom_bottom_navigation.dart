import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const CustomBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  static List<String> getLabels(bool isAdmin) => [
    AppStrings.dashboard,
    AppStrings.inventory,
    AppStrings.buyers,
    isAdmin ? AppStrings.team : AppStrings.profile,
  ];
  static List<IconData> getIcons(bool isAdmin) => [
    Icons.home_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
    Icons.person_outline,
  ];
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selected,
    onDestinationSelected: onSelected,
    destinations: [
      for (var i = 0; i < 4; i++)
        NavigationDestination(
          icon: Icon(
            i == 3 && context.watch<UserModel>().isAdmin
                ? Icons.badge_outlined
                : getIcons(true)[i],
          ),
          selectedIcon: Icon(
            i == 3 && context.watch<UserModel>().isAdmin
                ? Icons.badge
                : [
                    Icons.home,
                    Icons.inventory_2,
                    Icons.people,
                    Icons.person,
                  ][i],
          ),
          label: i == 3 && context.watch<UserModel>().isAdmin
              ? 'Staff'
              : getLabels(false)[i],
        ),
    ],
  );
}

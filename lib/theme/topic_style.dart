import 'package:flutter/material.dart';

import 'app_colors.dart';

Color topicColor(AppPalette c, String name) {
  switch (name) {
    case 'pie_chart':
      return c.pink;
    case 'functions':
      return c.accent;
    case 'tag':
      return c.medium;
    case 'trending_up':
      return c.easy;
    case 'show_chart':
      return c.teal;
    case 'calculate':
      return c.purple;
    case 'grid_on':
      return c.indigo;
    case 'casino':
      return c.pink;
    case 'account_tree':
      return c.teal;
    default:
      return c.accent;
  }
}

/// L'icona di un argomento o di un topic, dal nome scritto nei JSON.
IconData topicIcon(String name) {
  switch (name) {
    case 'functions':
      return Icons.functions;
    case 'pie_chart':
      return Icons.pie_chart;
    case 'tag':
      return Icons.tag;
    case 'trending_up':
      return Icons.trending_up;
    case 'show_chart':
      return Icons.show_chart;
    case 'calculate':
      return Icons.calculate;
    case 'grid_on':
      return Icons.grid_on;
    case 'casino':
      return Icons.casino;
    case 'account_tree':
      return Icons.account_tree;
    default:
      return Icons.menu_book;
  }
}

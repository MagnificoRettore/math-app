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

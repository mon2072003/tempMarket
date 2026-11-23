import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final String businessType; // factory, mall, pharmacy, restaurant, all
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.businessType,
    this.productCount = 0,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
}

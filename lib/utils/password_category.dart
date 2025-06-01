import 'package:flutter/material.dart';

class PasswordCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  const PasswordCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': icon.codePoint,
      'color_value': color.value,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory PasswordCategory.fromMap(Map<String, dynamic> map) {
    return PasswordCategory(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['icon_code'], fontFamily: 'MaterialIcons'),
      color: Color(map['color_value']),
      isDefault: map['is_default'] == 1,
    );
  }
}

class CategoryManager {
  // 预设分类
  static const List<PasswordCategory> defaultCategories = [
    PasswordCategory(
      id: 'all',
      name: '全部',
      icon: Icons.apps,
      color: Colors.grey,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'social',
      name: '社交',
      icon: Icons.people,
      color: Colors.green,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'email',
      name: '邮箱',
      icon: Icons.mail,
      color: Colors.blue,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'banking',
      name: '银行',
      icon: Icons.account_balance,
      color: Colors.teal,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'shopping',
      name: '购物',
      icon: Icons.shopping_cart,
      color: Colors.orange,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'work',
      name: '工作',
      icon: Icons.work,
      color: Colors.indigo,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'entertainment',
      name: '娱乐',
      icon: Icons.movie,
      color: Colors.purple,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'gaming',
      name: '游戏',
      icon: Icons.games,
      color: Colors.deepPurple,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'education',
      name: '学习',
      icon: Icons.school,
      color: Colors.cyan,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'cloud',
      name: '云存储',
      icon: Icons.cloud,
      color: Colors.lightBlue,
      isDefault: true,
    ),
    PasswordCategory(
      id: 'other',
      name: '其他',
      icon: Icons.category,
      color: Colors.grey,
      isDefault: true,
    ),
  ];

  // 根据用途智能推荐分类
  static String suggestCategory(String purpose) {
    final lowerPurpose = purpose.toLowerCase().trim();
    
    // 社交类
    if (lowerPurpose.contains('微信') || lowerPurpose.contains('qq') || 
        lowerPurpose.contains('微博') || lowerPurpose.contains('抖音') ||
        lowerPurpose.contains('wechat') || lowerPurpose.contains('weibo') ||
        lowerPurpose.contains('social') || lowerPurpose.contains('chat') ||
        lowerPurpose.contains('聊天') || lowerPurpose.contains('社交')) {
      return 'social';
    }
    
    // 邮箱类
    if (lowerPurpose.contains('邮箱') || lowerPurpose.contains('mail') ||
        lowerPurpose.contains('gmail') || lowerPurpose.contains('outlook') ||
        lowerPurpose.contains('163') || lowerPurpose.contains('126')) {
      return 'email';
    }
    
    // 银行金融类
    if (lowerPurpose.contains('银行') || lowerPurpose.contains('支付宝') ||
        lowerPurpose.contains('bank') || lowerPurpose.contains('alipay') ||
        lowerPurpose.contains('招商') || lowerPurpose.contains('工商') ||
        lowerPurpose.contains('建设') || lowerPurpose.contains('农业') ||
        lowerPurpose.contains('中国银行') || lowerPurpose.contains('payment')) {
      return 'banking';
    }
    
    // 购物类
    if (lowerPurpose.contains('淘宝') || lowerPurpose.contains('京东') ||
        lowerPurpose.contains('天猫') || lowerPurpose.contains('拼多多') ||
        lowerPurpose.contains('购物') || lowerPurpose.contains('shop') ||
        lowerPurpose.contains('amazon') || lowerPurpose.contains('美团') ||
        lowerPurpose.contains('饿了么')) {
      return 'shopping';
    }
    
    // 工作类
    if (lowerPurpose.contains('工作') || lowerPurpose.contains('公司') ||
        lowerPurpose.contains('work') || lowerPurpose.contains('office') ||
        lowerPurpose.contains('github') || lowerPurpose.contains('gitlab') ||
        lowerPurpose.contains('企业') || lowerPurpose.contains('团队')) {
      return 'work';
    }
    
    // 娱乐类
    if (lowerPurpose.contains('爱奇艺') || lowerPurpose.contains('优酷') ||
        lowerPurpose.contains('腾讯视频') || lowerPurpose.contains('网易云') ||
        lowerPurpose.contains('spotify') || lowerPurpose.contains('netflix') ||
        lowerPurpose.contains('音乐') || lowerPurpose.contains('视频') ||
        lowerPurpose.contains('电影') || lowerPurpose.contains('entertainment')) {
      return 'entertainment';
    }
    
    // 游戏类
    if (lowerPurpose.contains('游戏') || lowerPurpose.contains('steam') ||
        lowerPurpose.contains('epic') || lowerPurpose.contains('lol') ||
        lowerPurpose.contains('英雄联盟') || lowerPurpose.contains('魔兽') ||
        lowerPurpose.contains('我的世界') || lowerPurpose.contains('game')) {
      return 'gaming';
    }
    
    // 学习类
    if (lowerPurpose.contains('学习') || lowerPurpose.contains('教育') ||
        lowerPurpose.contains('课程') || lowerPurpose.contains('大学') ||
        lowerPurpose.contains('study') || lowerPurpose.contains('education') ||
        lowerPurpose.contains('school') || lowerPurpose.contains('学校')) {
      return 'education';
    }
    
    // 云存储类
    if (lowerPurpose.contains('云盘') || lowerPurpose.contains('网盘') ||
        lowerPurpose.contains('cloud') || lowerPurpose.contains('百度网盘') ||
        lowerPurpose.contains('onedrive') || lowerPurpose.contains('dropbox') ||
        lowerPurpose.contains('icloud')) {
      return 'cloud';
    }
    
    // 默认其他
    return 'other';
  }

  // 获取分类
  static PasswordCategory getCategoryById(String id) {
    return defaultCategories.firstWhere(
      (category) => category.id == id,
      orElse: () => defaultCategories.last, // 默认返回"其他"
    );
  }

  // 获取所有分类（除了"全部"）
  static List<PasswordCategory> getSelectableCategories() {
    return defaultCategories.where((category) => category.id != 'all').toList();
  }

  // 获取包含"全部"的分类列表（用于筛选）
  static List<PasswordCategory> getAllCategories() {
    return defaultCategories;
  }
} 
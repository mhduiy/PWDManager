import 'package:flutter/material.dart';

class WebsiteIcons {
  // 常见网站/应用的图标映射
  static const Map<String, IconData> _iconMap = {
    // 社交媒体
    'qq': Icons.chat,
    'wechat': Icons.wechat,
    '微信': Icons.wechat,
    'weibo': Icons.dynamic_feed,
    '微博': Icons.dynamic_feed,
    'douyin': Icons.music_video,
    '抖音': Icons.music_video,
    'bilibili': Icons.play_circle,
    'b站': Icons.play_circle,
    'xiaohongshu': Icons.favorite,
    '小红书': Icons.favorite,
    'zhihu': Icons.quiz,
    '知乎': Icons.quiz,
    
    // 邮箱
    'gmail': Icons.mail,
    'qq邮箱': Icons.mail,
    'outlook': Icons.mail,
    '163邮箱': Icons.mail,
    '126邮箱': Icons.mail,
    'email': Icons.mail,
    '邮箱': Icons.mail,
    
    // 购物
    'taobao': Icons.shopping_bag,
    '淘宝': Icons.shopping_bag,
    'tmall': Icons.shopping_cart,
    '天猫': Icons.shopping_cart,
    'jd': Icons.shopping_cart,
    '京东': Icons.shopping_cart,
    'pdd': Icons.shopping_bag,
    '拼多多': Icons.shopping_bag,
    'amazon': Icons.shopping_cart,
    
    // 银行金融
    'alipay': Icons.payment,
    '支付宝': Icons.payment,
    'bank': Icons.account_balance,
    '银行': Icons.account_balance,
    'icbc': Icons.account_balance,
    '工商银行': Icons.account_balance,
    'ccb': Icons.account_balance,
    '建设银行': Icons.account_balance,
    'abc': Icons.account_balance,
    '农业银行': Icons.account_balance,
    'boc': Icons.account_balance,
    '中国银行': Icons.account_balance,
    'cmb': Icons.account_balance,
    '招商银行': Icons.account_balance,
    
    // 工作相关
    'git': Icons.code,
    'github': Icons.code,
    'gitlab': Icons.code,
    'coding': Icons.code,
    'office': Icons.work,
    'work': Icons.work,
    '工作': Icons.work,
    'company': Icons.business,
    '公司': Icons.business,
    
    // 学习教育
    'study': Icons.school,
    '学习': Icons.school,
    'education': Icons.school,
    '教育': Icons.school,
    'course': Icons.book,
    '课程': Icons.book,
    'university': Icons.school,
    '大学': Icons.school,
    
    // 游戏
    'game': Icons.games,
    '游戏': Icons.games,
    'steam': Icons.games,
    'epic': Icons.games,
    'lol': Icons.sports_esports,
    '英雄联盟': Icons.sports_esports,
    'wow': Icons.sports_esports,
    '魔兽世界': Icons.sports_esports,
    'minecraft': Icons.grid_view,
    '我的世界': Icons.grid_view,
    
    // 云存储
    'cloud': Icons.cloud,
    '云盘': Icons.cloud,
    'baidu': Icons.cloud,
    '百度网盘': Icons.cloud,
    'onedrive': Icons.cloud,
    'dropbox': Icons.cloud,
    'icloud': Icons.cloud,
    
    // 视频音乐
    'youtube': Icons.play_circle,
    'netflix': Icons.movie,
    'iqiyi': Icons.movie,
    '爱奇艺': Icons.movie,
    'youku': Icons.movie,
    '优酷': Icons.movie,
    'music': Icons.music_note,
    '音乐': Icons.music_note,
    'spotify': Icons.music_note,
    'netease': Icons.music_note,
    '网易云音乐': Icons.music_note,
    
    // 新闻资讯
    'news': Icons.newspaper,
    '新闻': Icons.newspaper,
    'toutiao': Icons.article,
    '今日头条': Icons.article,
    
    // 旅行
    'travel': Icons.flight,
    '旅行': Icons.flight,
    'ctrip': Icons.flight,
    '携程': Icons.flight,
    'qunar': Icons.flight,
    '去哪儿': Icons.flight,
    
    // 外卖配送
    'meituan': Icons.restaurant,
    '美团': Icons.restaurant,
    'eleme': Icons.delivery_dining,
    '饿了么': Icons.delivery_dining,
    
    // 其他
    'wifi': Icons.wifi,
    'router': Icons.router,
    '路由器': Icons.router,
    'vpn': Icons.vpn_key,
    'password': Icons.lock,
    '密码': Icons.lock,
  };
  
  // 分类默认图标
  static const Map<String, IconData> _categoryIcons = {
    'social': Icons.people,
    'email': Icons.mail,
    'shopping': Icons.shopping_cart,
    'banking': Icons.account_balance,
    'work': Icons.work,
    'study': Icons.school,
    'game': Icons.games,
    'cloud': Icons.cloud,
    'entertainment': Icons.movie,
    'news': Icons.newspaper,
    'travel': Icons.flight,
    'food': Icons.restaurant,
    'other': Icons.apps,
  };
  
  // 根据用途获取图标
  static IconData getIcon(String purpose) {
    final lowerPurpose = purpose.toLowerCase().trim();
    
    // 首先尝试精确匹配
    if (_iconMap.containsKey(lowerPurpose)) {
      return _iconMap[lowerPurpose]!;
    }
    
    // 然后尝试包含匹配
    for (final entry in _iconMap.entries) {
      if (lowerPurpose.contains(entry.key) || entry.key.contains(lowerPurpose)) {
        return entry.value;
      }
    }
    
    // 尝试分类匹配
    for (final entry in _categoryIcons.entries) {
      if (lowerPurpose.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // 智能匹配关键词
    if (lowerPurpose.contains('银行') || lowerPurpose.contains('bank')) {
      return Icons.account_balance;
    }
    if (lowerPurpose.contains('邮箱') || lowerPurpose.contains('mail')) {
      return Icons.mail;
    }
    if (lowerPurpose.contains('游戏') || lowerPurpose.contains('game')) {
      return Icons.games;
    }
    if (lowerPurpose.contains('购物') || lowerPurpose.contains('shop')) {
      return Icons.shopping_cart;
    }
    if (lowerPurpose.contains('工作') || lowerPurpose.contains('work') || lowerPurpose.contains('office')) {
      return Icons.work;
    }
    if (lowerPurpose.contains('学习') || lowerPurpose.contains('study') || lowerPurpose.contains('school')) {
      return Icons.school;
    }
    if (lowerPurpose.contains('音乐') || lowerPurpose.contains('music')) {
      return Icons.music_note;
    }
    if (lowerPurpose.contains('视频') || lowerPurpose.contains('video') || lowerPurpose.contains('电影')) {
      return Icons.movie;
    }
    if (lowerPurpose.contains('社交') || lowerPurpose.contains('聊天') || lowerPurpose.contains('chat')) {
      return Icons.chat;
    }
    if (lowerPurpose.contains('云') || lowerPurpose.contains('cloud') || lowerPurpose.contains('网盘')) {
      return Icons.cloud;
    }
    
    // 默认返回应用图标
    return Icons.apps;
  }
  
  // 获取图标颜色（基于图标类型）
  static Color getIconColor(String purpose, ColorScheme colorScheme) {
    final icon = getIcon(purpose);
    final lowerPurpose = purpose.toLowerCase().trim();
    
    // 根据类型返回不同颜色
    if (icon == Icons.account_balance) {
      return Colors.green; // 银行 - 绿色
    }
    if (icon == Icons.mail) {
      return Colors.blue; // 邮箱 - 蓝色
    }
    if (icon == Icons.games || icon == Icons.sports_esports) {
      return Colors.purple; // 游戏 - 紫色
    }
    if (icon == Icons.shopping_cart || icon == Icons.shopping_bag) {
      return Colors.orange; // 购物 - 橙色
    }
    if (icon == Icons.work || icon == Icons.business) {
      return Colors.indigo; // 工作 - 靛蓝
    }
    if (icon == Icons.school || icon == Icons.book) {
      return Colors.teal; // 学习 - 青色
    }
    if (icon == Icons.music_note) {
      return Colors.pink; // 音乐 - 粉色
    }
    if (icon == Icons.movie || icon == Icons.play_circle) {
      return Colors.red; // 视频 - 红色
    }
    if (icon == Icons.chat || icon == Icons.people || icon == Icons.wechat) {
      return Colors.green; // 社交 - 绿色
    }
    if (icon == Icons.cloud) {
      return Colors.lightBlue; // 云存储 - 浅蓝
    }
    
    // 默认使用主题色
    return colorScheme.primary;
  }
  
  // 检查是否有自定义图标
  static bool hasCustomIcon(String purpose) {
    final lowerPurpose = purpose.toLowerCase().trim();
    return _iconMap.containsKey(lowerPurpose) || 
           _iconMap.keys.any((key) => lowerPurpose.contains(key) || key.contains(lowerPurpose));
  }
} 
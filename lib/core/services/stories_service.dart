import 'package:flutter/material.dart';

class StoryItem {
  final String title;
  final String content;
  final String category;
  StoryItem({required this.title, required this.content, required this.category});
}

class StoriesService extends ChangeNotifier {
  final List<StoryItem> _items = [
    StoryItem(category: 'قصص', title: 'الإصرار والنجاح', content: 'النجاح ليس نهاية، والفشل ليس قاتلاً؛ إنما الشجاعة للاستمرار هي ما يهم.'),
    StoryItem(category: 'أحاديث', title: 'فضل العلم', content: 'عن النبي ﷺ قال: "من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة".'),
    StoryItem(category: 'إلهام', title: 'حكمة اليوم', content: 'المستقبل ينتمي لأولئك الذين يؤمنون بجمال أحلامهم.'),
  ];
  List<StoryItem> getItemsByCategory(String cat) => _items.where((i) => i.category == cat).toList();
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/stories_service.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<StoriesService>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قصص وإلهام'),
          bottom: const TabBar(tabs: [Tab(text: 'قصص'), Tab(text: 'أحاديث'), Tab(text: 'إلهام')]),
        ),
        body: TabBarView(children: [
          _buildList(service, 'قصص'),
          _buildList(service, 'أحاديث'),
          _buildList(service, 'إلهام'),
        ]),
      ),
    );
  }
  Widget _buildList(StoriesService service, String cat) {
    final items = service.getItemsByCategory(cat);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (c, i) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [Padding(padding: const EdgeInsets.all(16), child: Text(items[i].content))],
        ),
      ),
    );
  }
}

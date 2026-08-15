import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  ChessBoardController controller = ChessBoardController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ألعاب ذكية'),
          bottom: const TabBar(tabs: [Tab(text: 'شطرنج'), Tab(text: 'روبيك')]),
        ),
        body: TabBarView(children: [
          Center(
            child: SingleChildScrollView(
              child: ChessBoard(
                controller: controller,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_in_ar, size: 80, color: Colors.purpleAccent),
                SizedBox(height: 16),
                Text('جاري تجهيز محرك روبيك 3D', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

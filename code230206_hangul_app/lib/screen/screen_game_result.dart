import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'screen_game_wrongWordList.dart';


class GameResultScreen extends StatefulWidget {
  static const String GameResultScreenRouteName = "/GameResultScreen";
  // GameResultScreen({required this.words, required String GameResultScreenText});
  final List<List<dynamic>> GameResultScreenText;
  GameResultScreen({required this.GameResultScreenText});

  @override
  _GameResultScreenState createState() => _GameResultScreenState();
}


class _GameResultScreenState extends State<GameResultScreen>{


  @override
  Widget build(BuildContext context) {
    // 스크린 사이즈 정의
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    final args = ModalRoute.of(context)!.settings.arguments as GameResultScreen;
    final List<List<dynamic>> words = List.from((args.GameResultScreenText));

    int correctCount = 0;
    for (var word in words) {
      if (word[2] == true) { correctCount++; }
    }

    String message;
    if (correctCount == 10) {
      message = '최고에요!';
    } else if (correctCount >= 7) {
      message = '훌륭해요!';
    } else if (correctCount >= 5) {
      message = '잘했어요!';
    } else {
      message = '조금만 더 노력해 봐요!';
    }

    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFFF3F3F3),
            elevation: 0.0,
            title: Text(
              "I HANGUL",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$correctCount/${words.length}',
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 16),
                Text( message, style: TextStyle(fontSize: 24),),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, GameWrongWordListScreen.GameWrongWordListScreenRouteName, arguments: GameWrongWordListScreen(GameWrongWordListScreenText: words));
                  },
                  child: Text('단어 다시보기',
                    style: TextStyle(
                        fontSize: 20,
                      color: Colors.black
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 랭킹 화면으로 연결
                  },
                  child: Text('기록 확인하기',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black
                    ),),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {Navigator.pop(context);},
                  child: Text('게임 나가기',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black
                    ),),
                ),
              ],
            ),
          ),
        )
    );
  }
}



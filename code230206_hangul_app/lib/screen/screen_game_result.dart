import 'package:code230206_hangul_app/configuration/my_style.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'screen_game_wrongWordList.dart';
import 'screen_game.dart';

class GameResultScreen extends StatefulWidget {
  static const String GameResultScreenRouteName = "/GameResultScreen";
  // GameResultScreen({required this.words, required String GameResultScreenText});
  final List<List<dynamic>> GameResultScreenText;
  GameResultScreen({required this.GameResultScreenText});

  @override
  _GameResultScreenState createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
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
      if (word[2] == true) {
        correctCount++;
      }
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title:Image.asset("assets/images/i_hangul.png"),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(),
                ),
                Text(
                  '$correctCount/${words.length}',
                  style: TextStyle(fontSize: 48),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: width * 0.5,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:MaterialStateProperty.all<Color>(Colors.white),),
                    onPressed: () {
                      Navigator.pushNamed(context,
                          GameWrongWordListScreen.GameWrongWordListScreenRouteName,
                          arguments: GameWrongWordListScreen(
                              GameWrongWordListScreenText: words));
                    },
                    child: Text(
                      '단어 다시보기',
                      style: TextStyle(fontSize: 20, color: MyColor.accentColor),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: width * 0.5, // <-- Your width
                  height: 50, // <-- Your height
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:MaterialStateProperty.all<Color>(Colors.white),),
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => GameScreen()));
                    },
                    child: Text(
                      '다시풀기',
                      style: TextStyle(fontSize: 20, color: MyColor.accentColor),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: width * 0.5, // <-- Your width
                  height: 50, // <-- Your height
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:MaterialStateProperty.all<Color>(Colors.white),),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '게임 나가기',
                      style: TextStyle(fontSize: 20, color: MyColor.accentColor),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ),
    ));
  }
}

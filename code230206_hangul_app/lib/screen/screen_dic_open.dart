// *** 사전 open 스크린 ***
// screen_dic.dart에서 클릭한 단어에 대한 다음 사전 검색 결과를 보여주는 스크린

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'screen_dic_open.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


//Web scraping 참고: https://github.com/muath-gh/flutter_web_scraping

class DicOpenScreen extends StatefulWidget {
  static const String DicOpenScreenRouteName = "/DicOpenScreen";
  final String DicOpenScreenText;

  DicOpenScreen({required this.DicOpenScreenText});

  @override
  _DicOpenScreen createState() => _DicOpenScreen();
}

class _DicOpenScreen extends State<DicOpenScreen> {

  // star 토글 위한 함수
  // bool _isStarred = false;
  // List<bool> _starred = [];


  late User? user;
  late DocumentReference userRef;
  late CollectionReference wordsRef;

  List<dicWord> dicWords = [];
  List<bool> _starred = [];

  void _initializeUserRef() {
    user = FirebaseAuth.instance.currentUser;
    userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    wordsRef = userRef.collection('words');
  }

  @override
  void initState() {
    super.initState();
    _initializeUserRef();
    _starred = List.generate(dicWords.length, (_) => false);
  }

  @override
    Widget build(BuildContext context) {

    // 스크린 사이즈 정의
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    final args = ModalRoute.of(context)!.settings.arguments as DicOpenScreen;
    final WebScraper webScraper = WebScraper(args.DicOpenScreenText);

    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              toolbarHeight: width * 0.15,
              title: Text("I HANGUL"),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20)),
                    gradient: LinearGradient(
                        colors: [Colors.deepPurpleAccent, Colors.deepPurple],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)),
              ),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(width * 0.03),
              child: FutureBuilder(
                future: webScraper.extractData(),
                builder: (_, snapShot) {
                  if (snapShot.hasData) {
                    dicWords = snapShot.data as List<dicWord>;
                    if (_starred.length != dicWords.length) { // check if length of _starred list needs to be updated
                      _starred = List.generate(dicWords.length, (_) => false); // update _starred list
                    }
                    // List<bool> _starred = List.generate(dicWords.length, (_) => false);// 모든 _starred 값을 false로 초기화
                    print('if (snapShot.hasData)' + _starred.join());

                    // _starred = List.filled(dicWords.length, false);


                    return Column(
                      children: [
                        Text(
                          '${args.DicOpenScreenText}',
                          style: TextStyle(
                            fontSize: width * 0.050,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10), // add some vertical spacing
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: dicWords.length,
                          itemBuilder: (_, index) {
                            String word = dicWords[index].txt_emph;
                            return FutureBuilder<DocumentSnapshot>(
                              future: wordsRef.doc(word).get(),
                                builder: (context, snapshot){
                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    _starred[index] = true; // set _starred[index] to true if the word exists in Firestore
                                  } else {
                                    _starred[index] = false; // set _starred[index] to false if the word doesn't exist in Firestore
                                  }

                                  return Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: ElevatedButton( // 단어 버튼
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.white,
                                            onPrimary: Colors.black,
                                          ),
                                          child: ListTile(
                                              title: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 5),
                                                child: ListTile(
                                                  title: Padding(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Text(dicWords[index].txt_emph, style: const TextStyle(fontSize: 20)),
                                                  ),
                                                ),
                                              ),
                                              subtitle: Text(dicWords[index].txt_mean, style: const TextStyle(fontSize: 15)),
                                              trailing: IconButton(
                                                onPressed: (){
                                                  setState(() {
                                                    _starred[index] = !_starred[index];
                                                  });
                                                  if (_starred[index]){
                                                    // wordsRef.doc(word).set({'word': dicWords[index].txt_emph}); // add word to Firestore if it doesn't exist
                                                    wordsRef.doc(word).set({'word': dicWords[index].txt_emph, 'meaning': dicWords[index].txt_mean}); // add word to Firestore if it doesn't exist
                                                  } else {
                                                    wordsRef.doc(word).delete(); // remove word from Firestore if it exists
                                                  }
                                                },
                                                icon: Icon(
                                                  _starred[index] ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                ),
                                              )
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  );
                                }
                            );



                          },
                        ),
                      ],
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            )
        )
    );
  }

  void _saveWord(String txt_emph, String txt_mean) async {
    final word = txt_emph;
    final meaning = txt_mean;
    await wordsRef.doc(word).set({'meaning': meaning});
  }

  void _deleteWord(String txt_emph, String txt_mean) async {
    final word = txt_emph;
    await wordsRef.doc(word).delete();
  }
  //
  // Future<void> checkWordExists(String word, int index) async {
  //   final docSnapshot = await FirebaseFirestore.instance.collection('words').doc(word).get();
  //
  //   if (docSnapshot.exists) {
  //     setState(() {
  //       _starred[index] = true;
  //     });
  //   } else {
  //     setState(() {
  //       _starred[index] = false;
  //     });
  //   }
  // }

}

// 네이버 버전
//
// class WebScraper {
//   String searchWord;
//
//   WebScraper(this.searchWord);
//
//   Future<List<dicWord>> extractData() async {
//     String url = "https://ko.dict.naver.com/#/search?query=" +
//         Uri.encodeComponent(searchWord);
//
//     http.Response response = await http.get(Uri.parse(url));
//     List<dicWord> dicWords = [];
//
//
//     if (response.statusCode == 200) {
//       final document = parser.parse(response.body);
//
//       // final container = document.querySelectorAll(".search_result_box");
//       final container = document.querySelectorAll(".component_keyword");
//
//       print('container: ${container}');
//
//       container.forEach((element) {
//         try {
//           final txt_emph =
//           element.querySelector(".search_title .title")?.text ?? "";
//           // print('error: ${e}');
//
//
//           final txt_mean =
//           element.querySelector(".search_mean .meaning")?.text ?? "";
//
//           dicWords.add(dicWord(txt_emph: txt_emph, txt_mean: txt_mean));
//         } catch (e) {
//           print('error: ${e}');
//         }
//       });
//     }
//
//     return dicWords;
//   }
// }

class WebScraper {
  final String searchWord;

  WebScraper(this.searchWord);

  Future<List<dicWord>> extractData() async {
    final url = "https://dic.daum.net/search.do?q=${Uri.encodeComponent(searchWord)}&dic=kor";

    final response = await http.get(Uri.parse(url));

    final dicWords = <dicWord>[];

    if (response.statusCode == 200) {
      final html = parser.parse(response.body);

      // final container = html.querySelectorAll('.card_word');
      final container = html.querySelectorAll('.search_box');



      for (final element in container) {
        // ver 1 -> 1번 단어만 나옴
        // final txt_emph = element.querySelector('.txt_cleansch .txt_emph1')?.text;
        // final txt_mean = element.querySelector('.list_search .txt_search')?.text;


        // ver2 -> 1번 단어만 나옴
        // final txt_emph = element.querySelector('.search_word .txt_searchword .txt_emph1')?.text;
        // final txt_mean = element.querySelector('.list_search .txt_search')?.text;


        final txt_emph = element.querySelector('.txt_cleansch .txt_emph1')?.text;
        final txt_mean = element.querySelector('.list_search .txt_search')?.text;

        if (txt_emph != null && txt_mean != null) {
          dicWords.add(dicWord(txt_emph: txt_emph, txt_mean: txt_mean));
        }
      }
    }

    return dicWords;
  }
}


// 다음 사전 클린 버전
// class WebScraper {
//   final String searchWord;
//
//   WebScraper(this.searchWord);
//
//   Future<List<dicWord>> extractData() async {
//     final url = "https://dic.daum.net/search.do?q=${Uri.encodeComponent(searchWord)}";
//
//     final response = await http.get(Uri.parse(url));
//
//     final dicWords = <dicWord>[];
//
//     if (response.statusCode == 200) {
//       final html = parser.parse(response.body);
//
//       // final container = html.querySelectorAll('.card_word > .cleanword_type');
//       final container = html.querySelectorAll('.card_word');
//
//
//       for (final element in container) {
//         final txt_emph = element.querySelector('.tit_cleansch .txt_emph1')?.text;
//         final txt_mean = element.querySelector('.list_search .txt_search')?.text;
//
//         if (txt_emph != null && txt_mean != null) {
//           dicWords.add(dicWord(txt_emph: txt_emph, txt_mean: txt_mean));
//         }
//       }
//     }
//
//     return dicWords;
//   }
// }



// // 다음 사전 Web scraping 클래스
// // 수정 필요
// class WebScraper {
//   String searchWord = '';
//
//   WebScraper(String searchWord)
//       : this.searchWord = searchWord;
//
//   Future<List<dicWord>> extractData() async {
//     // String url = "https://dic.daum.net/search.do?q=" + Uri.encodeComponent(searchWord); //1개용
//     String url = "https://dic.daum.net/search.do?q=" + Uri.encodeComponent(searchWord);
//
//     // String url = "https://ko.dict.naver.com/#/search?query=" + Uri.encodeComponent(searchWord);
//     http.Response response = await http.get(Uri.parse(url));
//     List<dicWord> dicWords = [];
//     if (response.statusCode == 200) {
//       final html = parser.parse(response.body);
//       // container: item-cells-wrap //전체 감싼거
//       // div: item-container // 상품 하나
//
//       // final container = html.querySelector(".component_keyword has-saving-function")!.children; //전체 감싼거 //네이버
//       final container = html.querySelector(".card_word")!.children; //전체 감싼거 //다음
//       // final container = html.querySelector(".inner_toop")!.children; //전체 감싼거 //다음 // 1개용
//
//       container.forEach((element) {
//         try {
//           //검색시 맨 위에 있는 메인 단어 보여줌 - 70%커버
//           // String txt_emph = element.getElementsByClassName("search_cleanword")[0].querySelector(".tit_cleansch .txt_emph1")!.text; // 다음
//           // String txt_mean = element.getElementsByClassName("list_search")[0].querySelector(".txt_search")!.text; // 다음
//
//           //검색시 단어 리스트들 보여줌(메인X) 메인 단어가 있을 경우 뜻이 밀리는 문제 발생
//           String txt_emph = element.getElementsByClassName("search_word")[0].querySelector(".tit_searchword .txt_searchword")!.text; // 다음
//           String txt_mean = element.getElementsByClassName("list_search")[0].querySelector(".txt_search")!.text; // 다음
//
//           dicWords.add(dicWord(txt_emph:txt_emph, txt_mean: txt_mean));
//
//         } catch (e) {
//           print(e);
//         }
//       });
//     }
//     return dicWords;
//   }
// }

class dicWord {
  String txt_emph ='init';
  String txt_mean = 'init';

  dicWord(
      {required this.txt_emph, required this.txt_mean});
}

//

class StarIcon extends StatefulWidget {
  final bool starred;
  final Function onPressed;

  StarIcon({this.starred = false, required this.onPressed});

  @override
  _StarIconState createState() => _StarIconState();
}

class _StarIconState extends State<StarIcon> {
  bool _starred = false;

  @override
  void initState() {
    _starred = widget.starred;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_starred ? Icons.star : Icons.star_border),
      onPressed: () {
        widget.onPressed();
        setState(() {
          _starred = !_starred;
        });
      },
    );
  }
}

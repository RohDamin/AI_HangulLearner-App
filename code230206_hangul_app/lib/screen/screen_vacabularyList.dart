// *** 단어장 스크린 ***
// firestore에 저장된 단어/뜻 리스트를 보여주는 스크린

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangul/hangul.dart';
import 'package:floating_action_bubble_custom/floating_action_bubble_custom.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:code230206_hangul_app/configuration/hangul_scroll.dart';
import 'package:code230206_hangul_app/configuration/my_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';


class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({Key? key}) : super(key: key);

  @override
  _VocabularyListScreenState createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen>
    with SingleTickerProviderStateMixin {
  late User user;
  late CollectionReference wordsRef;
  List<QueryDocumentSnapshot> starredWords = [];

  //FloatButton Animation
  late Animation<double> _animation;
  late AnimationController _animationController;

  //hidden
  bool _hiddenWord = false;
  bool _hiddenMeaning = false;
  bool isPlaysound = false;

  //TTS
  final FlutterTts _tts = FlutterTts(); // tts


  @override
  void initState() {
    super.initState();
    _initializeUserRef();
    _getStarredWords();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
    CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    //TTS
    _tts.setLanguage('kor'); // tts - 언어 한국어
    _tts.setSpeechRate(0.3); // tts - 읽기 속도. 기본 보통 속도
  }

  void _initializeUserRef() {
    user = FirebaseAuth.instance.currentUser!;
    wordsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('words');
  }

  // Initial consonant category button list
  List<String> initialConsonants = [
    "모두",
    "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ",
    "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ",
    "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ",
    "ㅋ", "ㅌ", "ㅍ", "ㅎ",
  ];
  Map<String, String> starredWordsMap = {}; // List of words/meanings displayed on the screen
  Map<String, String> filteredWordsMap = {}; // List for initial consonant category filtering

  List<List<String>> starredWordsList = []; // List of words/meanings displayed on the screen
  List<List<String>> filteredWordsList = []; // List for initial consonant category filtering


  // Function to display the entire list of words
  // When '모두' category is selected
  void _getStarredWords() async {
    final QuerySnapshot querySnapshot = await wordsRef.get();
    setState(() {
      starredWords = querySnapshot.docs;
    });

    starredWordsList.clear();
    for (int i = 0; i < starredWords.length; i++){
      String word = starredWords[i]['word'];
      String meaning = starredWords[i]['meaning'];
      starredWordsList.add([word, meaning]);
    }
    setState(() {}); // UI Update
  }

  // Function that shows only the words of the corresponding initial consonant category
  // When 'ㄱ'~'ㅎ' category is selected
  void _getStarredWordsCategory(String initialConsonant) async {
    final QuerySnapshot querySnapshot = await wordsRef.get();
    setState(() {
      starredWords = querySnapshot.docs;
    });
    starredWordsList.clear();

    for (int i = 0; i < starredWords.length; i++){
      String word = starredWords[i]['word'];
      String meaning = starredWords[i]['meaning'];
      starredWordsList.add([word, meaning]);
    }

    filteredWordsList = [];
    bool checkConsonant = false; // 단어 카테고리에 표시할 단어가 있는지 체크

    for (int i = 0; i < starredWordsList.length; i++) {
      String word = starredWordsList[i][0];
      String meaning = starredWordsList[i][1];
      String? firstConsonant = _getFirstConsonant(word.characters.first);

      if (firstConsonant == initialConsonant) {
        filteredWordsList.add([word, meaning]);
        checkConsonant = true;
      }
    }

    starredWordsList = List.from(filteredWordsList);

    if (!checkConsonant) {
      filteredWordsList.clear();
    }

    setState(() {}); // UI Update

  }

  // extract initial consonant
  String? _getFirstConsonant(String str) {
    final Map<int, String> initialConsonants = {
      4352: 'ㄱ', 4353: 'ㄲ', 4354: 'ㄴ', 4355: 'ㄷ', 4356: 'ㄸ',
      4357: 'ㄹ', 4358: 'ㅁ', 4359: 'ㅂ', 4360: 'ㅃ', 4361: 'ㅅ',
      4362: 'ㅆ', 4363: 'ㅇ', 4364: 'ㅈ', 4365: 'ㅉ', 4366: 'ㅊ',
      4367: 'ㅋ', 4368: 'ㅌ', 4369: 'ㅍ', 4370: 'ㅎ'
    };
    if (str == null) {
      throw Exception('한글이 아닙니다');
    } else {
      String result = '';
      int unicode = str.codeUnitAt(0);

      if (unicode < 44032 || unicode > 55203) {
        print("_getFirstConsonant unicode : $unicode");
        throw Exception('unicode range error : unicode < 44032 || unicode > 55203');
      }
      int index = (unicode - 44032) ~/ 588;
      result += initialConsonants[4352 + index]!;
      return result;
    }

  }

  //sort word list random
  void _randomOrderStarredWords() {
    List<List<String>> entries = starredWordsList.toList();
    entries.shuffle();
    starredWordsList  = entries;

    setState(() {});
  }

  //sort word list consonant order
  void _consonantOrderStarredWords() {
    List<List<String>> entries = starredWordsList.toList();
    entries.sort((a, b) {
      String firstConsonantA = _getFirstConsonant(a[0].characters.first) ?? '';
      String firstConsonantB = _getFirstConsonant(b[0].characters.first) ?? '';
      return firstConsonantA.compareTo(firstConsonantB);
    });
    starredWordsList = entries;

    setState(() {});
  }

// Sort word list by newest
  void _newestOrderStarredWords() async {
    List<Map<String, dynamic>> entries = [];

    QuerySnapshot snapshot = await wordsRef.get();
    List<DocumentSnapshot> documents = snapshot.docs;

    for (DocumentSnapshot document in documents) {
      dynamic data = document.data();
      String timestamp = data['timestamp'];

      if (data != null) {
        String word = data['word'];
        String meaning = data['meaning'];
        Map<String, dynamic> entry = {'word': word, 'meaning': meaning, 'timestamp': timestamp};
        entries.add(entry);
      }
    }
    entries.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    starredWordsList = [];
    for (var entry in entries) {
      starredWordsList.add([entry['word'], entry['meaning']]);
    }
    setState(() {});
  }

  // Sort word list by oldest
  void _oldestOrderStarredWords() async {
    List<Map<String, dynamic>> entries = [];

    QuerySnapshot snapshot = await wordsRef.get();
    List<DocumentSnapshot> documents = snapshot.docs;

    for (DocumentSnapshot document in documents) {
      dynamic data = document.data();
      String timestamp = data['timestamp'];

      if (data != null) {
        String word = data['word'];
        String meaning = data['meaning'];
        Map<String, dynamic> entry = {'word': word, 'meaning': meaning, 'timestamp': timestamp};
        entries.add(entry);
      }
    }
    entries.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    starredWordsList = [];
    for (var entry in entries) {
      starredWordsList.add([entry['word'], entry['meaning']]);
    }
    setState(() {});
  }

  //hide word
  void _hideWords() {
    _hiddenWord = true;
    _hiddenMeaning = false;
    setState(() {});
  }

  //hide meaning
  void _hideMeaning() {
    _hiddenWord = false;
    _hiddenMeaning = true;
    setState(() {});
  }

  //display the word and meaning
  void _fullDisplay() {
    _hiddenWord = false;
    _hiddenMeaning = false;
    setState(() {});
  }

  //Read words and meanings in TTS
  void _speakTTS() async {
    String speakWords = starredWordsList.map((value) => '${value[0]}. ${value[1]}.').join(' ');
    _tts.speak(speakWords);
  }

  void _speakTTScard(String cardString) async {
    _tts.speak(cardString);
  }

  //Stop speaking TTS
  void _StopSpeakTts() async {
    await _tts.stop();
  }

  // delete StarredWords
  // When star icon is toggled
  void _deleteStarredWords(String word) async {
    final DocumentReference wordRef = wordsRef.doc(word);
    final bool exists = await wordRef
        .get()
        .then((DocumentSnapshot snapshot) => snapshot.exists);
    if (exists) {
      await wordRef.delete();
    } else {
      await wordRef.set({'word': word});
    }

    // If the user is selecting the '모두' category
    if (initialConsonantsIndex == 0) {
      _getStarredWords();
    }

    // If the user is selecting the 'ㄱ'~'ㅎ' category
    if (initialConsonantsIndex > 0){
      _getStarredWordsCategory(initialConsonants[initialConsonantsIndex]);
    }
  }

  // Index of initialConsonants
  int initialConsonantsIndex = 0;

  String dropdownValue = "가나순";

  @override
  Widget build(BuildContext context) {
    // 스크린 사이즈 정의
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return WillPopScope(
        onWillPop: () async {
          _StopSpeakTts(); // Stop TTS when back button is pressed
          return true; // Allow navigation to occur
        },
      child: Scaffold(
        appBar:
        AppBar(
          backgroundColor: Color(0xFFF3F3F3),
          elevation: 0.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _StopSpeakTts();
              Navigator.of(context).pop();
            },
          ),
          title: Text("I HANGUL",style: TextStyle(color: Colors.black,),),
          centerTitle: true,
        ),

        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        // // Init Floating Action Bubble
        // floatingActionButton: FloatingActionBubble(
        //   // Menu items
        //   items: <Widget>[
        //     BubbleMenu(
        //         title: "    Order",
        //         style: TextStyle(color: Color.fromARGB(255, 51, 153, 255)),
        //         iconColor: Color.fromARGB(255, 51, 153, 255),
        //         bubbleColor: Color.fromARGB(255, 255, 255, 255),
        //         icon: Icons.bar_chart,
        //         onPressed: _consonantOrderStarredWords),
        //     BubbleMenu(
        //         title: "Random",
        //         style: TextStyle(color: Color.fromARGB(255, 51, 153, 255)),
        //         iconColor: Color.fromARGB(255, 51, 153, 255),
        //         bubbleColor: Color.fromARGB(255, 255, 255, 255),
        //         icon: Icons.bar_chart,
        //         onPressed: _randomOrderStarredWords),
        //     BubbleMenu(
        //         title: "전체 읽기",
        //         style: TextStyle(color: Color.fromARGB(255, 51, 153, 255)),
        //         iconColor: Color.fromARGB(255, 51, 153, 255),
        //         bubbleColor: Color.fromARGB(255, 255, 255, 255),
        //         icon: Icons.volume_up_outlined,
        //         onPressed: _speakTTS),
        //     BubbleMenu(
        //         title: "읽기 중단",
        //         style: TextStyle(color: Color.fromARGB(255, 51, 153, 255)),
        //         iconColor: Color.fromARGB(255, 51, 153, 255),
        //         bubbleColor: Color.fromARGB(255, 255, 255, 255),
        //         icon: Icons.stop,
        //         onPressed: _StopSpeakTts),
        //   ],
        //
        //   // animation controller
        //   animation: _animation,
        //
        //   // On pressed change animation state
        //   onPressed: () => _animationController.isCompleted
        //       ? _animationController.reverse()
        //       : _animationController.forward(),
        //
        //   // Floating Action button Icon color
        //   iconColor: Colors.blue,
        //
        //   // Flaoting Action button Icon
        //   iconData: Icons.add_circle_outline,
        //   backgroundColor: Colors.white,
        // ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Spacer(),
                Checkbox(
                  value: _hiddenWord,
                  onChanged: (value) {
                    if(_hiddenWord==false&&_hiddenMeaning==false){
                      setState(() {
                        _hiddenWord = true;
                      });
                    }else if(_hiddenWord==true&&_hiddenMeaning==false){
                      setState(() {
                        _hiddenWord = false;
                      });
                    }else if(_hiddenWord==false&&_hiddenMeaning==true){
                      setState(() {
                        _hiddenWord = true;
                        _hiddenMeaning=false;
                      });
                    }
                  },
                ),
                Text("단어숨김"),
                Spacer(),
                Checkbox(
                  value: _hiddenMeaning,
                  onChanged: (value) {
                    if(_hiddenWord==false&&_hiddenMeaning==false){
                      setState(() {
                        _hiddenMeaning = true;
                      });
                    }else if(_hiddenWord==false&&_hiddenMeaning==true){
                      setState(() {
                        _hiddenMeaning = false;
                      });
                    }else if(_hiddenWord==true&&_hiddenMeaning==false){
                      setState(() {
                        _hiddenWord = false;
                        _hiddenMeaning=true;
                      });
                    }
                  },
                ),
                Text("뜻숨김"),
                Spacer(),
                IconButton(
                  icon: Icon(isPlaysound?CupertinoIcons.pause:Icons.keyboard_voice),
                  onPressed: () {
                    setState(() {
                      isPlaysound=!isPlaysound;
                    });
                    if (isPlaysound){
                      _speakTTS();
                    } else {
                      _StopSpeakTts();
                    }
                  },
                ),
                Spacer(),
                DropdownButton(
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(child: Text("가나순", style: TextStyle(color: Colors.black),), value: "가나순",),
                      DropdownMenuItem(child: Text("랜덤순", style: TextStyle(color: Colors.black),), value: "랜덤순",),
                      DropdownMenuItem(child: Text("최신순", style: TextStyle(color: Colors.black),), value: "최신순",),
                      DropdownMenuItem(child: Text("오래된순", style: TextStyle(color: Colors.black),), value: "오래된순",),

                    ],
                    value: dropdownValue,
                    elevation: 10,
                    icon: Icon(Icons.reorder),
                    onChanged: (selectValue) {
                      dropdownValue = selectValue!;
                      if(dropdownValue == "가나순"){
                        setState(() {
                          _consonantOrderStarredWords();
                        });
                      }
                      if(dropdownValue == "랜덤순"){
                        setState(() {
                          _randomOrderStarredWords();
                        });
                      }
                      if(dropdownValue == "최신순"){
                        setState(() {
                          _newestOrderStarredWords();
                        });
                      }
                      if(dropdownValue == "오래된순"){
                        setState(() {
                          _oldestOrderStarredWords();
                        });
                      }
                    }),
                Spacer(),
              ],
            ),

            Expanded(
              child: Padding(
                  padding: EdgeInsets.all(width * 0.01),
                  child: Row(children: [
                    Expanded(
                      child: Padding(
                          padding: EdgeInsets.all(width * 0.005),
                          child: starredWordsList.isEmpty
                              ? Center(child: const Text('단어장에 단어가 존재하지 않습니다'))
                              : ListView.builder(
                                itemCount: starredWordsList.length,
                                itemBuilder: (_, index) {
                              final String word = starredWordsList[index][0];
                              final String meaning = starredWordsList[index][1];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    word, style:  TextStyle(fontSize: 20,color: _hiddenWord?Colors.white:Colors.black),
                                  ),
                                  subtitle: Text(
                                    meaning, style:  TextStyle(fontSize: 16,color: _hiddenMeaning?Colors.white:Colors.black87),
                                  ),
                                  onTap: () {
                                    _StopSpeakTts();
                                    _speakTTScard('$word. $meaning');
                                  },
                                  trailing: Container(
                                    width: 30,
                                    child: IconButton(
                                        icon: Icon(Icons.star),
                                        color: Colors.orangeAccent,
                                        // onPressed: () {_toggleWordStarred(word);},
                                        onPressed: () async {
                                          showDialog(
                                              context: context,
                                              barrierDismissible:
                                              true, // 바깥 터치시 close
                                              builder:
                                                  (BuildContext context) {
                                                return AlertDialog(
                                                  content:
                                                  Text('단어를 삭제하시겠습니까?'),
                                                  actions: [
                                                    TextButton(
                                                      child:
                                                      const Text('아니요', style: TextStyle(color: Colors.black)),
                                                      onPressed: () {Navigator.of(context).pop();},
                                                    ),
                                                    TextButton(
                                                      child:
                                                      const Text('네', style: TextStyle(color: Colors.black)),
                                                      onPressed: () {_deleteStarredWords(word);
                                                      Navigator.of(context).pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              });
                                        }),
                                  )
                                ),
                              );
                            },
                          )),
                    ),
                    Column(
                      children: <Widget>[
                        Container(
                          width: width * 0.1,
                          height: height * 0.8,
                          child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            // itemExtent: 25,
                            itemCount: initialConsonants.length,
                            itemBuilder: (BuildContext context, int index) {
                              return SizedBox(
                                // height: 20,
                                child: ListTile(
                                  title: Text(initialConsonants[index],
                                    style: TextStyle(color: initialConsonantsIndex == index ? Colors.white : Colors.black,),),
                                  tileColor: initialConsonantsIndex == index
                                      ? Color(0xFF74b29e)
                                      : null,
                                  dense: true,
                                  visualDensity:
                                  VisualDensity(horizontal: 0, vertical: -4),
                                  onTap: () {
                                    _StopSpeakTts();
                                    setState(() {
                                      initialConsonantsIndex = index; // Update the selected index
                                    });
                                    _getStarredWordsCategory(initialConsonants[index]);
                                    if (index == 0) {
                                      _getStarredWords();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  ])),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:convert';

import 'package:fabric/util/scrapeThread.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './util/constants.dart' as Constants;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fabric',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF101010,
            <int, Color>{
              50: Colors.white,
              100: Colors.white,
              300: Colors.white,
              400: Colors.white,
              500: Colors.white,
              600: Colors.white,
              700: Colors.white,
              800: Colors.white,
              900: Colors.white,
            },
          ),
          brightness: Brightness.dark,
          primaryColorDark: Colors.white,
          backgroundColor: Colors.white,
          cardColor: Colors.white,
          accentColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: const MaterialColor(
            0xFF101010,
            <int, Color>{
              50: Color(0xFF101010),
              100: Color(0xFF101010),
              300: Color(0xFF101010),
              400: Color(0xFF101010),
              500: Color(0xFF101010),
              600: Color(0xFF101010),
              700: Color(0xFF101010),
              800: Color(0xFF101010),
              900: Color(0xFF101010),
            },
          ),
          brightness: Brightness.dark,
          primaryColorDark: const Color(0xFF101010),
          backgroundColor: const Color(0xFF101010),
          cardColor: const Color(0xFF101010),
          accentColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Fabric 🧵'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  Future<List<String>> _loadSavedThreads() async {
    print('load the saved threads data');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedThreads =
        prefs.getStringList(Constants.key_SAVED_THREADS_MAP) ?? [];
    return savedThreads;
  }

  Future _getSavedThreadData(fabricUUID) async {
    print('load saved thread data');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('thread-${fabricUUID}')!;
    return jsonDecode(jsonString);
  }

  late Future<List<String>> loadTheSavedThreads = _loadSavedThreads();

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color secondaryAccent = isDarkMode ? const Color(0xff4C4C4C) : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title,
            style: const TextStyle(
              fontFamily: 'InstagramSans',
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              FutureBuilder<List<String>>(
                future: loadTheSavedThreads,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Display a loading indicator while waiting for the data
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // Display an error message if an error occurs
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Display the ListView with the generated items
                    return ListView(
                      shrinkWrap: true,
                      children: snapshot.data!.map((thread) {
                        return FutureBuilder(
                          future: _getSavedThreadData(thread),
                          builder: (context, snapshot2) {
                            if (snapshot2.connectionState ==
                                ConnectionState.waiting) {
                              // Display a loading indicator while waiting for the data
                              return CircularProgressIndicator();
                            } else if (snapshot2.hasError) {
                              // Display an error message if an error occurs
                              return Text('Error: ${snapshot.error}');
                            } else {
                              var userData = snapshot2.data['data']['data']
                                      ['containing_thread']['thread_items'][0]
                                  ['post']['user'];

                              var isVerified = userData['is_verified'] ||
                                  userData['username'] == 'sethui9';

                              var caption = snapshot2.data['data']['data']
                                      ['containing_thread']['thread_items'][0]
                                  ['post']['caption']['text'];
                              // Display the ListView with the generated items
                              return Column(children: [
                                ListTile(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      showModalBottomSheet(
                                        showDragHandle: true,
                                        builder: (context) {
                                          return Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 30),
                                            child: Wrap(
                                              alignment: WrapAlignment.start,
                                              children: [
                                                ListTile(
                                                  iconColor: Colors.red,
                                                  textColor: Colors.red,
                                                  leading: Icon(Icons.delete),
                                                  title: Text('Delete'),
                                                ),
                                                ListTile(
                                                  leading: Icon(
                                                      CupertinoIcons.share),
                                                  title: Text('Share'),
                                                ),
                                                ListTile(
                                                  leading: Icon(Icons.copy),
                                                  title: Text('Copy Text'),
                                                ),
                                                Center(
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: Colors
                                                          .purple, // background
                                                      onPrimary: Colors
                                                          .white, // foreground
                                                    ),
                                                    onPressed: () {},
                                                    child: const Text(
                                                      'Open in Threads',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily:
                                                            'InstagramSans',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        context: context,
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.purple,
                                      backgroundImage: NetworkImage(
                                          userData['profile_pic_url']),
                                      radius: 15,
                                    ),
                                    title: Row(children: [
                                      Text(
                                        userData['username'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(width: 3.5),
                                      if (isVerified)
                                        Icon(
                                          Icons.verified,
                                          color: Colors.blue,
                                          size: 14,
                                        ),
                                    ]),
                                    subtitle: Text(
                                      caption,
                                    ),
                                    trailing: Column(
                                      children: [
                                        Text('4d',
                                            style: TextStyle(
                                                color: secondaryAccent)),
                                        const Spacer(),
                                        // Icon(
                                        //   Ionicons.ellipsis_horizontal,
                                        //   color: secondaryAccent,
                                        // ),
                                      ],
                                    )),
                                Divider(
                                  thickness: 0.3,
                                  color: secondaryAccent,
                                ),
                              ]);
                            }
                          },
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.purple, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData('text/plain');

                    if (data != null) {
                      if (data.text!.startsWith('https://www.threads.net/t/')) {
                        print('Scraping ${data.text}');
                        await saveThread(Uri.parse(data.text!));
                        setState(() {
                          loadTheSavedThreads = _loadSavedThreads();
                        });
                      } else {
                        print('Not a Threads link');
                      }
                    } else {
                      print('no text clipboard data');
                    }
                  },
                  child: const Text(
                    'Paste Threads 🧵 Link',
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'InstagramSans',
                        fontWeight: FontWeight.bold),
                  ),
                )),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: const TextStyle(
          fontSize: 0,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 0,
        ),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Ionicons.home : Ionicons.home_outline,
              color: _selectedIndex == 0 ? Colors.white : secondaryAccent,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1
                  ? Ionicons.settings
                  : Ionicons.settings_outline,
              color: _selectedIndex == 1 ? Colors.white : secondaryAccent,
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:fabric/util/scrapeThread.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ionicons/ionicons.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './util/constants.dart' as Constants;
import 'package:timeago/timeago.dart' as timeago;

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
          fontFamily: 'SFPro',
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
          fontFamily: 'SFPro',
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
        home: const LoaderOverlay(
          useDefaultLoading: false,
          overlayWidget: Center(
            child: SpinKitDoubleBounce(
              color: Colors.red,
              size: 50.0,
            ),
          ),
          child: MyHomePage(title: 'Fabric 🧵'),
        ));
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
      body: CupertinoScrollbar(
        child: FutureBuilder<List<String>>(
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
              return ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final thread = snapshot.data![index];
                  return FutureBuilder(
                    future: _getSavedThreadData(thread),
                    builder: (context, snapshot2) {
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
                            var threadItems = snapshot2.data['data']['data']
                                ['containing_thread']['thread_items'];

                            Widget makeThread(int index,
                                ScreenshotController screenshotController) {
                              var userData = snapshot2.data['data']['data']
                                      ['containing_thread']['thread_items']
                                  [index]['post']['user'];

                              var isVerified = userData['is_verified'] ||
                                  userData['username'] == 'sethui9';

                              var caption = snapshot2.data['data']['data']
                                      ['containing_thread']['thread_items']
                                  [index]['post']['caption']['text'];

                              int postedTimeStamp = snapshot2.data['data']
                                      ['data']['containing_thread']
                                  ['thread_items'][index]['post']['taken_at'];

                              String publicThreadID = snapshot2.data['data']
                                      ['data']['containing_thread']
                                  ['thread_items'][index]['post']['code'];

                              String threadURL =
                                  'https://www.threads.net/t/${publicThreadID}';

                              var videoData = snapshot2.data['data']['data']
                                      ['containing_thread']['thread_items']
                                  [index]['post']['video_versions'];

                              bool isVideo = videoData.length > 0;

                              if (isVideo) {
                                String videoURL = videoData[0]['url'];
                              }

                              // Display the ListView with the generated items
                              DateTime postedTime =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      postedTimeStamp * 1000);

                              print(postedTime);

                              String sincePostTime = timeago.format(postedTime,
                                  locale: 'en_short');

                              Widget threadNool = SizedBox(
                                width: 2,
                                height: 10,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: secondaryAccent),
                                ),
                              );

                              return ListTile(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    showModalBottomSheet(
                                      showDragHandle: true,
                                      builder: (context) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 30),
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
                                                leading:
                                                    Icon(CupertinoIcons.share),
                                                title: Text('Share'),
                                                onTap: () async {
                                                  await screenshotController
                                                      .capture(
                                                          delay: const Duration(
                                                              milliseconds: 10))
                                                      .then((Uint8List?
                                                          image) async {
                                                    if (image != null) {
                                                      final directory =
                                                          await getApplicationDocumentsDirectory();
                                                      final imagePath = await File(
                                                              '${directory.path}/image.png')
                                                          .create();
                                                      await imagePath
                                                          .writeAsBytes(image);

                                                      /// Share Plugin
                                                      await Share.shareFiles(
                                                          [imagePath.path],
                                                          text: threadURL);
                                                    }
                                                  });
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(Icons.copy),
                                                title: Text('Copy Text'),
                                              ),
                                              Center(
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
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
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (threadItems.length > 1 && index != 0)
                                        threadNool,
                                      FutureBuilder<Widget>(
                                        future: profilePic(userData),
                                        builder: (context, snapshot3) {
                                          if (snapshot3.connectionState ==
                                              ConnectionState.waiting) {
                                            // Display a loading indicator while waiting for the data
                                            return CircularProgressIndicator();
                                          } else if (snapshot3.hasError) {
                                            // Display an error message if an error occurs
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          } else {
                                            return snapshot3.data!;
                                          }
                                        },
                                      ),
                                      if (threadItems.length > 1 &&
                                          index < threadItems.length - 1)
                                        threadNool
                                    ],
                                  ),
                                  title: Row(children: [
                                    Text(
                                      userData['username'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
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
                                      Text(sincePostTime,
                                          style: TextStyle(
                                              color: secondaryAccent)),
                                      const Spacer(),
                                      // Icon(
                                      //   Ionicons.ellipsis_horizontal,
                                      //   color: secondaryAccent,
                                      // ),
                                    ],
                                  ));
                            }

                            List<Widget> makeAll(screenshotController) {
                              List<Widget> threadItemsList = [];
                              int index = 0;
                              for (var threadThing in threadItems) {
                                threadItemsList.add(
                                    makeThread(index, screenshotController));
                                index++;
                              }
                              return threadItemsList;
                            }

                            return StatefulBuilder(
                              builder:
                                  (BuildContext context, StateSetter setState) {
                                ScreenshotController screenshotController =
                                    ScreenshotController();

                                return Column(children: [
                                  Screenshot(
                                      controller: screenshotController,
                                      child: Column(
                                        children: makeAll(screenshotController),
                                      )),
                                  Divider(
                                    thickness: 0.3,
                                    color: secondaryAccent,
                                  ),
                                ]);
                              },
                            );
                          }
                        },
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton.extended(
          enableFeedback: true,
          backgroundColor: Colors.purple,
          onPressed: () async {
            context.loaderOverlay.show();

            ClipboardData? data = await Clipboard.getData('text/plain');

            if (data != null) {
              if (data.text!.startsWith('https://www.threads.net/t/')) {
                print('Scraping ${data.text}');
                try {
                  await saveThread(Uri.parse(data.text!));
                } catch (e) {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.ERROR,
                    animType: AnimType.BOTTOMSLIDE,
                    title: 'Error Bookmarking Thread',
                    desc:
                        'There was an error saving this thread, please try again.',
                    btnOkOnPress: () {},
                  ).show();
                  print('error saving thread (overview)');
                  print(e);
                }
                setState(() {
                  loadTheSavedThreads = _loadSavedThreads();
                });
                context.loaderOverlay.hide();
              } else {
                context.loaderOverlay.hide();
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.ERROR,
                  animType: AnimType.BOTTOMSLIDE,
                  title: 'Not a valid Threads 🧵 Link',
                  desc: 'Please copy a Threads 🧵 link and try again.',
                  btnOkOnPress: () {},
                ).show();
                print('Not a Threads link');
              }
            } else {
              context.loaderOverlay.hide();
              Fluttertoast.showToast(
                  msg: "Nothing copied to clipboard!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.purpleAccent,
                  textColor: Colors.white,
                  fontSize: 16.0);
              print('no text clipboard data');
            }
          },
          label: Text(
            'Paste Thread 🧵 Link',
            style: TextStyle(
                fontFamily: 'InstagramSans', fontWeight: FontWeight.bold),
          )),

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

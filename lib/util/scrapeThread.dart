import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart' as Constants;
import 'package:uuid/uuid.dart';

// TODO: make it save prev token and use that as default
var fbLSDToken = 'NjppQDEgONsU_1LCzrmp6q'; //default token

const commonHeaders = {
  'User-Agent': 'Barcelona ${Constants.LATEST_ANDROID_APP_VERSION} Android',
  'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
  'authority': 'www.threads.net',
  'accept': '*/*',
  'accept-language': 'en',
  'cache-control': 'no-cache',
  'origin': 'https://www.threads.net',
  'pragma': 'no-cache',
  'Sec-Fetch-Site': 'same-origin',
  'x-asbd-id': '129477',
};

Future<Map> scrapeThread(Uri url) async {
  //get internal post id
  final response = await http.get(
    url,
    headers: {
      ...commonHeaders,
      'x-fb-lsd': fbLSDToken,
      'x-ig-app-id': '238260118697367',
    },
  );

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body.contains('a good hangover')}');

  final postID =
      RegExp(r'{"post_id":"(.*?)"}').firstMatch(response.body)?.group(1);
  print('Post ID: $postID');

  final lsdToken = RegExp(r'"LSD",\[\],{"token":"(\w+)"},\d+\]')
      .firstMatch(response.body)
      ?.group(1);

  print('lsdToken: $lsdToken');

  fbLSDToken = lsdToken ?? fbLSDToken;

  var queryString =
      'lsd=${lsdToken}&variables=%7B%22postID%22%3A%22${postID}%22%7D&doc_id=5587632691339264';

  print('Query String: $queryString');

  //get post data
  final response2 = await http.post(
    Uri.parse('https://www.threads.net/api/graphql'),
    headers: {
      ...commonHeaders,
      'x-fb-lsd': fbLSDToken,
      'x-fb-friendly-name': 'BarcelonaPostPageQuery'
    },
    body: queryString,
  );

  print('Response2 status: ${response2.statusCode}');
  //print('Response2 body: ${response2.body}');

  var threadData = jsonDecode(response2.body);
  print(threadData);
  return threadData;
  // ! Handle json parse error elsewhere if not valid json
}

Future<void> downloadImage(String imageUrl, String imageName) async {
  try {
    final response = await http.get(Uri.parse(imageUrl), headers: {
      ...commonHeaders,
    });

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      final fileExtension = contentType?.split('/').last ?? 'png';

      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDocumentsDir.path}/${imageName}.$fileExtension';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      print('Image downloaded successfully');
    } else {
      throw Exception('Failed to download image');
    }
  } catch (e) {
    print('An error occurred while downloading the image: $e');
  }
}

Future<bool> isProfilePicDownloaded(String username) async {
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final filePath = '${appDocumentsDir.path}/profile-${username}.jpeg';
  final file = File(filePath);

  return file.existsSync();
}

Future<Widget> profilePic(var userData) async {
  bool isProfilePicDdl = await isProfilePicDownloaded(userData['username']);

  if (isProfilePicDdl) {
    print('image is saved');
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final filePath =
        '${appDocumentsDir.path}/profile-${userData['username']}.jpeg';
    final file = File(filePath);

    return CircleAvatar(
      backgroundColor: Colors.purple,
      backgroundImage: FileImage(file),
      radius: 15,
    );
  } else {
    print('image is not saved');
    return CircleAvatar(
        radius: 15,
        backgroundColor: Colors.purple,
        backgroundImage: NetworkImage(userData['profile_pic_url']));
  }
}

Future<bool> saveThread(Uri url) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> savedThreads =
      prefs.getStringList(Constants.key_SAVED_THREADS_MAP) ?? [];
  var uuid = const Uuid();

  try {
    var threadData = await scrapeThread(url);
    threadData['fabric-savedOn'] = DateTime.now().toString();
    var fabricUUID = uuid.v4();
    threadData['fabric-uuid'] = fabricUUID;

    //save thread to db
    prefs.setString('thread-${fabricUUID}', jsonEncode(threadData));

    savedThreads.add(fabricUUID);
    prefs.setStringList(Constants.key_SAVED_THREADS_MAP, savedThreads);

    var userData = threadData['data']['data']['containing_thread']
        ['thread_items'][0]['post']['user'];

    //download profile pic
    String profilePicURL = userData['profile_pic_url'];

    await downloadImage(profilePicURL, 'profile-${userData['username']}');

    return true;
  } catch (e) {
    print(e);
    return false;
  }
}

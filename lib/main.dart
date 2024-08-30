import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MongoDB Notification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late mongo.Db db;
  late mongo.DbCollection collection;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isConnectedToDB = false;
  bool isConnectedToInternet = false;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    checkInternetConnection();
    connectToMongoDB();
    showNotification('App Started', 'The app has started successfully.');
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> checkInternetConnection() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        isConnectedToInternet = true;
      } else {
        isConnectedToInternet = false;
      }
      setState(() {});
    } catch (e) {
      print('Error checking internet connection: $e');
      setState(() {
        isConnectedToInternet = false;
      });
    }
  }

  Future<void> connectToMongoDB() async {
    try {
      db = mongo.Db('mongodb+srv://21fycsa36rohan:isS7FVmRICRlZxtw@cluster0.fj1dt.mongodb.net/ROHAN1?retryWrites=true&w=majority');
      await db.open();
      collection = db.collection('ROHAN!');
      isConnectedToDB = true;
      showNotification('Database Connection', 'Connected to MongoDB successfully.');
      monitorCollection();
    } catch (e) {
      isConnectedToDB = false;
      print('Error connecting to MongoDB: $e');
      showNotification('Database Connection', 'Failed to connect to MongoDB: $e');
    }
    setState(() {});
  }

  Future<void> monitorCollection() async {
    mongo.ObjectId? lastDocumentId;

    while (true) {
      try {
        final latestDocument = await collection.findOne(
          mongo.where.sortBy('_id', descending: true),
        );

        if (latestDocument != null) {
          final currentDocumentId = latestDocument['_id'] as mongo.ObjectId;

          if (lastDocumentId == null || currentDocumentId != lastDocumentId) {
            lastDocumentId = currentDocumentId;
            print('New document detected: $latestDocument');
            showNotification('New Document', 'A new document has been added to MongoDB');
            await playSong();
          }
        }
      } catch (e) {
        print('Error in monitoring collection: $e');
      }

      await Future.delayed(Duration(seconds: 10));
    }
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'Your channel description',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Notification Payload',
    );
  }

  Future<void> playSong() async {
    try {
      await audioPlayer.play(AssetSource('assets/song.mp3'));
      print('Playing song...');
    } catch (e) {
      print('Failed to play song: $e');
    }
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MongoDB Notification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isConnectedToDB
                  ? 'Connected to MongoDB!'
                  : 'Failed to connect to MongoDB.',
              style: TextStyle(
                  fontSize: 20, color: isConnectedToDB ? Colors.green : Colors.red),
            ),
            SizedBox(height: 20),
            Text(
              isConnectedToInternet
                  ? 'Connected to the Internet!'
                  : 'No Internet connection.',
              style: TextStyle(
                  fontSize: 20, color: isConnectedToInternet ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    connectToMongoDB();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> connectToMongoDB() async {
    db = mongo.Db('mongodb://localhost:27017/ROHAN1');
    await db.open();

    collection = db.collection('ROHAN!');

    print('Connected to MongoDB');
    monitorCollection();
  }

  Future<void> monitorCollection() async {
    try {
      final pipeline = [
        {
          '\$match': {'operationType': 'insert'}
        }
      ];

      final changeStream = collection.watch(pipeline);

      print('Monitoring for new documents...');

      await for (var change in changeStream) {
        if (change['operationType'] == 'insert') {
          final newDocument = change['fullDocument'];
          print('New document detected: $newDocument');
          await showNotification('New Document Added', 'A new document has been added to MongoDB');
          await playSong();
        }
      }
    } catch (e) {
      print('An error occurred while monitoring the collection: $e');
    } finally {
      await db.close(); // Ensure the database connection is closed when done
      print('Stopped monitoring MongoDB collection.');
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
    await audioPlayer.play(AssetSource('Song.mp3'));
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
        child: Text(
          'Monitoring MongoDB collection...',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

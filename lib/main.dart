import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

Future<List<MarvelCharacter>> fetchPhotos(http.Client client) async {
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  String apikey='8b399c3e03be559f8a36829c14029244';
  String privKey='1a2cc2e362c7731efe3bd5a48d333389611bacf4';
  String value = timestamp+ privKey+apikey;
  String hash= md5.convert(utf8.encode(value)).toString();



  final response = await client
      .get(Uri.parse('https://gateway.marvel.com:443/v1/public/characters?limit=10&apikey=$apikey&ts=$timestamp&hash=$hash'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseCharacters, response.body);
}

// A function that converts a response body into a List<Photo>.
List<MarvelCharacter> parseCharacters(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<MarvelCharacter>((json) => MarvelCharacter.fromJson(json)).toList();
}
class Thumbnail{
  final String path;
  final String extension;

  const Thumbnail({
    required this.path,
    required this.extension
});
}


class MarvelCharacter {
  final int id;
  final String name;
  final Thumbnail thumbnail;

  const MarvelCharacter({
    required this.id,
    required this.name,
   required this.thumbnail
  });

  factory MarvelCharacter.fromJson(Map<String, dynamic> json) {
    return MarvelCharacter(
      id: json['id'] as int,
      name: json['title'] as String,
      thumbnail: json['thumbnail'] as Thumbnail
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Isolate Demo';

    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<MarvelCharacter>>(
        future: fetchPhotos(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('An error has occurred!'),
            );
          } else if (snapshot.hasData) {
            return PhotosList(photos: snapshot.data!);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  const PhotosList({Key? key, required this.photos}) : super(key: key);

  final List<MarvelCharacter> photos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Image.network(photos[index].thumbnail.path+'.'+photos[index].thumbnail.extension);
      },
    );
  }
}
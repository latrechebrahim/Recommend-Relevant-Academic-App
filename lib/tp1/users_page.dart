import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

class Userspage extends StatefulWidget {
  const Userspage({super.key, required this.path});
  final String path;

  @override
  State<Userspage> createState() => _UserspageState();
}

class _UserspageState extends State<Userspage> {
  final Random _random = Random();

  /// Generate a random color
  Color getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256), // Red
      _random.nextInt(256), // Green
      _random.nextInt(256), // Blue
      1, // Opacity
    );
  }
  /// Copies Prolog file from assets to temporary directory
  Future<String?> copyPrologFileToTemp() async {
    try {
      ByteData data = await rootBundle.load('prolog/TP.pl');

      if (data.lengthInBytes == 0) {
        print("❌ Error: Prolog file is empty.");
        return null;
      }

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/TP.pl';

      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);

      print("✅ Prolog file copied to: $tempPath");
      return tempPath;
    } catch (e) {
      print("❌ Error copying Prolog file: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> runPrologQuery(
      String? prologFilePath, String rules) async {
    if (prologFilePath == null || !(await File(prologFilePath).exists())) {
      throw Exception('❌ Error: Prolog file not found.');
    }

    String safePrologFilePath = prologFilePath.replaceAll('\\', '/');

    try {
      // Run Prolog process
      ProcessResult result = await Process.run(
        'swipl',
        [
          '-s',
          safePrologFilePath,
          '-g',
          "consult('$safePrologFilePath'),$rules."
        ],
        stdoutEncoding: utf8,
      );

      String output = result.stdout.toString().trim();
      print("🔍 Prolog Output: $output");

      // Ensure valid JSON format
      if (output.startsWith('{') && output.endsWith('}')) {
        Map<String, dynamic> jsonData = jsonDecode(output);

        // ✅ Dynamically detect the key
        for (String key in jsonData.keys) {
          if (jsonData[key] is List) {
            return List<Map<String, dynamic>>.from(jsonData[key]);
          }
        }
        throw Exception('❌ Error: No valid list found in Prolog output.');
      } else {
        throw Exception('❌ Error: Unexpected output format from Prolog.');
      }
    } catch (e) {
      throw Exception('❌ Error running Prolog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(child: fatchusers()),
          ],
        ),
      ),
    );
  }

  FutureBuilder<List<Map<String, dynamic>>> fatchusers() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: copyPrologFileToTemp().then(
          (prologPath) => runPrologQuery(prologPath, 'fetch_all_user(JSON)')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('❌ Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<Map<String, dynamic>> Users = snapshot.data!;

          return ListView.builder(
            itemCount: Users.length,
            itemBuilder: (context, index) {
              var user = Users[index];
              Color backgroundColor = getRandomColor();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          id: user["id"].toString(),
                          path:widget.path,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Container(
                      width: 350,
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          // Green Left Corner with ID Initial
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 50,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(100),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  user["id"].toString()[0],
                                  style: const TextStyle(
                                      fontSize: 24, color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                          // User Information
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 60, top: 10, right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  const SizedBox(height: 5),

                                  // Interest Tags
                                  Wrap(
                                    spacing: 6.0,
                                    runSpacing: 6.0,
                                    children: (user["indexTerms"] as String)
                                        .replaceAll("[", "")
                                        .replaceAll("]", "")
                                        .split(',')
                                        .map((term) => Chip(
                                              label: Text(term.trim()),
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text('📭 No Users  found.'));
        }
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PaperPage extends StatefulWidget {

  String pathe;
   PaperPage({super.key, required this.pathe});

  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
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
    print(rules);
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
        title: const Text('Papers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
                child: fatchpapers('load_papers('+widget.pathe+'), fetch_all_papers(JSON)'),
            ),
          ],
        ),
      ),
    );
  }

  FutureBuilder<List<Map<String, dynamic>>> fatchpapers(String commend) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: copyPrologFileToTemp()
          .then((prologPath) => runPrologQuery(prologPath, commend)),
      builder: (context, snapshot) {
        print(snapshot);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('❌ Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<Map<String, dynamic>> papers = snapshot.data!;

          return ListView.builder(
            itemCount: papers.length,
            itemBuilder: (context, index) {
              var paper = papers[index];
              return Card(

                color: Colors.greenAccent,
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Stack(
                    children: [
                  // SVG Background
                  Positioned.fill(
                    left: 0,
                    child: Opacity(
                      opacity: 0.3, // Adjust transparency for better readability
                      child: SvgPicture.network(
                        "https://dl.acm.org/specs/products/acm/releasedAssets/images/logo-ada347b17afcb4e44bd9760475dea384.svg",
                        width: 300, // Set width
                        height: 300, // Set height
                        fit: BoxFit.contain, // Adjusts how the SVG scales inside the container
                        alignment: Alignment.center, // Centers the logo
                        placeholderBuilder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),

                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      paper["title"] ?? "Unknown Title",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto'),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text("📅 Date: ",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text(" ${paper["date"] ?? "Unknown"}",
                                style: TextStyle(
                                    color: Colors.grey[900], fontSize: 16)),
                          ],
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                Text("Authors:",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(" ${paper["authors"] ?? "Unknown"}",
                                style: TextStyle(color: Colors.grey[900])),
                          ],
                        ),
                        Row(
                          children: [
                            Text("📖 Published in:",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                " ${paper["publishedIn"].isNotEmpty ? paper["publishedIn"] : "N/A"}",
                                style: TextStyle(
                                    color: Colors.grey[900], fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text("IndexTerms: ",
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8.0,
                              children: (paper["indexTerms"] as String)
                                  .replaceAll("[", "")
                                  .replaceAll("]", "")
                                  .split(',')
                                  .map((term) => Chip(
                                      label: Text(term.trim()),
                                      backgroundColor: Colors.blue.shade100))
                                  .toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("📥 ${paper["downloads"]}",
                            style:
                                TextStyle(color: Colors.green, fontSize: 14)),
                        Text("🔗 ${paper["citations"]} Citations",
                            style:
                                TextStyle(color: Colors.orange, fontSize: 14)),
                      ],
                    ),
                    onTap: () {
                      if (paper["link"] != null && paper["link"].isNotEmpty) {
                        _launchURL(context, paper["link"]);
                      }
                    },
                  ),
                ]),
              );
            },
          );
        } else {
          return const Center(child: Text('📭 No recommended papers found.'));
        }
      },
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error opening link")));
    }
  }
}

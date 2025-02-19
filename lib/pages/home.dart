import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.id, required this.path});
  final String id;
  final String path;

  @override
  State<Home> createState() => _HomeState();
}

enum FilterType { none, year, author, topics, N, year1 }

class _HomeState extends State<Home> {
  Set<FilterType> selectedFilters = {};
  bool state = false;
  bool state1 = false;

  int selectedYear = DateTime.now().year; // Store only the year
  int selectedYear1 = DateTime.now().year;
  int N = 10;
  String searchQuery = '';
  late final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _yearController = TextEditingController();
  String selectedSortOption = 'Not selected';

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

  /// Runs a Prolog query and returns the recommended papers
  Future<List<Map<String, dynamic>>> runPrologQuery(
      String? prologFilePath, String rules) async {
    print(rules);
    if (prologFilePath == null || !(await File(prologFilePath).exists())) {
      throw Exception('❌ Error: Prolog file not found.');
    }

    String safePrologFilePath = prologFilePath.replaceAll('\\', '/');

    try {
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

      if (output.startsWith('{') && output.endsWith('}')) {
        Map<String, dynamic> jsonData = jsonDecode(output);

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
    String prologQuery;
    String author = _searchController.text.trim();
    // Ensure single quotes only exist if needed
    if (author.isNotEmpty && !author.startsWith("'") && !author.endsWith("'")) {
      author = "'$author'";
    }

    if (selectedSortOption == 'Combined Interests') {
      prologQuery = 'recommend_papers_with_combined_interests(${widget.id})';
    } else if (selectedSortOption == 'Multi-Criteria') {
      prologQuery =
          'recommend_papers_by_multi_criteria(${widget.id}, $author, ${_yearController.text})';
    } else if (selectedSortOption == 'Year') {
      prologQuery =
          'recommend_papers_after_year(${widget.id}, ${_searchController.text})';
    } else if (selectedSortOption == 'Author') {
      prologQuery = 'recommend_papers_by_author(${widget.id}, $author)';
    } else if (selectedSortOption == 'Topics') {
      prologQuery =
          'recommend_papers_exclude_topics(${widget.id}, [${_searchController.text}])';
    } else if (selectedSortOption == 'N') {
      prologQuery = 'recommend_top_n_downloadable_papers(${widget.id}, ${_searchController.text})';
    } else if (selectedSortOption == 'Year1') {
      prologQuery =
          'recommend_papers_exclude_old(${widget.id}, ${_searchController.text})';
    } else {
      prologQuery = 'recommend_papers(${widget.id})';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Row(
          children: [
            selectedSortOption == 'Multi-Criteria' ? Expanded(
              child: TextField(
                controller: _yearController,
                decoration: InputDecoration(
                  hintText: 'year',
                  prefixIcon: Icon(Icons.search),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ) : Container(),
            const SizedBox(width: 10),
            (selectedSortOption == 'Combined Interests' || selectedSortOption == 'Not selected') ? Container() : Expanded(
              child: TextField(
                controller: _searchController,
                cursorColor:  Colors.white,
                style: TextStyle(color:  Colors.white,),
                decoration: InputDecoration(
                  contentPadding:

                  EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: selectedSortOption,
              items: const [
                DropdownMenuItem(value: 'Not selected', child: Text('Not selected')),
                DropdownMenuItem(value: 'Year', child: Text('filter by year')),
                DropdownMenuItem(value: 'Combined Interests', child: Text('Combined Interests')),
                DropdownMenuItem(value: 'Multi-Criteria', child: Text('Multi-Criteria')),
                DropdownMenuItem(value: 'Author', child: Text('Author')),
                DropdownMenuItem(value: 'Topics', child: Text('Topics')),
                DropdownMenuItem(value: 'N', child: Text('Most Downloaded')),
                DropdownMenuItem(value: 'Year1', child: Text('Exclude Old')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedSortOption = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      body: fetchData('load_papers(${widget.path}),$prologQuery'),
    );
  }

  Widget _buildFilterContainer({required String title, required Widget child}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 2.0,
            spreadRadius: 0.0,
            offset: Offset(2.0, 2.0),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 8),
          child,
        ],
      ),
    );
  }

  /// Fetches Prolog data
  FutureBuilder<List<Map<String, dynamic>>> fetchData(String command) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: copyPrologFileToTemp()
          .then((prologPath) => runPrologQuery(prologPath, command)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<Map<String, dynamic>> papers = snapshot.data!;

          return ListView.builder(
            itemCount: papers.length,
            itemBuilder: (context, index) {
              var paper = papers[index];

              return Card(
                color: Colors.greenAccent,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    paper["title"] ?? "Unknown Title",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("📅 Date: ${paper["date"] ?? "Unknown"}"),
                      Text("👤 Authors: ${paper["authors"] ?? "Unknown"}"),
                      Text("📖 Published in: ${paper["publishedIn"] ?? "N/A"}"),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text("IndexTerms: ",
                              style: const TextStyle(fontSize: 16)),
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
                      Text("📥 ${paper["downloads"]}"),
                      Text("🔗 ${paper["citations"]} Citations"),
                    ],
                  ),
                  onTap: () {
                    if (paper["link"] != null && paper["link"].isNotEmpty) {
                      _launchURL(paper["link"]);
                    }
                  },
                ),
              );
            },
          );
        } else {
          return const Center(
              child: Text(
            '📭 No recommended papers found.',
            style: TextStyle(fontSize: 25),
          ));
        }
      },
    );
  }

  void _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error opening link")));
    }
  }
}

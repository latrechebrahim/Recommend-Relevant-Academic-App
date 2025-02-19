import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:tpia/tp2/querys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PaperPage extends StatefulWidget {
  PaperPage({super.key});

  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = true; // Track loading state

  Future<void> fetchRecommendations(String sparqlQuery) async {
    String endpointUrl = "http://localhost:3030/DataSet/query";
    try {
      var response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          "Content-Type": "application/sparql-query",
          "Accept": "application/json",
        },
        body: sparqlQuery,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List results = jsonResponse['results']['bindings'];
        setState(() {
          recommendations = results.map((result) {
            return {
              "paper": result['paper']['value'],
              "title": result['title']['value'],
              "date": result['date']['value'],
              "citations": result['citations']['value'],
              "downloads": result['downloads']['value'],
              "link": result['link']['value'],
              "authors": result.containsKey('authors')
                  ? result['authors']['value']
                  : "Unknown",
              "indexTerms": result.containsKey('indexTerms')
                  ? result['indexTerms']['value']
                  : "None",
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecommendations(Querys().allpapers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendations.isEmpty
              ? const Center(child: Text('📭 No recommended papers found.'))
              : fatchpapers(recommendations),
    );
  }

  Widget fatchpapers(List<Map<String, dynamic>> papers) {
    return ListView.builder(
      itemCount: papers.length,
      itemBuilder: (context, index) {
        var paper = papers[index];
        return Card(
          color: Colors.green.shade100,
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          elevation: 3,
          child: Stack(
            children: [
              Positioned(
                right: 5,
                bottom: 0,
                child: Container(
                  width: 1000,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(200),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200, // Shadow color
                        blurRadius: 10, // Softness of the shadow
                        spreadRadius: 2, // How much the shadow spreads
                        offset: Offset(0, 5), // Changes the position of the shadow
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 290,
                  width: 600,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(200),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade100, // Shadow color
                        blurRadius: 10, // Softness of the shadow
                        spreadRadius: 2, // How much the shadow spreads
                        offset: Offset(0, 5), // Changes the position of the shadow
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 300,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(200),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200, // Shadow color
                        blurRadius: 10, // Softness of the shadow
                        spreadRadius: 2, // How much the shadow spreads
                        offset: Offset(0, 5), // Changes the position of the shadow
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 40,
                child: Container(
                  width: 150,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(200),
                      bottomRight: Radius.circular(0),
                      topLeft: Radius.circular(200),
                      topRight: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200, // Shadow color
                        blurRadius: 10, // Softness of the shadow
                        spreadRadius: 2, // How much the shadow spreads
                        offset: Offset(0, 5), // Changes the position of the shadow
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius:
                      BorderRadiusDirectional.all(Radius.circular(20))),
                  child: Center(
                    child: Text(
                      paper["title"] ?? "Unknown Title",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto'),
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("📅 Date: ",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8.0,
                          children: (paper["date"] as String)
                              .split(',')
                              .map((term) => Chip(
                              label: Text(term.trim()),
                              backgroundColor: Colors.blue.shade100))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(" 🧑‍🎓 authors: ",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            children: (paper["authors"] as String)
                                .split(',')
                                .map((term) => Chip(
                                label: Text(term.trim()),
                                backgroundColor: Colors.red.shade200))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("Index Terms: ",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            children: (paper["indexTerms"] as String)
                                .split(',')
                                .map((term) => Chip(
                                label: Text(term.trim()),
                                backgroundColor: Colors.blue.shade100))
                                .toList(),
                          ),
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
                        const TextStyle(color: Colors.green, fontSize: 14)),
                    Text("🔗 ${paper["citations"]} Citations",
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 14)),
                  ],
                ),
                onTap: () {
                  if (paper["link"] != null && paper["link"].isNotEmpty) {
                    _launchURL(context, paper["link"]);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("❌ Error opening link")));
    }
  }
}

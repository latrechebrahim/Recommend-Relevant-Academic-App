import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tpia/tp2/querys.dart';

import '../tp2/home.dart';

class Userspage extends StatefulWidget {
  const Userspage({super.key});

  @override
  State<Userspage> createState() => _UserspageState();
}

class _UserspageState extends State<Userspage> {
  final Random _random = Random();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  /// Generate a random color
  Color getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256), // Red
      _random.nextInt(256), // Green
      _random.nextInt(256), // Blue
      1, // Opacity
    );
  }

  Future<void> fetchUsers(String sparqlQuery) async {
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
          users = results.map((result) {
            return {
              "id": results.indexOf(result) + 1, // Generate numeric ID
              "name": result['name']['value'],
              "interests": result.containsKey('interests')
                  ? result['interests']['value']
                  : "Unknown",
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
    fetchUsers(Querys().allUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('📭 No users found.'))
              : buildUserList(users),
    );
  }

  Widget buildUserList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        var user = users[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GestureDetector(
            onTap: () {
              // Navigate to user details page (if needed)
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Home(
                        id: user["name"],
                        interests: (user["interests"] is String)
                            ? user["interests"]
                                .split(',') // Split string by comma
                                .map((term) => Chip(
                                    label: Text(term.trim()))) // Trim spaces
                                .toList()
                            : (user["interests"] is List)
                                ? (user["interests"] as List)
                                    .map((term) => Chip(
                                        label: Text(term
                                            .toString()
                                            .trim()))) // Ensure safe conversion
                                    .toList()
                                : [], // Fallback if interests is missing
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
                                user["id"].toString(),
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
                                Text(
                                  user["name"],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),

                                // Interest Tags
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 6.0,
                                  children: (user["interests"] as String)
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
            ),
          ),
        );
      },
    );
  }
}

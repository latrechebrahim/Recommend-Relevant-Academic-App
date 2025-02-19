import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tpia/tp2/querys.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.id, required this.interests});
  final String id;
  final List<dynamic> interests;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> recommendations = [];
  List<Map<String, dynamic>> Authors = [];
  List<String> selectedAuthorsUrls = [];
  List<String> selectedIndexTerms = [];
  List<String> selectedVenues = [];
  bool isLoading = true;
  String selectedSortOption = 'Not selected';

  @override
  void initState() {
    super.initState();
    fetchPapersByInterests(papperbyuser(widget.interests));
  }

  Future<void> fetchPapersByInterests(String sparqlQuery) async {
    print(sparqlQuery);
    setState(() {
      isLoading = true;
    });

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

  Future<void> fetchAuthors(String sparqlQuery,String mode) async {
    print(sparqlQuery);
    setState(() {
      isLoading = true;
    });

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
          Authors = results.map((result) {
            return {
              "author": result['$mode']['value'],
              "name": result['name']['value'],
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

  void updateFilterOption(String newOption) {
    if (selectedSortOption == newOption) return;
    setState(() {
      selectedSortOption = newOption;
      recommendations.clear();
      isLoading = true;
    });
    switch (newOption) {
      case 'Citation':
         break;
      case 'Topics':
      fetchAuthors(Querys().allIndexTerms,'indexTerm');
        break;
      case 'Prioritization':
        fetchAuthors(Querys().allVenues,'PublicationVenue');
        break;
      case 'Year':
        showYearSelectionDialog(context);
        break;
      case 'Author':
        fetchAuthors(Querys().allAuthors,'author');
        break;
      default:
        fetchPapersByInterests(papperbyuser(widget.interests));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectedSortOption == "Author")
              ElevatedButton(
                onPressed: () {
                  showAuthorSelectionDialog(context);
                },
                child: const Text("Select Authors"),
              ),
            if (selectedSortOption == "Year")
              ElevatedButton(
                onPressed: () {
                  showYearSelectionDialog(context);
                },
                child: const Text("Select Year"),
              ),
            if (selectedSortOption == "Topics")
              ElevatedButton(
                onPressed: () {
                  showTopicSelectionDialog(context);
                },
                child: const Text("Select Topics"),
              ),
            if (selectedSortOption == "Citation")
              ElevatedButton(
                onPressed: () {
                  showCitationSelectionDialog(context);
                },
                child: const Text("Citation"),
              ),
            if (selectedSortOption == "Prioritization")
              ElevatedButton(
                onPressed: () {
                  showPrioritizationSelectionDialog(context);
                },
                child: const Text("Prioritization"),
              ),
            DropdownButton<String>(
              value: selectedSortOption,
              items: const [
                DropdownMenuItem(value: 'Not selected', child: Text('Not selected')),
                DropdownMenuItem(value: 'Year', child: Text('Filter by Year')),
                DropdownMenuItem(value: 'Author', child: Text('Author')),
                DropdownMenuItem(value: 'Topics', child: Text('Topics')),
                DropdownMenuItem(value: 'Citation', child: Text('Top Citation')),
                DropdownMenuItem(value: 'Prioritization', child: Text('Prioritization')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  updateFilterOption(value);
                }
              },
            ),
            Container(
              child: Text('Welcome ${widget.id} !', style: const TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fatchpapers(recommendations),
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
  Widget fatchpapers(List<Map<String, dynamic>> papers) {
     if (papers.isNotEmpty) {
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
                          offset:
                          Offset(0, 5), // Changes the position of the shadow
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
                          offset:
                          Offset(0, 5), // Changes the position of the shadow
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
                          offset:
                          Offset(0, 5), // Changes the position of the shadow
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
                          offset:
                          Offset(0, 5), // Changes the position of the shadow
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
                                .map((term) =>
                                Chip(
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
                                  .map((term) =>
                                  Chip(
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
                                  .map((term) =>
                                  Chip(
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
    }else{
      return const Center(child: Text('📭 No recommended papers found.'));
    }
  }

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("❌ Error opening link")));
    }
  }

  void showAuthorSelectionDialog(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredAuthors =
        List.from(Authors); // Copy of the list

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Authors"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔍 Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: "Search Author",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (query) {
                          setState(() {
                            filteredAuthors = Authors.where((author) =>
                                author["name"]
                                    .toLowerCase()
                                    .contains(query.toLowerCase())).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 📜 Authors List with Checkboxes
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredAuthors.length,
                        itemBuilder: (context, index) {
                          String authorName = filteredAuthors[index]["name"];
                          String authorUrl = filteredAuthors[index]["author"];
                          bool isSelected =
                              selectedAuthorsUrls.contains(authorUrl);
                          return CheckboxListTile(
                            title: Text(authorName),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedAuthorsUrls.add(authorUrl);
                                } else {
                                  selectedAuthorsUrls.remove(authorUrl);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedAuthorsUrls
                                  .clear(); // Clear selected authors on cancel
                            });
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            fetchPapersByInterests(Author_Based_Suggestions(
                                widget.interests, selectedAuthorsUrls));
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text("Confirm Selection"),
                        ),
                      ],
                    ),

                    // ✅ Confirm Button
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showTopicSelectionDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredIndexTerms = List.from(Authors);
    String? selectedTopic; // Store only one selected topic

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select a Topic"),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: "Search Topic",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setState(() {
                      filteredIndexTerms = Authors
                          .where((term) => term["name"]
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: filteredIndexTerms.length,
                    itemBuilder: (context, index) {
                      final topic = filteredIndexTerms[index];
                      return RadioListTile<String>(
                        title: Text(topic["name"]),
                        value: topic["name"],
                        groupValue: selectedTopic,
                        onChanged: (value) {
                          setState(() {
                            selectedTopic = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        if (selectedTopic != null) {
                          fetchPapersByInterests(Generalization(selectedTopic!));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showYearSelectionDialog(BuildContext context) {
    int selectedStartYear = 2019; // Default start year
    int selectedEndYear = 2023; // Default end year
    List<int> availableYears =
        List.generate(10, (index) => 2015 + index); // Years from 2015 to 2024

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year Range"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Start Year"),
                  DropdownButton<int>(
                    value: selectedStartYear,
                    items: availableYears.map((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null && newValue <= selectedEndYear) {
                        setState(() {
                          selectedStartYear = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text("End Year"),
                  DropdownButton<int>(
                    value: selectedEndYear,
                    items: availableYears.map((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null && newValue >= selectedStartYear) {
                        setState(() {
                          selectedEndYear = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Call function to fetch filtered papers
                          fetchPapersByInterests(Year_Based_Filtering(
                              widget.interests,
                              selectedStartYear,
                              selectedEndYear));
                          Navigator.pop(context); // Close dialog
                        },
                        child: const Text("Confirm Selection"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
  void showCitationSelectionDialog(BuildContext context) {
    int selectedCitation = 0; // Default citation count (starting from 1)
    List<int> citationValues = List.generate(100, (index) => index + 1); // [1, 2, ..., 100]

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Minimum Citations"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Minimum Citation Count"),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180, // Adjusted height for better scrolling
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController( initialItem:selectedCitation  ),
                      itemExtent: 50, // Increased for better touch experience
                      perspective: 0.003, // More subtle 3D effect
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedCitation = citationValues[index];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0), // Better spacing
                            child: Text(
                              citationValues[index].toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: index == selectedCitation - 1
                                    ? Colors.blue // Highlight selected value
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                        childCount: citationValues.length,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                        },
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          fetchPapersByInterests(
                            Citation_Based_Recommendation(widget.interests, selectedCitation),
                          );
                          Navigator.pop(context); // Close dialog
                        },
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
  void showPrioritizationSelectionDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredIndexTerms = List.from(Authors);
    String? selectedTopic; // Store only one selected topic

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Venue"),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: "Search Venue",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setState(() {
                      filteredIndexTerms = Authors
                          .where((term) => term["name"]
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: filteredIndexTerms.length,
                    itemBuilder: (context, index) {
                      final topic = filteredIndexTerms[index];
                      return RadioListTile<String>(
                        title: Text(topic["name"]),
                        value: topic["name"],
                        groupValue: selectedTopic,
                        onChanged: (value) {
                          setState(() {
                            selectedTopic = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        if (selectedTopic != null) {
                          fetchPapersByInterests(Venue_Based_Prioritization(widget.interests,selectedTopic!,));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



}

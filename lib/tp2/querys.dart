import 'package:flutter/material.dart';

class Querys {
  String allpapers = """
      PREFIX :     <http://example.org/ontology#>
      PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      
      SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
             (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
             (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
      WHERE {
          ?paper rdf:type :Paper ;
                 :title ?title ;
                 :date ?date ;
                 :totalCitations ?citations ;
                 :totalDownloads ?downloads ;
                 :linkAccess ?link .
          
          OPTIONAL { ?paper :hasAuthor ?author . }
          OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
          OPTIONAL { ?paper :publishedIn ?venue . }  # Ensure venue is properly retrieved
      }
      GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
    """;
  String allUsers = """
          PREFIX : <http://example.org/ontology#>
          PREFIX owl: <http://www.w3.org/2002/07/owl#>
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          SELECT ?user ?name 
                 (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?interest), "http://example.org/ontology#", ""); separator=", "), "None") AS ?interests)
          WHERE {
              ?user a :Users ;  # Match all individuals of type :Users
                    :name ?name .  # Get the name of the user
              OPTIONAL { ?user :hasInterest ?interest }  # Get their interests (if any)
          }
          GROUP BY ?user ?name  # Group by user and name to concatenate interests
""";
  String allAuthors = """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    
    SELECT DISTINCT ?author (STR(?author) AS ?url) (REPLACE(REPLACE(STR(?author), "^.*#", ""), "_", " ") AS ?name)
    WHERE {
        ?author rdf:type :Author .
    }
    ORDER BY ?name

  """;
  String allIndexTerms = """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    
    SELECT DISTINCT ?indexTerm (STR(?indexTerm) AS ?url) (REPLACE(REPLACE(STR(?indexTerm), "^.*#", ""), "_", "_") AS ?name)
    WHERE {
        ?indexTerm rdf:type :IndexTerm .
    }
    ORDER BY ?name
""";
  String allVenues = """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    
    SELECT DISTINCT ?PublicationVenue (STR(?PublicationVenue) AS ?url) (REPLACE(REPLACE(STR(?PublicationVenue), "^.*#", ""), "_", " ") AS ?name)
    WHERE {
        ?PublicationVenue rdf:type :PublicationVenue .
    }
    ORDER BY ?name
  """;
}

String papperbyuser(List<dynamic> interests) {
  List<String> formattedInterests = [];
  for (var interest in interests) {
    // Extract text if interest is a Chip widget
    if (interest is Chip && interest.label is Text) {
      String term = (interest.label as Text).data ?? "";
      formattedInterests
          .add("<http://example.org/ontology#${term.replaceAll(' ', '_')}>");
    }
    // If it's already a string, format it directly
    else if (interest is String) {
      formattedInterests.add(
          "<http://example.org/ontology#${interest.replaceAll(' ', '_')}>");
    }
  }
  // Properly join the formatted interests
  String interestsList = formattedInterests.join(",\n    ");

  // Build the SPARQL query
  return """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
    WHERE {
        ?paper rdf:type :Paper ;
               :title ?title ;
               :date ?date ;
               :totalCitations ?citations ;
               :totalDownloads ?downloads ;
               :linkAccess ?link .
        
        OPTIONAL { ?paper :hasAuthor ?author . }
        OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
        OPTIONAL { ?paper :publishedIn ?venue . }  # Ensure venue is properly retrieved
    
        # Filtering papers by user interests
        FILTER(?indexTerm IN ($interestsList))
    }
      GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
  """;
}

String Author_Based_Suggestions(List<dynamic> interests, authors) {
  List<String> formattedInterests = [];
  List<String> formattedAuthors = [];
  print(interests);
  // Format interests
  for (var interest in interests) {
    // Extract text if interest is a Chip widget
    if (interest is Chip && interest.label is Text) {
      String term = (interest.label as Text).data ?? "";
      formattedInterests
          .add("<http://example.org/ontology#${term.replaceAll(' ', '_')}>");
    }
    // If it's already a string, format it directly
    else if (interest is String) {
      formattedInterests.add(
          "<http://example.org/ontology#${interest.replaceAll(' ', '_')}>");
    }
  }

  // Format authors
  for (var author in authors) {
    if (author is String) {
      formattedAuthors.add(
          "\"$author\""); // Wrap author names in quotes for string matching
    }
  }

  // Ensure at least one valid interest and author to prevent syntax errors
  if (formattedInterests.isEmpty)
    formattedInterests.add("<http://example.org/ontology#DefaultInterest>");
  if (formattedAuthors.isEmpty) formattedAuthors.add("\"Unknown\"");

  // Join formatted values for SPARQL query
  String interestsList = formattedInterests.join(", ");
  String authorsList = formattedAuthors.join(", ");

  print("Interests List:\n$interestsList");
  print("Authors List:\n$authorsList");

  // Build the SPARQL query with filters
  return """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

    SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
    WHERE {
        ?paper rdf:type :Paper ;
               :title ?title ;
               :date ?date ;
               :totalCitations ?citations ;
               :totalDownloads ?downloads ;
               :linkAccess ?link .
        
        OPTIONAL { ?paper :hasAuthor ?author . }
        OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
        OPTIONAL { ?paper :publishedIn ?venue . }

        # Filtering papers by user interests and authors
        FILTER(?indexTerm IN ($interestsList))
        FILTER(STR(?author) IN ($authorsList))
    }
    GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
  """;
}

String Year_Based_Filtering(List<dynamic> interests, int startYear, int endYear) {
  List<String> formattedInterests = [];
  for (var interest in interests) {
    // Extract text if interest is a Chip widget
    if (interest is Chip && interest.label is Text) {
      String term = (interest.label as Text).data ?? "";
      formattedInterests
          .add("<http://example.org/ontology#${term.replaceAll(' ', '_')}>");
    }
    // If it's already a string, format it directly
    else if (interest is String) {
      formattedInterests.add(
          "<http://example.org/ontology#${interest.replaceAll(' ', '_')}>");
    }
  }
  // Properly join the formatted interests
  String interestsList = formattedInterests.join(",\n    ");
  return """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
    WHERE {
        ?paper rdf:type :Paper ;
               :title ?title ;
               :date ?date ;
               :totalCitations ?citations ;
               :totalDownloads ?downloads ;
               :linkAccess ?link .
        
        OPTIONAL { ?paper :hasAuthor ?author . }
        OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
        OPTIONAL { ?paper :publishedIn ?venue . }
        FILTER(?indexTerm IN ($interestsList))
        # Filtering papers by publication date
        FILTER(YEAR(?date) >= $startYear && YEAR(?date) <= $endYear)
        
    }
    GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
  """;
}

String Generalization(String topic) {
  return """ 
            PREFIX : <http://example.org/ontology#>
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX owl: <http://www.w3.org/2002/07/owl#>
            SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
                   (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
                   (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
            WHERE {
                ?paper rdf:type :Paper ;
                       :title ?title ;
                       :date ?date ;
                       :totalCitations ?citations ;
                       :totalDownloads ?downloads ;
                       :linkAccess ?link ;
                       :hasIndexTerm ?indexTerm .
            
                # Topic Generalization: Include papers linked to the topic or its subclasses
                ?indexTerm (rdfs:subClassOf|owl:equivalentClass)* ?broaderTopic .
                
                # Replace `$topic` dynamically before executing the query
                FILTER (?broaderTopic = :$topic)  
            
                OPTIONAL { ?paper :hasAuthor ?author . }
                OPTIONAL { ?paper :publishedIn ?venue . }
            }
            GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
            ORDER BY DESC(?citations)
""";
}

String Citation_Based_Recommendation(List<dynamic> interests,int Citation) {
  List<String> formattedInterests = [];
  for (var interest in interests) {
    // Extract text if interest is a Chip widget
    if (interest is Chip && interest.label is Text) {
      String term = (interest.label as Text).data ?? "";
      formattedInterests
          .add("<http://example.org/ontology#${term.replaceAll(' ', '_')}>");
    }
    // If it's already a string, format it directly
    else if (interest is String) {
      formattedInterests.add(
          "<http://example.org/ontology#${interest.replaceAll(' ', '_')}>");
    }
  }
  // Properly join the formatted interests
  String interestsList = formattedInterests.join(",\n    ");
  return """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
    WHERE {
        ?paper rdf:type :Paper ;
               :title ?title ;
               :date ?date ;
               :totalCitations ?citations ;
               :totalDownloads ?downloads ;
               :linkAccess ?link .
        OPTIONAL { ?paper :hasAuthor ?author . }
        OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
        OPTIONAL { ?paper :publishedIn ?venue . }
        FILTER(?indexTerm IN ($interestsList))
        FILTER (?citations >= $Citation)
    }
    GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
    ORDER BY DESC(?citations)
  """;
}

String Venue_Based_Prioritization(List<dynamic> interests,String publishedIn) {
  List<String> formattedInterests = [];
  for (var interest in interests) {
    // Extract text if interest is a Chip widget
    if (interest is Chip && interest.label is Text) {
      String term = (interest.label as Text).data ?? "";
      formattedInterests
          .add("<http://example.org/ontology#${term.replaceAll(' ', '_')}>");
    }
    // If it's already a string, format it directly
    else if (interest is String) {
      formattedInterests.add(
          "<http://example.org/ontology#${interest.replaceAll(' ', '_')}>");
    }
  }
  // Properly join the formatted interests
  String interestsList = formattedInterests.join(",\n    ");
  return """
    PREFIX :     <http://example.org/ontology#>
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    SELECT ?paper ?title ?date ?citations ?downloads ?link ?venue
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?author), ".*#", ""); separator=", "), "Unknown") AS ?authors)
           (COALESCE(GROUP_CONCAT(DISTINCT REPLACE(STR(?indexTerm), ".*#", ""); separator=", "), "None") AS ?indexTerms)
    WHERE {
        ?paper rdf:type :Paper ;
               :title ?title ;
               :date ?date ;
               :totalCitations ?citations ;
               :totalDownloads ?downloads ;
               :publishedIn :$publishedIn ;
               :linkAccess ?link .
        OPTIONAL { ?paper :hasAuthor ?author . }
        OPTIONAL { ?paper :hasIndexTerm ?indexTerm . }
        OPTIONAL { ?paper :publishedIn ?venue . }
        FILTER(?indexTerm IN ($interestsList))
    }
    GROUP BY ?paper ?title ?date ?citations ?downloads ?link ?venue
    ORDER BY DESC(?citations)
  """;
}














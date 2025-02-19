% Use necessary libraries
use_module(library(readutil)).
use_module(library(lists)).
use_module(library(apply)).

% Load papers from the file
load_papers(File) :-
    open(File, read, Stream),
    read_lines(Stream, Lines),
    close(Stream),
    parse_lines(Lines, _).

% Read lines from the file
read_lines(Stream, []) :-
    at_end_of_stream(Stream).

read_lines(Stream, [Line | Rest]) :-
    read_line_to_string(Stream, Line),
    read_lines(Stream, Rest).
% Parse the lines to extract papers and their IDs
parse_lines([], []).

parse_lines([Line | Rest], ParsedData) :-
    (   sub_string(Line, _, _, _, '-----------|') ->
        extract_id_and_parse([Line | Rest], ParsedData)
    ;   parse_lines(Rest, ParsedData)
    ).
% Extract the ID and parse the paper details
extract_id_and_parse([Line | RestLines],
   [paper(ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms) | Rest]) :-
    get__id([Line | RestLines], ID),  % Extract the ID from the separator line
    extract_paper(RestLines,
    paper(_, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms), RemainingLines),
    assertz(paper(ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms)),  % Assert the paper as a fact
    parse_lines(RemainingLines, Rest).  % Continue parsing the remaining lines
% Extract paper entry
extract_paper(Lines, paper(_, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms), RemainingLines) :-
    get_value('Type', Lines, Type),
    get_value('Date', Lines, Date),
    get_value('title', Lines, Title),
    get_values('Authors', Lines, Authors),  % Extract authors here
    get_value('Link Access', Lines, Link),
    get_value('Total Citations', Lines, Citations),
    get_value('Total Downloads', Lines, Downloads),
    get_value('Publiched in', Lines, PublishedIn),  % Fix spelling if necessary
    get_value('Abstract', Lines, Abstract),
    get_values('Index Terms', Lines, IndexTerms),
    extract_remaining_lines(Lines, RemainingLines).

% Extract values for a given key from the lines
get_values(Key, Lines, Values) :-
    collect_values(Lines, Key, [], Values).

% Collect values recursively until we hit a separator (or the end of the list)
collect_values([], _, Accum, Accum).  % No more lines, return accumulated values

collect_values([Line | Rest], Key, Accum, Values) :-
    (   sub_string(Line, _, _, _, '-----------|')  % Stop at the separator
    ->  reverse(Accum, Values)  % Reverse the accumulated values before returning
    ;   (   sub_string(Line, _, _, _, Key)  % If the line contains the key
        ->  split_at_first_occurrence(Line, " | ", KeyPart, ValuePart),
            trim_spaces(KeyPart, TrimmedKey),
            trim_spaces(ValuePart, TrimmedValue),
            Key == TrimmedKey,  % Ensure it matches the key
            collect_values(Rest, Key, [TrimmedValue | Accum], Values)  % Accumulate values
        ;   collect_values(Rest, Key, Accum, Values)  % Continue without change if no match
        )
    ).

% Remove empty elements from a list
remove_empty([], []).

remove_empty(['' | T], Cleaned) :-
    remove_empty(T, Cleaned).

remove_empty([H | T], [H | Cleaned]) :-
    remove_empty(T, Cleaned).

% Extract a single value
get_value(Key, Lines, Value) :-
    ( member(Line, Lines),
      trim_spaces(Line, CleanedLine),  % Clean extra spaces from the line
      split_at_first_occurrence(CleanedLine, " | ", KeyPart, ValuePart), % Split line by " | "
      trim_spaces(KeyPart, TrimmedKey),  % Trim the Key
      trim_spaces(ValuePart, TrimmedValue),  % Trim the Value
      Key == TrimmedKey,  % Check if the Key matches
      Value = TrimmedValue  % Return the trimmed Value
    -> true
    ;   Value = ''  % Default empty if missing
    ).

% Extract paper ID from a separator line
get__id([Line | _], ID) :-
    split_string(Line, "|", " ", Parts),  % Split by '|', remove extra spaces
    nth1(2, Parts, IDStr),  % Get the second part (ID)
    trim_spaces(IDStr, TrimmedID),  % Trim spaces
    atom_number(TrimmedID, ID).

% Trim spaces from a string
trim_spaces(Str, Trimmed) :-
    atom_string(Atom, Str),  % Convert string to atom to normalize spaces
    atomic_list_concat(Atoms, ' ', Atom),  % Split into atoms
    atomic_list_concat(Atoms, ' ', Trimmed).  % Rejoin with single spaces

% Helper predicate to split at the first occurrence of the separator
split_at_first_occurrence(Str, Sep, Part1, Part2) :-
    sub_string(Str, Before, _, After, Sep),
    sub_string(Str, 0, Before, _, Part1),
    sub_string(Str, _, After, 0, Part2).

% Get remaining lines after parsing one paper (keep the next separator)
extract_remaining_lines(Lines, RemainingLines) :-
    split_at_separator(Lines, RemainingLines).

% Split lines at the first occurrence of the separator (keep the separator)
split_at_separator([], []).

split_at_separator([Line | Rest], [Line | Rest]) :-
    sub_string(Line, _, _, _, '-----------|').

split_at_separator([_ | Rest], RemainingLines) :-
    split_at_separator(Rest, RemainingLines).

% Print a paper by ID in JSON format
print_paper_by_id(ID, JSON) :-
(   paper(ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms)
->  format(atom(JSON),
           '{"id": ~w, "type": "~w", "date": "~w", "title": "~w", "authors": "~w", "link": "~w", "citations": ~w, "downloads": ~w, "publishedIn": "~w", "abstract": "~w", "indexTerms": "~w"}',
           [ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms])
;   format(atom(JSON), '{"error": "Paper with ID ~w not found."}', [ID])
).

% User Profiles
user(0, ["Machine learning approaches", "Energy distribution", "ML"]).
user(1, ["Machine learning theory", "Smart grid"]).
user(2, ["Intrusion detection systems", "Machine learning approaches"]).
user(3, ["Designing software", "NLP"]).
user(4, ["Quantum Computing", "Reinforcement learning"]).
user(5, ["Big Data", "Database design and models"]).
user(6, ["Adult education", "Manufacturing"]).
user(7, ["Big Data", "Manufacturing"]).

% Define synonym relationships
synonym("ML", "Machine learning").
synonym("ML", "Machine learning approaches ").
synonym("ML", "Machine learning theory ").
synonym("Computing education", "Computing education programs").
synonym("Visualization application", "Visualization application domains").


expand_synonyms([], []).
expand_synonyms([H | T], Expanded) :-
    findall(Syn, (synonym(H, Syn) ; Syn = H), Synonyms),  % Get synonyms or keep original
    expand_synonyms(T, Rest),
    append(Synonyms, Rest, Expanded).



% ----------------------
% Logical Rules (Revised)
% ----------------------

% Fetch all papers in JSON format
fetch_all_papers(JSON) :-
    findall(PaperJSON, (paper(ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms),
        format(atom(PaperJSON),
              '{"id": ~w, "type": "~w", "date": "~w", "title": "~w", "authors": "~w", "link": "~w", "citations": ~w, "downloads": ~w, "publishedIn": "~w", "abstract": "~w", "indexTerms": "~w"}',
               [ID, Type, Date, Title, Authors, Link, Citations, Downloads, PublishedIn, Abstract, IndexTerms])
    ), PapersJSONList),
    % Concatenate JSON objects into a JSON array
    atomic_list_concat(PapersJSONList, ', ', PapersJSONString),
    format(atom(JSON), '{"papers": [~w]}', [PapersJSONString]),
    write(JSON), nl.

fetch_all_user(JSON) :-
    findall(UsersJSON, (user(ID,IndexTerms),
        format(atom(UsersJSON),
              '{"id": ~w,"indexTerms": "~w"}',
               [ID,IndexTerms])
    ), UsersJSONList),

    % Concatenate JSON objects into a JSON array
    atomic_list_concat(UsersJSONList, ', ', UsersJSONString),
    format(atom(JSON), '{"Users": [~w]}', [UsersJSONString]),
    write(JSON), nl.

recommend_papers(UserID) :-
      user(UserID, InterestStrings),
      maplist(atom_string, InterestAtoms, InterestStrings),
      findall(PaperID, (
          paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
          maplist(atom_string, KeywordAtoms, Keywords),
          intersection(InterestAtoms, KeywordAtoms, Common),
          Common \= []
      ), RecommendedPapers),

      (   RecommendedPapers = []
      ->  JSON = '{"message": "No matching papers found."}'
      ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
          atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
          format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
      ),
      write(JSON),nl.

% Rule 2: Year-Based Filter
recommend_papers_after_year(UserID, Year) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, PaperDate, _, _, _, _, _, _, _, PaperKeywords),
        extract_year(PaperDate, PaperYear),
        maplist(atom_string, PaperKeywordAtoms, PaperKeywords),
        intersection(InterestAtoms, PaperKeywordAtoms, Common),
        Common \= [],
        PaperYear = Year
    ), RecommendedPapers),
    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.

extract_year(DateString, Year) :-
    split_string(DateString, " ", "", Parts),
    last(Parts, YearString),
    number_string(Year, YearString), !.


% Rule 3: Author-Based Recommendation (Partial String Matching)
recommend_papers_by_author(UserID, Author) :-
    % Step 1: Fetch papers based on user interests (reuse recommend_papers logic)
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        Common \= []
    ), RecommendedPapers),

    % Step 2: Normalize the input author name
    string_lower(Author, NormalizedAuthor),
    string_trim(NormalizedAuthor, TrimmedAuthor),

    % Step 3: Filter the recommended papers by the specified author
    findall(PaperID, (
        member(PaperID, RecommendedPapers),  % Only consider papers from the recommended list
        paper(PaperID, _, _, _, PaperAuthors, _, _, _, _, _, _),
        member(PaperAuthor, PaperAuthors),  % Iterate through authors of the paper
        string_lower(PaperAuthor, NormalizedPaperAuthor),  % Normalize paper author name
        string_trim(NormalizedPaperAuthor, TrimmedPaperAuthor),  % Trim extra spaces
        sub_string(TrimmedPaperAuthor, _, _, _, TrimmedAuthor)  % Partial string match for author
    ), FilteredPapers),

    % Step 4: Generate JSON output
    (   FilteredPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, FilteredPapers), print_paper_by_id(ID, PaperJSON)), FilteredPapersJSONList),
        atomic_list_concat(FilteredPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.

% Rule 4: Multi-Criteria Recommendation (Author, Year, and Interests)
recommend_papers_by_multi_criteria(UserID, Author, Year) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),  % Convert user interests to atoms
    string_lower(Author, NormalizedAuthor),  % Normalize input author name (lowercase)
    string_trim(NormalizedAuthor, TrimmedAuthor),  % Trim extra spaces
    findall(PaperID, (
        paper(PaperID, _, PaperDate, _, PaperAuthors, _, _, _, _, _, Keywords),
        extract_year(PaperDate, PaperYear),
        maplist(atom_string, KeywordAtoms, Keywords),  % Convert paper keywords to atoms
        intersection(InterestAtoms, KeywordAtoms, CommonKeywords),
        CommonKeywords \= [],  % Ensure at least one common interest
        PaperYear >= Year,
        member(PaperAuthor, PaperAuthors),  % Iterate through paper authors
        string_lower(PaperAuthor, NormalizedPaperAuthor),  % Normalize paper author name (lowercase)
        string_trim(NormalizedPaperAuthor, TrimmedPaperAuthor),  % Trim extra spaces
        sub_string(TrimmedPaperAuthor, _, _, _, TrimmedAuthor)  % Partial string match
    ), RecommendedPapers),
    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.

% Remove leading and trailing spaces from a string
string_trim(String, Trimmed) :-
    string_chars(String, Chars),  % Convert string to a list of characters
    remove_leading_spaces(Chars, NoLeadingSpaces),  % Remove leading spaces
    reverse(NoLeadingSpaces, Reversed),  % Reverse to remove trailing spaces
    remove_leading_spaces(Reversed, NoTrailingSpaces),  % Remove trailing spaces (now leading after reverse)
    reverse(NoTrailingSpaces, TrimmedChars),  % Reverse back to original order
    string_chars(Trimmed, TrimmedChars).  % Convert list of characters back to a string

% Remove leading spaces from a list of characters
remove_leading_spaces([' ' | T], Result) :-
    remove_leading_spaces(T, Result).  % Recursively remove leading spaces
remove_leading_spaces(List, List).  % Base case: no leading spaces left

% Rule 5: Topic Exclusion Rule (Fixed)
recommend_papers_exclude_topics(UserID, ExcludedTopics) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        Common \= [],  % Ensure there is at least one matching interest
        \+ (   member(Topic, ExcludedTopics), member(Topic, Keywords) )  % Exclude papers containing unwanted topics
    ), RecommendedPapers),

    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON),nl.


% Rule 6: Top-N Downloadable Papers Based on Download Count
recommend_top_n_downloadable_papers(UserID, N) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(Downloads-PaperID, (
        paper(PaperID, _, _, _, _, _, Downloads, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        Common \= []
    ), DownloadPaperPairs),
    sort(0, @>=, DownloadPaperPairs, SortedDownloadPaperPairs),
    pairs_values(SortedDownloadPaperPairs, SortedPaperIDs),
    length(SortedPaperIDs, Length),
    (   Length >= N
    ->  length(TopNPaperIDs, N),
        append(TopNPaperIDs, _, SortedPaperIDs)
    ;   TopNPaperIDs = SortedPaperIDs
    ),
    (   TopNPaperIDs = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, TopNPaperIDs), print_paper_by_id(ID, PaperJSON)), TopNPapersJSONList),
        atomic_list_concat(TopNPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.

% Rule 7: Keyword Weighting Rule
recommend_papers_with_keyword_weighting(UserID, Weights) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(Score-PaperID, (
        paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        calculate_relevance_score(InterestAtoms, KeywordAtoms, Weights, Score),
        writeln(Score),  % Debugging: Print the score
        Score > 0  % Ensure the score is greater than 0
    ), ScoredPapers),
    sort(0, @>=, ScoredPapers, SortedScoredPapers),
    pairs_values(SortedScoredPapers, SortedPaperIDs),
    (   SortedPaperIDs = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, SortedPaperIDs), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.

calculate_relevance_score(InterestAtoms, KeywordAtoms, Weights, Score) :-
    format('Interest Atoms: ~w\n', [InterestAtoms]),  % Debug user interests
    format('Keyword Atoms: ~w\n', [KeywordAtoms]),  % Debug paper keywords
    format('Weights: ~w\n', [Weights]),  % Debug weights
    findall(Weight, (
        member(Interest-Weight, Weights),
        downcase_atom(Interest, LowerInterest),
        member(Keyword, KeywordAtoms),
        downcase_atom(Keyword, LowerKeyword),
        LowerInterest == LowerKeyword
    ), Scores),
    format('Scores: ~w\n', [Scores]),  % Debug scores
    sum_list(Scores, Score).

% Rule 8: Combination of Interests Rule
recommend_papers_with_combined_interests(UserID) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        length(Common, CommonLength),
        CommonLength >= 2  % Ensure at least two matching interests
    ), RecommendedPapers),
    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.
    
% Rule 9: Exclude Old Papers Rule
recommend_papers_exclude_old(UserID, ExcludeBeforeYear) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, PaperDate, _, _, _, _, _, _, _, Keywords),
        extract_year(PaperDate, PaperYear),
        PaperYear > ExcludeBeforeYear,  % Ensure the paper is not older than the specified year
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        Common \= []  % Ensure there is at least one matching interest
    ), RecommendedPapers),
    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.


% Rule 10: User Feedback Rule
% Store user feedback

% Add feedback for a paper
add_feedback(UserID, PaperID, Feedback) :-
    retractall(user_feedback(UserID, PaperID)),  % Remove existing feedback if any
    assertz(user_feedback(UserID, PaperID, Feedback)).  % Add new feedback

% Recommend papers excluding those marked as irrelevant by the user
recommend_papers_with_feedback(UserID) :-
    user(UserID, InterestStrings),
    maplist(atom_string, InterestAtoms, InterestStrings),
    findall(PaperID, (
        paper(PaperID, _, _, _, _, _, _, _, _, _, Keywords),
        maplist(atom_string, KeywordAtoms, Keywords),
        intersection(InterestAtoms, KeywordAtoms, Common),
        Common \= [],
        \+ user_feedback(UserID, PaperID, irrelevant)  % Exclude papers marked as irrelevant
    ), RecommendedPapers),
    (   RecommendedPapers = []
    ->  JSON = '{"message": "No matching papers found."}'
    ;   findall(PaperJSON, (member(ID, RecommendedPapers), print_paper_by_id(ID, PaperJSON)), RecommendedPapersJSONList),
        atomic_list_concat(RecommendedPapersJSONList, ', ', PapersJSONString),
        format(atom(JSON), '{"papers": [~w]}', [PapersJSONString])
    ),
    write(JSON), nl.





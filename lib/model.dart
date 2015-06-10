library imdb.model;

class Movie {
  // id
  String title;

  // y-value
  Map rating;

  double runningTime;

  // in minutes
  int year;
  Map<String, String> releaseDates = {};

  String budget;

  String country;
  String language;

  List<String> genres = [];
  List<String> keywords = [];

  List<String> editors = [];
  List<String> directors = [];
  List<String> producers = [];
  List<String> writers = [];

  List<String> actors = [];
  List<String> actresses = [];

  List<String> cinematographers = [];
  List<String> composers = [];
  List<String> costumeDesigners = [];
  List<String> productionCompanies = [];
  List<String> specialEffectsCompanies = [];
}
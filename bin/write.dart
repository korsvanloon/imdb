import 'dart:io';
//import 'dart:mirrors';
import '../lib/model.dart';
import '../lib/util.dart';

main(List<String> arguments) async {
  Stopwatch sw = new Stopwatch();
  sw.start();

  var movies = await getMovies();

  if(arguments.contains('norm')) {
    var normalizedMovies = norm(movies);
    writeNormalisedToFile(normalizedMovies);
  }
  else {
    writeAsFile(movies);
  }

  sw.stop();
  print('time: ${sw.elapsedMilliseconds} milliseconds');
}

writeNormalisedToFile(List<Map> movies) {
  print('writing to out/normalised_movies');
  var file = new File('out/normalised_movies2');

  file.writeAsStringSync(movies.first.keys.join('\t'));

  movies.forEach((m) => file.writeAsStringSync('\n' + m.values.join('\t'), mode:FileMode.APPEND));
}

writeAsFile(List<Movie> movies) {
  print('writing to out/movies');
  var file = new File('out/movies');

  file.writeAsStringSync('title\trating\trunningTime\tyear\treleaseDates\tbudget\tcountry\tlanguage'
  + '\tgenres\tkeywords\teditors\tdirectors\tproducers\twriters\tactors\tactresses'
  + '\tcinematographers\tcomposers\tcostumeDesigners\tproductionCompanies\tspecialEffectsCompanies');

  movies.forEach((m) => file.writeAsStringSync('\n' + toTabString(m), mode:FileMode.APPEND));
}

List<Map> norm(List<Movie> movies) {
  var genres = calcEntityValues(movies, #genres);
  var keywords = calcEntityValues(movies, #keywords);

  var editors = calcEntityValues(movies, #editors);
  var directors = calcEntityValues(movies, #directors);
  var producers = calcEntityValues(movies, #producers);
  var writers = calcEntityValues(movies, #writers);

  var actors = calcEntityValues(movies, #actors);
  var actresses = calcEntityValues(movies, #actresses);

  var cinematographers = calcEntityValues(movies, #cinematographers);
  var composers = calcEntityValues(movies, #composers);
  var costumeDesigners = calcEntityValues(movies, #costumeDesigners);
  var productionCompanies = calcEntityValues(movies, #productionCompanies);
  var specialEffectsCompanies = calcEntityValues(movies, #specialEffectsCompanies);

  return movies.map((m) => {
    'title': m.title,
    'rating': double.parse(m.rating['average']),
    'runningTime': m.runningTime,
    'year': m.year,
    'budget': m.budget,
    'country': m.country,
    'language': m.language,
    'genres': average(m.genres, genres, m.rating['average']),
    'keywords': average(m.keywords, keywords, m.rating['average']),
    'editors': average(m.editors, editors, m.rating['average']),
    'directors': average(m.directors, directors, m.rating['average']),
    'producers': average(m.producers, producers, m.rating['average']),
    'writers': average(m.writers, writers, m.rating['average']),
    'actors': average(m.actors, actors, m.rating['average']),
    'actresses': average(m.actresses, actresses, m.rating['average']),
    'cinematographers': average(m.cinematographers, cinematographers, m.rating['average']),
    'composers': average(m.composers, composers, m.rating['average']),
    'costumeDesigners': average(m.costumeDesigners, costumeDesigners, m.rating['average']),
    'productionCompanies': average(m.productionCompanies, productionCompanies, m.rating['average']),
    'specialEffectsCompanies': average(m.specialEffectsCompanies, specialEffectsCompanies, m.rating['average']),
  }).toList();
}

average(List list, Map refs, String rating) {
  if(list.length == 0) return double.parse(rating);
  return list.map((v) => refs[v]).fold(0, (v,e) => v+e) / list.length;
}
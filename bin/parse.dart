import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../lib/model.dart';
import '../lib/util.dart';

main() async {
  Stopwatch sw = new Stopwatch();
  sw.start();

  mongo.Db db = new mongo.Db('mongodb://localhost/imdb');
  await db.open();

  var persons = [
    'genres',
    'keywords',

    'editors',
    'directors',
    'producers',
    'writers',

    'actors',
    'actresses',

    'cinematographers',
    'composers',
    'costumeDesigners',
    'productionCompanies',
    'specialEffectsCompanies',
  ];


  var movies = await getMovies();
//  await saveMovies(db, movies);
  await savePersons(db, movies, persons);

  db.close();
  sw.stop();
  print('time: ${sw.elapsedMilliseconds} milliseconds');
}

savePersons(mongo.Db db, List<Movie> movies, List<String> persons) async {

  await Future.wait(persons.map((p) => db.collection(p).drop()));

  return await Future.wait(
    persons.map((p) {
      print('saving normalised $p to mongodb');
      var personValues = calcEntityValues(movies, new Symbol(p));
      return Future.wait(
        personValues.keys.map((k) => db.collection(p).insert({'name': k, 'score': personValues[k]}))
      );
    })
  );
}

saveMovies(mongo.Db db, List<Movie> movies) async {
  print('saving movies to mongodb');
  await db.collection('movie').drop();

  await Future.wait(
      movies.map(toMap).map(db.collection('movie').insert)
  );
}


Future<List<Movie>> buildMovies() async {

  var moviesMap = await buildMoviesFromRatings(new File('imdb/ratings.list'));

  print('running times');
  await simpleParse(moviesMap, new File('imdb/running-times.list'), (m, i) => m.runningTime = double.parse(i.split(':').last));

  print('budgets');
  await budgetParse(moviesMap, new File('imdb/business.list'));

  print('genres');
  await simpleParse(moviesMap, new File('imdb/genres.list'), (m, i) => m.genres.add(i));
  print('keywords');
  await simpleParse(moviesMap, new File('imdb/keywords.list'), (m, i) => m.keywords.add(i));
  print('language');
  await simpleParse(moviesMap, new File('imdb/language.list'), (m, i) => m.language = i);
  print('countries');
  await simpleParse(moviesMap, new File('imdb/countries.list'), (m, i) => m.country = i);

  print('actors');
  await personParse(moviesMap, new File('imdb/actors.list'), (m, i) => m.actors.add(i));
  print('actresses');
  await personParse(moviesMap, new File('imdb/actresses.list'), (m, i) => m.actresses.add(i));

  print('editors');
  await personParse(moviesMap, new File('imdb/editors.list'), (m, i) => m.editors.add(i));
  print('producers');
  await personParse(moviesMap, new File('imdb/producers.list'), (m, i) => m.producers.add(i));
  print('writers');
  await personParse(moviesMap, new File('imdb/writers.list'), (m, i) => m.writers.add(i));
  print('directors');
  await personParse(moviesMap, new File('imdb/directors.list'), (m, i) => m.directors.add(i));

  print('cinematographers');
  await personParse(moviesMap, new File('imdb/cinematographers.list'), (m, i) => m.cinematographers.add(i));
  print('composers');
  await personParse(moviesMap, new File('imdb/composers.list'), (m, i) => m.composers.add(i));
  print('costume designers');
  await personParse(moviesMap, new File('imdb/costume-designers.list'), (m, i) => m.costumeDesigners.add(i));

  print('special effects companies');
  await simpleParse(moviesMap, new File('imdb/special-effects-companies.list'), (m, i) => m.specialEffectsCompanies);
  print('production companies');
  await simpleParse(moviesMap, new File('imdb/production-companies.list'), (m, i) => m.productionCompanies.add(i));
  print('release date');
  await simpleParse(moviesMap, new File('imdb/release-dates.list'), (m, i) => m.releaseDates[i.split(':').first] = i.split(':').last);
  return moviesMap.values;
}

typedef void UpdateMovie(Movie m, value);

personParse(Map<String, Movie> movies, File file, UpdateMovie update) async {
  var entriesPattern = new RegExp(r'([^\t]+)');
  var updates = 0;

  var latestPerson;
  var latestMovies;

  (await file.readAsLines(encoding:LATIN1))
  .forEach((line) {
    var entriesMatch = entriesPattern.allMatches(line);

    if (entriesMatch.isEmpty) return;
    if (entriesMatch.length > 1) {

      if (latestMovies != null)
        latestMovies.forEach((t) {
          if (movies.containsKey(t)) {
            updates++;
            update(movies[t], latestPerson);
          }
        });

      latestPerson = entriesMatch.first.group(1);
      latestMovies = [entriesMatch.elementAt(1).group(1).split('  ').first];

    } else {
      var movie = entriesMatch.first.group(1).split('  ').first;
      if (movie.startsWith('"')) return;
      latestMovies.add(movie);
    }
  });
  print(updates);
}

simpleParse(Map<String, Movie> movies, File file, UpdateMovie update) async {

  var updates = 0;
  var entriesPattern = new RegExp(r'([^\t]+)');

  (await file.readAsLines(encoding:LATIN1))
  .forEach((line) {

    var entriesMatch = entriesPattern.allMatches(line);

    var title = entriesMatch.first.group(1);
    var language = entriesMatch.elementAt(1).group(1);

    if (movies.containsKey(title)) {
      updates++;
      update(movies[title], language);
    }
  });
  print(updates);
}

budgetParse(Map<String, Movie> movies, File file) async {

  var latestMovie;
  var updates = 0;

  (await file.readAsLines(encoding:LATIN1))
  .forEach((String line) {
    if (line.startsWith('MV: ') && !line.startsWith('MV: "')) {
      latestMovie = line.split('MV: ').last;
    } else if (line.startsWith('BT: ')) {
      if (movies.containsKey(latestMovie)) {
        movies[latestMovie].budget = line.split('BT: ').last;
        updates++;
      }
    }
  });
  print(updates);
}

Future<Map<String, Movie>> buildMoviesFromRatings(File file) async {
  Map<String, Movie> movies = <String, Movie>{};

  var entriesPattern = new RegExp(r' +([^ ]+) +([^ ]+) +([^ ]+) +(.+)');
  var yearPattern = new RegExp(r'\((\d+).*\)');
  var deleted = 0, parsed = 0;

  (await file.readAsLines(encoding:LATIN1))
  .forEach((line) {
    var entriesMatch = entriesPattern.firstMatch(line);

    if (entriesMatch == null) {
      return;
    }

    if (line.contains('"') || line.contains('????')) {
      deleted++;
      return;
    }
    var distribution = entriesMatch.group(1);
    var votes = int.parse(entriesMatch.group(2));
    var average = double.parse(entriesMatch.group(3));
    var title = entriesMatch.group(4);
    var year = int.parse(yearPattern.firstMatch(title).group(1));

    if (year > 1980 && votes > 1000) {
      parsed++;

      movies[title] = new Movie()
        ..title = title
        ..year = year
        ..rating = {
        'distribution': distribution,
        'votes': votes,
        'average': average,
      }
      ;
    }
    else
      deleted++;
  });
  print('parsed $parsed, deleted $deleted');
  return movies;
}

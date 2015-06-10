library imdb.util;
import 'dart:mirrors';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'model.dart';

toTabString(Object o) => toMap(o).values.reduce((v, e) => '$v\t$e');

Movie fromMapToMovie(Map o) {
  var m = new Movie();
  InstanceMirror im = reflect(m);
  im.type.declarations.values.where(
          (v) => v is VariableMirror && !v.isPrivate && !v.isStatic && !v.isConst
  ).forEach((v) {
    var fieldName = MirrorSystem.getName(v.simpleName);
    im.setField(v.simpleName, o[fieldName]);
  });
  return m;
}

Map toMap(Object o) {
  InstanceMirror im = reflect(o);
  return new Map.fromIterable(im.type.declarations.values.where(
          (v) => v is VariableMirror && !v.isPrivate && !v.isStatic && !v.isConst
  ), key:(v) => MirrorSystem.getName(v.simpleName)
  , value:(v) => im.getField(v.simpleName).reflectee
  );
}

Future<List<Movie>> getMovies() async {
  mongo.Db db = new mongo.Db('mongodb://localhost/imdb');
  await db.open();
  mongo.Cursor res = await db.collection('movie').find();
  var movies = (await res.toList()).map(fromMapToMovie).toList();
  await db.close();
  return movies;
}

Map<String, double> calcEntityValues(List<Movie> movies, Symbol s) {
  var entityValues = {};
  movies.forEach((m) {
    InstanceMirror im = reflect(m);
    im.getField(s).reflectee.forEach((c) {
      if (!entityValues.containsKey(c)) entityValues[c] = [];
      entityValues[c].add(m.rating);
    });
  });
//  var total = entityValues.keys.length;

//  var min = 99, max = -1;
//  entityValues.keys.forEach((k) {
//    var value = entityValues[k].fold(0, (p, c) => p + double.parse(c['average'])) / entityValues[k].length;
//    min = math.min(min, value);
//    max = math.max(max, value);
//    entityValues[k] = value;
//  });
  entityValues.keys.forEach((k) {
    entityValues[k] = entityValues[k].fold(0, (p, c) => p + double.parse(c['average'])) / entityValues[k].length / 10;
  });
//  entityValues.keys.forEach((k) => entityValues[k] = (entityValues[k] - min) / (max - min));
  return entityValues;
}
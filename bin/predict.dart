import 'package:mongo_dart/mongo_dart.dart' as mongo;

const double BASE_FACTOR = -2.314458, ACTORS = 4.107763, ACTRESSES = 5.232366, DIRECTORS = 1.371337, WRITERS = 2.900282;

main(List<String> arguments) async {
  // dart predict --actors=['George Clooney'] --actresses=[''] --directors=[''] --writers=['']
  var actors = [
    'Pratt, Chris (I)',
//    'Irrfan Khan',
//    'Vincent D\'Onofrio',
//    'Ty Simpkins',
//    'Nick Robinson	Nick Robinson',
//    'Jake Johnson	Jake Johnson',
//    'Omar Sy',
//    'BD Wong',
  ];
  var actresses = [
    'Howard, Bryce Dallas',
//    'Judy Greer',
//    'Lauren Lapkus	Lauren Lapkus',
  ];
  var directors = ['Colin Trevorrow'];
  var writers = [
    'Rick Jaffa',
//    'Amanda Silver',
//    'Colin Trevorrow',
//    'Derek Connolly',
//    'Rick Jaffa',
//    'Amanda Silver',
//    'Michael Crichton',
  ];

  mongo.Db db = new mongo.Db('mongodb://localhost/imdb');
  await db.open();

  var actorValue = await average(db.collection('actors'), actors);
  var actressesValue = await average(db.collection('actresses'), actresses);
  var directorsValue = await average(db.collection('directors'), directors);
  var writersValue = await average(db.collection('writers'), writers);
  print(actorValue);
  print(actressesValue);
  print(directorsValue);
  print(writersValue);

  print(predict(actorValue, actressesValue, directorsValue, writersValue));

  db.close();
}

average(mongo.DbCollection collection, values) async {
  var vs = values.map((v) {
    if(!v.contains(',')) {
      var splitted = v.split(' ');
      return splitted.last+', '+splitted.first;
    }
    return v;
  }).toList();
  print(vs);

  var items = await collection.find(mongo.where.oneFrom('name', vs)).toList();
  print(items);
  return items.fold(0, (v, e) => v + e['score']) / items.length;
}

predict(double actorValue, double actressesValue, double directorsValue, double writersValue) {
  return BASE_FACTOR + actorValue * ACTORS + actressesValue * ACTRESSES + directorsValue * DIRECTORS + writersValue * WRITERS;
}
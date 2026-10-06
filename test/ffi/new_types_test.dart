// ignore: library_annotations
@TestOn('vm')

import 'dart:typed_data';

import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:dart_duckdb/src/types/time.dart';
import 'package:test/test.dart';

void main() {
  late Database database;
  late Connection connection;

  setUp(() async {
    database = await duckdb.open(":memory:");
    connection = await duckdb.connect(database);
  });

  tearDown(() async {
    await connection.dispose();
    await database.dispose();
  });

  test('query should return BIGNUM values', () async {
    const values = [
      '0',
      '1',
      '-1',
      '255',
      '-256',
      '9223372036854775807',
      '-9223372036854775808',
      '123456789012345678901234567890123456789012345678901234567890',
      '-123456789012345678901234567890123456789012345678901234567890',
    ];
    for (final value in values) {
      final results =
          (await connection.query("SELECT '$value'::BIGNUM")).fetchAll();
      expect(results[0][0], BigInt.parse(value), reason: value);
    }
  });

  test('query should return TIME_NS value', () async {
    final results = (await connection
            .query("SELECT '12:34:56.123456789'::TIME_NS"))
        .fetchAll();

    final time = results[0][0]! as Time;
    expect(time.hour, 12);
    expect(time.minute, 34);
    expect(time.second, 56);
    expect(time.microsecond, 123456);
  });

  test('query should return GEOMETRY as WKB', () async {
    final results =
        (await connection.query("SELECT 'POINT(1 2)'::GEOMETRY")).fetchAll();

    final wkb = ByteData.sublistView(results[0][0]! as Uint8List);
    expect(wkb.lengthInBytes, 21);
    expect(wkb.getUint8(0), 1); // little endian
    expect(wkb.getUint32(1, Endian.little), 1); // point
    expect(wkb.getFloat64(5, Endian.little), 1.0);
    expect(wkb.getFloat64(13, Endian.little), 2.0);
  });

  test('prepared statement reports statement type', () async {
    await connection.execute('CREATE TABLE t (i INTEGER)');
    final cases = {
      'SELECT 1': StatementType.select,
      'INSERT INTO t VALUES (1)': StatementType.insert,
      'MERGE INTO t USING (SELECT 1 AS i) s ON t.i = s.i '
          'WHEN NOT MATCHED THEN INSERT VALUES (s.i)': StatementType.mergeInto,
    };
    for (final MapEntry(key: sql, value: type) in cases.entries) {
      final statement = await connection.prepare(sql);
      expect(statement.statementType, type, reason: sql);
      await statement.dispose();
    }
    expect(StatementType.mergeInto.isReadOnly, isFalse);
  });
}

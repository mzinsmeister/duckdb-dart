/// The kind of SQL statement, as reported by DuckDB for a prepared statement.
///
/// Mirrors DuckDB's `duckdb_statement_type` C enum. Use [isReadOnly] to decide
/// whether executing the statement can be trusted not to modify the database.
enum StatementType {
  invalid,
  select,
  insert,
  update,
  explain,
  delete,
  prepare,
  execute,
  alter,
  transaction,
  copy,
  analyze,
  variableSet,
  create,
  createFunc,
  drop,
  export,
  pragma,
  vacuum,
  call,
  set,
  load,
  relation,
  extension,
  logicalPlan,
  attach,
  detach,
  multi,
  copyDatabase,
  updateExtensions,
  mergeInto;

  /// Whether a statement of this type is safe to run in a read-only context,
  /// matching PostgreSQL's `READ ONLY` transaction semantics: it may not modify
  /// persistent database state.
  ///
  /// Everything PostgreSQL disallows in a read-only transaction is disallowed
  /// here too — `INSERT`, `UPDATE`, `DELETE`, `COPY ... FROM`, `TRUNCATE`, all
  /// `CREATE`/`ALTER`/`DROP` DDL, `GRANT`/`REVOKE`, `ATTACH`/`DETACH`,
  /// `INSTALL`/`LOAD`, `VACUUM`/`ANALYZE`, etc.
  ///
  /// Two DuckDB statement types are treated as *not* read-only even though
  /// PostgreSQL permits their read-only forms, because DuckDB's coarse
  /// statement type cannot distinguish the safe form from the unsafe one:
  ///   - `explain`: `EXPLAIN ANALYZE <stmt>` actually executes `<stmt>`, which
  ///     may be a mutation, and shares this type with plain `EXPLAIN`.
  ///   - `copy`: `COPY ... TO` writes a file (a side effect) and shares this
  ///     type with `COPY ... FROM`.
  bool get isReadOnly => switch (this) {
        StatementType.select ||
        StatementType.relation ||
        StatementType.pragma ||
        StatementType.set ||
        StatementType.variableSet =>
          true,
        _ => false,
      };
}

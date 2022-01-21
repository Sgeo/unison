-- | The Unison monorepo interface to SQLite.
--
-- This module provides a high(-er) level interface to SQLite than the @sqlite-simple@ library, which it wraps. Code
-- that interacts with SQLite in this monorepo should use this interface, rather than @sqlite-simple@ or @direct-sqlite@
-- directly.
--
-- Three variants of the main query interface are provided:
--
--   * "Unison.Sqlite.Connection" provides an interface in @IO@, which takes the 'Connection' argument as an explicit
--     argument.
--   * "Unison.Sqlite.DB" provides a type class interface, which moves the 'Connection' to an implicit argument. This
--     interface is also re-exported by this module, for convenient backwards compatibility with the existing queries.
--   * "Unison.Sqlite.Transaction" provides a newer, yet-unused interface that executes queries in transactions, with
--     automatic retries on @SQLITE_BUSY@ due to concurrent writers.
module Unison.Sqlite
  ( -- * Connection management
    Connection,
    withConnection,

    -- * Type class query interface
    DB,
    runDB,

    -- * Executing queries
    Sql (..),

    -- ** Without results

    -- *** With parameters
    execute,
    executeMany,

    -- *** Without parameters
    execute_,

    -- ** With results
    -- $query-naming-convention

    -- *** With parameters
    queryListRow,
    queryListCol,
    queryMaybeRow,
    queryMaybeCol,
    queryOneRow,
    queryOneCol,

    -- **** With checks
    queryListRowCheck,
    queryListColCheck,
    queryMaybeRowCheck,
    queryMaybeColCheck,
    queryOneRowCheck,
    queryOneColCheck,

    -- *** Without parameters
    queryListRow_,
    queryListCol_,
    queryMaybeRow_,
    queryMaybeCol_,
    queryOneRow_,
    queryOneCol_,

    -- **** With checks
    queryListRowCheck_,
    queryListColCheck_,
    queryMaybeRowCheck_,
    queryMaybeColCheck_,
    queryOneRowCheck_,
    queryOneColCheck_,

    -- * Data version
    DataVersion (..),
    getDataVersion,

    -- * Journal mode
    JournalMode (..),
    trySetJournalMode,

    -- ** Low-level
    withSavepoint,
    withStatement,

    -- * Exceptions
    SomeSqliteException (..),
    SqliteConnectException (..),
    SqliteQueryException (..),
    SqliteExceptionReason,
    SomeSqliteExceptionReason (..),
    ExpectedAtMostOneRowException (..),
    ExpectedExactlyOneRowException (..),
    SetJournalModeException (..),
  )
where

import Unison.Sqlite.Connection
  ( Connection,
    ExpectedAtMostOneRowException (..),
    ExpectedExactlyOneRowException (..),
    withConnection,
  )
import Unison.Sqlite.DB
import Unison.Sqlite.DataVersion (DataVersion (..), getDataVersion)
import Unison.Sqlite.Exception
  ( SomeSqliteException (..),
    SomeSqliteExceptionReason (..),
    SqliteConnectException (..),
    SqliteExceptionReason,
    SqliteQueryException (..),
  )
import Unison.Sqlite.JournalMode (JournalMode (..), SetJournalModeException (..), trySetJournalMode)
import Unison.Sqlite.Sql (Sql (..))

-- $query-naming-convention
--
-- Queries that return results have many different variants.
--
-- Every function name begins with the string @__query__@.
--
--   1. /Row count/. The caller may expect /exactly one/, /zero or one/, or /zero or more/ rows, in which case the
--      function name includes the string @__List__@, @__Maybe__@, or @__One__@, respectively.
--      Example: @query__List__Row@.
--
--   2. /Row width/. The caller may expect the returned rows may contain /exactly one/ or /more than one/ column, in
--      which case the function name includes the string @__Col__@ or @__Row__@, respectively.
--      Example: @queryOne__Col__@.
--
--   3. /Result checks/. The caller may want to perform additional validation on the returned rows, in which case the
--      function name includes the string @__Check__@.
--      Example: @queryMaybeCol__Check__@.
--
--   4. /Parameter count/. The query may contain /zero/ or /one or more/ parameters. In the former case, the function
--      name includes the string @__\___@.
--      Example: @queryListRow__\___@.
--
-- All together, the full anatomy of a query function is:
--
-- @
-- query(List|Maybe|One)(Row|Col)[Check][_]
-- @
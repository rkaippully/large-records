{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE LambdaCase         #-}
{-# LANGUAGE ViewPatterns       #-}

-- | Generation options for large-records.
module Data.Record.Internal.Plugin.Options (
    -- * Definition
    LargeRecordOptions(..)
  , largeRecordStrict
  , largeRecordLazy
    -- * Extract options from source module
  , getLargeRecordOptions
  ) where

import Data.Bifunctor
import Data.Data (Data)
import Data.Map (Map)
import Data.Maybe (mapMaybe)

import qualified Data.Generics   as SYB
import qualified Data.Map.Strict as Map

import Data.Record.Internal.GHC.Shim
import Data.Record.Internal.GHC.TemplateHaskellStyle

{-------------------------------------------------------------------------------
  Definition
-------------------------------------------------------------------------------}

-- | A type specifying how a record should be treated by large-records.
--
-- Examples:
--
-- > {-# ANN type T largeRecordStrict #-}
-- > data T = ..
--
-- > {-# ANN type T largeRecordLazy #-}
-- > data T = ..
data LargeRecordOptions = LargeRecordOptions {
      allFieldsStrict   :: Bool
    , hasFieldInstances :: Bool
    , debugLargeRecords :: Bool
    }
  deriving stock (Data)

largeRecordStrict :: LargeRecordOptions
largeRecordStrict = LargeRecordOptions {
      allFieldsStrict   = True
    , hasFieldInstances = True
    , debugLargeRecords = False
    }

largeRecordLazy :: LargeRecordOptions
largeRecordLazy = LargeRecordOptions {
      allFieldsStrict   = False
    , hasFieldInstances = True
    , debugLargeRecords = False
    }

{-------------------------------------------------------------------------------
  Extract options from module
-------------------------------------------------------------------------------}

-- | Extract all 'LargeRecordOptions' in a module
--
-- Additionally returns the location of the ANN pragma.
getLargeRecordOptions :: HsModule -> Map String [(SrcSpan, LargeRecordOptions)]
getLargeRecordOptions =
      Map.fromListWith (++)
    . map (second (:[]))
    . mapMaybe viewAnnotation
    . SYB.everything (++) (SYB.mkQ [] (:[]))

viewAnnotation :: AnnDecl GhcPs -> Maybe (String, (SrcSpan, LargeRecordOptions))
viewAnnotation = \case
    PragAnnD (TypeAnnotation tyName) (intOptions -> Just options) ->
      Just (nameBase tyName, (getLoc tyName, options))
    _otherwise ->
      Nothing

{-------------------------------------------------------------------------------
  Very limited interpreter for 'LargeRecordOptions'

  TODO: Instead of doing this, we might be able to use runAnnotation. This lives
  in the TcM monad, but the Hsc monad gives us a HscEnv which is sufficient to
  run things in the TcM monad. For that however we would need to use the
  /renamed/ module, rather than the parsed one. I think this might be possible
  now that quasi-quotation is no longer necessary, but I am not 100% sure.
-------------------------------------------------------------------------------}

intOptions :: LHsExpr GhcPs -> Maybe LargeRecordOptions
intOptions (VarE (nameBase -> "largeRecordStrict")) =
    Just largeRecordStrict
intOptions (VarE (nameBase -> "largeRecordLazy")) =
    Just largeRecordLazy
intOptions (RecUpdE expr fields) = do
    opts    <- intOptions expr
    updates <- mapM intUpdate fields
    return $ foldr (.) id updates opts
intOptions _otherwise =
    Nothing

intUpdate ::
     (LRdrName, LHsExpr GhcPs)
  -> Maybe (LargeRecordOptions -> LargeRecordOptions)
intUpdate (nameBase -> "debugLargeRecords", intBool -> Just b) =
    Just $ \opts -> opts { debugLargeRecords = b }
intUpdate _otherwise =
    Nothing

intBool :: LHsExpr GhcPs -> Maybe Bool
intBool (ConE (nameBase -> "True"))  = Just True
intBool (ConE (nameBase -> "False")) = Just False
intBool _otherwise                   = Nothing

{-# LANGUAGE CPP            #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE ViewPatterns   #-}

-- | Support for scalable large records
--
-- = Usage
--
-- > {-# OPTIONS_GHC -fplugin=Data.Record.Plugin #-}
-- >
-- > {-# ANN type B largeRecord #-}
-- > data B a = B {a :: a, b :: String}
-- >   deriving stock (Show, Eq, Ord)
--
-- See 'LargeRecordOptions' for the list of all possible annotations.
--
-- = Usage with @record-dot-preprocessor@
--
-- There are two important points. First, the order of plugins matters —
-- @record-dot-preprocessor@ has to be listed before this plugin (and
-- correspondingly will be applied /after/ this plugin):
--
-- > {-# OPTIONS_GHC -fplugin=RecordDotPreprocessor -fplugin=Data.Record.Plugin #-}
--
-- Second, you will want at least version 0.2.14.
module Data.Record.Plugin (plugin) where

import Control.Monad.Except
import Control.Monad.Trans.Writer.CPS
import Data.List (intersperse)
import Data.Map.Strict (Map)
import Data.Set (Set)
import Data.Traversable (for)
import Language.Haskell.TH (Extension(..))

import qualified Data.Map.Strict as Map
import qualified Data.Set        as Set

import Data.Record.Internal.Plugin.CodeGen (genLargeRecord)
import Data.Record.Internal.GHC.Fresh
import Data.Record.Internal.GHC.Shim
import Data.Record.Internal.GHC.TemplateHaskellStyle
import Data.Record.Internal.Plugin.Exception
import Data.Record.Internal.Plugin.Options
import Data.Record.Internal.Plugin.Record

#if __GLASGOW_HASKELL__ >= 902
import GHC.Driver.Errors
import GHC.Types.Error (mkWarnMsg, mkErr, mkDecorated)
import GHC.Utils.Logger (getLogger)
#endif

{-------------------------------------------------------------------------------
  Top-level: the plugin proper
-------------------------------------------------------------------------------}

plugin :: Plugin
plugin = defaultPlugin {
      parsedResultAction = aux
    , pluginRecompile    = purePlugin
    }
  where
    aux ::
         [CommandLineOption]
      -> ModSummary
      -> HsParsedModule -> Hsc HsParsedModule
    aux _opts _summary parsed@HsParsedModule{hpm_module = modl} = do
        modl' <- transformDecls modl
        pure $ parsed { hpm_module = modl' }

{-------------------------------------------------------------------------------
  Transform datatype declarations
-------------------------------------------------------------------------------}

transformDecls :: LHsModule -> Hsc LHsModule
transformDecls (L l modl@HsModule {hsmodDecls = decls, hsmodImports}) = do
    (decls', transformed) <- runWriterT $ for decls $ transformDecl largeRecords

    checkEnabledExtensions l

    -- Check for annotations without corresponding types
    let untransformed = Map.keysSet largeRecords `Set.difference` transformed
    unless (Set.null untransformed) $ do
      issueError l $ vcat $
          text "These large-record annotations were not applied:"
        : [text (" - " ++ n) | n <- Set.toList untransformed]

    -- We add imports whether or not there were some errors, to avoid spurious
    -- additional errors from ghc about things not in scope.
    pure $ L l $ modl {
        hsmodDecls   = concat decls'
      , hsmodImports = hsmodImports ++ map (uncurry importDecl) requiredImports
      }
  where
    largeRecords :: Map String [(SrcSpan, LargeRecordOptions)]
    largeRecords = getLargeRecordOptions modl

    -- Required imports along with whether or not they should be qualified
    --
    -- ANN pragmas are written by the user, and should thefore not require
    -- qualification; references to the runtime are generated by the plugin.
    requiredImports :: [(ModuleName, Bool)]
    requiredImports = [
          (mkModuleName "Data.Record.Plugin.Options", False)
        , (mkModuleName "Data.Record.Plugin.Runtime", True)
        , (mkModuleName "GHC.Generics", True)
        ]

transformDecl ::
     Map String [(SrcSpan, LargeRecordOptions)]
  -> LHsDecl GhcPs
  -> WriterT (Set String) Hsc [LHsDecl GhcPs]
transformDecl largeRecords decl@(reLoc -> L l _) =
    case decl of
      DataD (nameBase -> name) _ _ _  ->
        case Map.findWithDefault [] name largeRecords of
          [] ->
            -- Not a large record. Leave alone.
            return [decl]
          (_:_:_) -> do
            lift $ issueError l $ text ("Conflicting annotations for " ++ name)
            return [decl]
          [(annLoc, opts)] -> do
            tell (Set.singleton name)
            case runExcept (viewRecord annLoc opts decl) of
              Left e -> do
                lift $ issueError (exceptionLoc e) (exceptionToSDoc e)
                -- Return the declaration unchanged if we cannot parse it
                return [decl]
              Right r -> do
                dynFlags <- lift getDynFlags
                newDecls <- lift $ runFreshHsc $ genLargeRecord r dynFlags
                when (debugLargeRecords opts) $
                  lift $ issueWarning l (debugMsg newDecls)
                pure newDecls
      _otherwise ->
        pure [decl]
  where
    debugMsg :: [LHsDecl GhcPs] -> SDoc
    debugMsg newDecls = pprSetDepth AllTheWay $ vcat $
          text "large-records: splicing in the following definitions:"
        : map ppr newDecls

{-------------------------------------------------------------------------------
  Check for enabled extensions

  In ghc 8.10 and up there are DynFlags plugins, which we could use to enable
  these extensions for the user. Since this is not available in 8.8 however we
  will not make use of this for now. (There is also reason to believe that these
  may be removed again in later ghc releases.)
-------------------------------------------------------------------------------}

checkEnabledExtensions :: SrcSpan -> Hsc ()
checkEnabledExtensions l = do
    dynFlags <- getDynFlags
    let missing :: [RequiredExtension]
        missing = filter (not . isEnabled dynFlags) requiredExtensions
    unless (null missing) $
      -- We issue a warning here instead of an error, for better integration
      -- with HLS. Frankly, I'm not entirely sure what's going on there.
      issueWarning l $ vcat . concat $ [
          [text "Please enable these extensions for use with large-records:"]
        , map ppr missing
        ]
  where
    requiredExtensions :: [RequiredExtension]
    requiredExtensions = [
          RequiredExtension [ConstraintKinds]
        , RequiredExtension [DataKinds]
        , RequiredExtension [ExistentialQuantification, GADTs]
        , RequiredExtension [FlexibleInstances]
        , RequiredExtension [MultiParamTypeClasses]
        , RequiredExtension [ScopedTypeVariables]
        , RequiredExtension [TypeFamilies]
        , RequiredExtension [UndecidableInstances]
        ]

-- | Required extension
--
-- The list is used to represent alternative extensions that could all work
-- (e.g., @GADTs@ and @ExistentialQuantification@).
data RequiredExtension = RequiredExtension [Extension]

instance Outputable RequiredExtension where
  ppr (RequiredExtension exts) = hsep . intersperse (text "or") $ map ppr exts

isEnabled :: DynFlags -> RequiredExtension -> Bool
isEnabled dynflags (RequiredExtension exts) = any (`xopt` dynflags) exts

{-------------------------------------------------------------------------------
  Internal auxiliary
-------------------------------------------------------------------------------}

issueError :: SrcSpan -> SDoc -> Hsc ()
issueError l errMsg = do
#if __GLASGOW_HASKELL__ >= 902
    throwOneError $
      mkErr l neverQualify (mkDecorated [errMsg])
#else
    dynFlags <- getDynFlags
    throwOneError $
      mkErrMsg dynFlags l neverQualify errMsg
#endif

issueWarning :: SrcSpan -> SDoc -> Hsc ()
issueWarning l errMsg = do
    dynFlags <- getDynFlags
#if __GLASGOW_HASKELL__ >= 902
    logger <- getLogger
    liftIO $ printOrThrowWarnings logger dynFlags . listToBag . (:[]) $
      mkWarnMsg l neverQualify errMsg
#else
    liftIO $ printOrThrowWarnings dynFlags . listToBag . (:[]) $
      mkWarnMsg dynFlags l neverQualify errMsg
#endif

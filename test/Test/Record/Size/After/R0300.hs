{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE CPP                   #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE UndecidableInstances  #-}

#if PROFILE_GEN_CODE
{-# OPTIONS_GHC -fplugin=GhcDump.Plugin #-}
#endif

module Test.Record.Size.After.R0300 where

import Data.Aeson (ToJSON(..))

import Data.Record.Generic.JSON
import Data.Record.TH

import Test.Record.Size.Infra

#ifdef PROFILE_ALLZIP
import Data.Record.Generic
import Data.Record.Generic.Transform
#endif

largeRecord defaultLazyOptions (recordOfSize 300)

instance ToJSON R where
  toJSON = gtoJSON

#ifdef PROFILE_ALLZIP
testInterpretTo :: ()
testInterpretTo = aux
  where
    aux :: InterpretTo I (MetadataOf R) (MetadataOf R) => ()
    aux = ()
#endif

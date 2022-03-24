#if PROFILE_CORESIZE
{-# OPTIONS_GHC -ddump-to-file -ddump-ds-preopt -ddump-ds -ddump-simpl #-}
#endif
#if PROFILE_TIMING
{-# OPTIONS_GHC -ddump-to-file -ddump-timings #-}
#endif

{-# OPTIONS_GHC -fplugin=TypeLet #-}

module Experiment.HListLetAsCase.Sized.R050 where

import TypeLet

import Bench.HList
import Bench.Types
import Common.HListOfSize.HL050

hlist :: HList Fields
hlist =
    -- 49 .. 40
    case letAs (MkT 49 :* Nil)  of { LetAs (xs49 :: HList t49) ->
    case letAs (MkT 48 :* xs49) of { LetAs (xs48 :: HList t48) ->
    case letAs (MkT 47 :* xs48) of { LetAs (xs47 :: HList t47) ->
    case letAs (MkT 46 :* xs47) of { LetAs (xs46 :: HList t46) ->
    case letAs (MkT 45 :* xs46) of { LetAs (xs45 :: HList t45) ->
    case letAs (MkT 44 :* xs45) of { LetAs (xs44 :: HList t44) ->
    case letAs (MkT 43 :* xs44) of { LetAs (xs43 :: HList t43) ->
    case letAs (MkT 42 :* xs43) of { LetAs (xs42 :: HList t42) ->
    case letAs (MkT 41 :* xs42) of { LetAs (xs41 :: HList t41) ->
    case letAs (MkT 40 :* xs41) of { LetAs (xs40 :: HList t40) ->
    -- 39 .. 30
    case letAs (MkT 39 :* xs40) of { LetAs (xs39 :: HList t39) ->
    case letAs (MkT 38 :* xs39) of { LetAs (xs38 :: HList t38) ->
    case letAs (MkT 37 :* xs38) of { LetAs (xs37 :: HList t37) ->
    case letAs (MkT 36 :* xs37) of { LetAs (xs36 :: HList t36) ->
    case letAs (MkT 35 :* xs36) of { LetAs (xs35 :: HList t35) ->
    case letAs (MkT 34 :* xs35) of { LetAs (xs34 :: HList t34) ->
    case letAs (MkT 33 :* xs34) of { LetAs (xs33 :: HList t33) ->
    case letAs (MkT 32 :* xs33) of { LetAs (xs32 :: HList t32) ->
    case letAs (MkT 31 :* xs32) of { LetAs (xs31 :: HList t31) ->
    case letAs (MkT 30 :* xs31) of { LetAs (xs30 :: HList t30) ->
    -- 29 .. 20
    case letAs (MkT 29 :* xs30) of { LetAs (xs29 :: HList t29) ->
    case letAs (MkT 28 :* xs29) of { LetAs (xs28 :: HList t28) ->
    case letAs (MkT 27 :* xs28) of { LetAs (xs27 :: HList t27) ->
    case letAs (MkT 26 :* xs27) of { LetAs (xs26 :: HList t26) ->
    case letAs (MkT 25 :* xs26) of { LetAs (xs25 :: HList t25) ->
    case letAs (MkT 24 :* xs25) of { LetAs (xs24 :: HList t24) ->
    case letAs (MkT 23 :* xs24) of { LetAs (xs23 :: HList t23) ->
    case letAs (MkT 22 :* xs23) of { LetAs (xs22 :: HList t22) ->
    case letAs (MkT 21 :* xs22) of { LetAs (xs21 :: HList t21) ->
    case letAs (MkT 20 :* xs21) of { LetAs (xs20 :: HList t20) ->
    -- 19 .. 10
    case letAs (MkT 19 :* xs20) of { LetAs (xs19 :: HList t19) ->
    case letAs (MkT 18 :* xs19) of { LetAs (xs18 :: HList t18) ->
    case letAs (MkT 17 :* xs18) of { LetAs (xs17 :: HList t17) ->
    case letAs (MkT 16 :* xs17) of { LetAs (xs16 :: HList t16) ->
    case letAs (MkT 15 :* xs16) of { LetAs (xs15 :: HList t15) ->
    case letAs (MkT 14 :* xs15) of { LetAs (xs14 :: HList t14) ->
    case letAs (MkT 13 :* xs14) of { LetAs (xs13 :: HList t13) ->
    case letAs (MkT 12 :* xs13) of { LetAs (xs12 :: HList t12) ->
    case letAs (MkT 11 :* xs12) of { LetAs (xs11 :: HList t11) ->
    case letAs (MkT 10 :* xs11) of { LetAs (xs10 :: HList t10) ->
    -- 09 .. 00
    case letAs (MkT 09 :* xs10) of { LetAs (xs09 :: HList t09) ->
    case letAs (MkT 08 :* xs09) of { LetAs (xs08 :: HList t08) ->
    case letAs (MkT 07 :* xs08) of { LetAs (xs07 :: HList t07) ->
    case letAs (MkT 06 :* xs07) of { LetAs (xs06 :: HList t06) ->
    case letAs (MkT 05 :* xs06) of { LetAs (xs05 :: HList t05) ->
    case letAs (MkT 04 :* xs05) of { LetAs (xs04 :: HList t04) ->
    case letAs (MkT 03 :* xs04) of { LetAs (xs03 :: HList t03) ->
    case letAs (MkT 02 :* xs03) of { LetAs (xs02 :: HList t02) ->
    case letAs (MkT 01 :* xs02) of { LetAs (xs01 :: HList t01) ->
    case letAs (MkT 00 :* xs01) of { LetAs (xs00 :: HList t00) ->
      castEqual xs00
    }}}}}}}}}}
    }}}}}}}}}}
    }}}}}}}}}}
    }}}}}}}}}}
    }}}}}}}}}}

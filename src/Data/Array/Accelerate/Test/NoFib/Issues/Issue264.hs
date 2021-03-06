{-# LANGUAGE BangPatterns        #-}
{-# LANGUAGE ConstraintKinds     #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeOperators       #-}
-- |
-- Module      : Data.Array.Accelerate.Test.NoFib.Issues.Issue264
-- Copyright   : [2009..2019] The Accelerate Team
-- License     : BSD3
--
-- Maintainer  : Trevor L. McDonell <trevor.mcdonell@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)
--
-- https://github.com/AccelerateHS/accelerate/issues/264
--

module Data.Array.Accelerate.Test.NoFib.Issues.Issue264 (

  test_issue264

) where

import Prelude                                                      as P

import Data.Array.Accelerate                                        as A
import Data.Array.Accelerate.Array.Sugar                            as S
import Data.Array.Accelerate.Test.NoFib.Base
import Data.Array.Accelerate.Test.NoFib.Config
import Data.Array.Accelerate.Test.Similar

import Hedgehog
import qualified Hedgehog.Gen                                       as Gen

import Test.Tasty
import Test.Tasty.Hedgehog


test_issue264 :: RunN -> TestTree
test_issue264 runN =
  testGroup "264"
    [ testBool
    , at @TestInt8   $ testElt i8
    , at @TestInt16  $ testElt i16
    , at @TestInt32  $ testElt i32
    , at @TestInt64  $ testElt i64
    , at @TestWord8  $ testElt w8
    , at @TestWord16 $ testElt w16
    , at @TestWord32 $ testElt w32
    , at @TestWord64 $ testElt w64
    , at @TestFloat  $ testElt f32
    , at @TestDouble $ testElt f64
    ]
  where
    testElt
        :: forall a. (Similar a, P.Num a, A.Num a)
        => Gen a
        -> TestTree
    testElt e =
      testGroup (show (eltType @a))
        [ testProperty "neg.neg"        $ test_neg_neg runN e
        ]

    testBool :: TestTree
    testBool =
      testGroup "Bool"
        [ testProperty "not.not"        $ test_not_not runN
        , testProperty "not(&&)"        $ test_not_and runN
        , testProperty "not(||)"        $ test_not_or runN
        , testProperty "not(not(&&))"   $ test_not_not_and runN
        , testProperty "not(not(||))"   $ test_not_not_or runN
        ]

test_not_not
    :: RunN
    -> Property
test_not_not runN =
  property $ do
    xs <- forAll (array Z Gen.bool)
    let !go = runN (A.map A.not . A.map A.not) in go xs === mapRef (P.not . P.not) xs

test_not_and
    :: RunN
    -> Property
test_not_and runN =
  property $ do
    xs <- forAll (array Z Gen.bool)
    ys <- forAll (array Z Gen.bool)
    let !go = runN (A.zipWith (\u v -> A.not (u A.&& v))) in go xs ys === zipWithRef (\u v -> P.not (u P.&& v)) xs ys

test_not_or
    :: RunN
    -> Property
test_not_or runN =
  property $ do
    xs <- forAll (array Z Gen.bool)
    ys <- forAll (array Z Gen.bool)
    let !go = runN (A.zipWith (\u v -> A.not (u A.|| v))) in go xs ys === zipWithRef (\u v -> P.not (u P.|| v)) xs ys

test_not_not_and
    :: RunN
    -> Property
test_not_not_and runN =
  property $ do
    xs <- forAll (array Z Gen.bool)
    ys <- forAll (array Z Gen.bool)
    let !go = runN (A.zipWith (\u v -> A.not (A.not (u A.&& v)))) in go xs ys === zipWithRef (\u v -> P.not (P.not (u P.&& v))) xs ys

test_not_not_or
    :: RunN
    -> Property
test_not_not_or runN =
  property $ do
    xs <- forAll (array Z Gen.bool)
    ys <- forAll (array Z Gen.bool)
    let !go = runN (A.zipWith (\u v -> A.not (A.not (u A.|| v)))) in go xs ys === zipWithRef (\u v -> P.not (P.not (u P.|| v))) xs ys

test_neg_neg
    :: (P.Num e, A.Num e, Similar e)
    => RunN
    -> Gen e
    -> Property
test_neg_neg runN e =
  property $ do
    sh <- forAll dim1
    xs <- forAll (array sh e)
    let !go = runN (A.map negate . A.map negate) in go xs ~~~ mapRef (negate . negate) xs



mapRef :: (Shape sh, Elt a, Elt b) => (a -> b) -> Array sh a -> Array sh b
mapRef f xs = fromFunction (S.shape xs) (\ix -> f (xs S.! ix))

zipWithRef
    :: (Shape sh, Elt a, Elt b, Elt c)
    => (a -> b -> c)
    -> Array sh a
    -> Array sh b
    -> Array sh c
zipWithRef f xs ys =
  fromFunction
    (S.shape xs `S.intersect` S.shape ys)
    (\ix -> f (xs S.! ix) (ys S.! ix))


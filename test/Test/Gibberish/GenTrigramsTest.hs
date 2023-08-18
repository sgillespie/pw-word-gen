{-# LANGUAGE OverloadedLists #-}

module Test.Gibberish.GenTrigramsTest (tests) where

import Data.Gibberish.GenTrigrams
import Data.Gibberish.Types
import Test.Gibberish.Gen qualified as Gen

import Data.List qualified as List
import Data.Map (Map ())
import Data.Map qualified as Map
import Data.Text (Text ())
import Data.Text qualified as Text
import Hedgehog
import Hedgehog.Gen qualified as Gen hiding (word)
import Hedgehog.Range qualified as Range
import Test.Tasty (TestTree (), testGroup)
import Test.Tasty.Hedgehog (testPropertyNamed)

tests :: TestTree
tests =
  testGroup
    "Test.Gibberish.GenTrigrams"
    [ testPropertyNamed "length trigrams" "prop_len_trigrams" prop_len_trigrams,
      testPropertyNamed "length frequencies" "prop_len_frequencies" prop_len_frequencies,
      testPropertyNamed "contains all trigrams" "prop_trigrams_all" prop_trigrams_all
    ]

prop_len_trigrams :: Property
prop_len_trigrams = property $ do
  word <- forAll Gen.word
  let trigrams' = List.sort $ trigrams word

  cover 10 "with duplicates" $ hasDuplicates trigrams'
  cover 10 "no duplicates" $ not (hasDuplicates trigrams')

  assert $
    length (mapTrigrams [word]) <= max 0 (Text.length word - 2)

prop_len_frequencies :: Property
prop_len_frequencies = property $ do
  word <- forAll Gen.word
  let wordTrigrams' = List.sort $ trigrams word

  cover 10 "with duplicates" $ hasDuplicates wordTrigrams'
  cover 10 "no duplicates" $ not (hasDuplicates wordTrigrams')

  let totalTrigrams =
        sum
          . concatMap (Map.elems . unFrequencies)
          . Map.elems
          . mapTrigrams
          $ [word]
  length wordTrigrams' === fromIntegral totalTrigrams

prop_trigrams_all :: Property
prop_trigrams_all = property $ do
  words' <- forAll $ Gen.list (Range.linear 0 10) Gen.word
  let wordTrigrams = mapTrigrams words'
      trigrams' = map (List.sort . trigrams) words'

  cover 10 "with duplicates" $ List.any hasDuplicates trigrams'
  cover 10 "no duplicates" $ not (List.all hasDuplicates trigrams')

  concatNub trigrams' === List.sort (allTrigrams wordTrigrams)
  where
    concatNub :: Ord a => [[a]] -> [a]
    concatNub = List.nub . List.sort . List.concat

trigrams :: Text -> [(Char, Char, Char)]
trigrams ts = case Text.take 3 ts of
  [a, b, c] -> (a, b, c) : trigrams (Text.tail ts)
  _ -> []

allTrigrams :: Map Digram Frequencies -> [(Char, Char, Char)]
allTrigrams tris = concatMap (uncurry mapFrequencies) $ Map.toList tris
  where
    mapFrequencies (Digram c1 c2) (Frequencies freqs) =
      map (\(Unigram c3) -> (c1, c2, c3)) $ Map.keys freqs

hasDuplicates :: Ord a => [a] -> Bool
hasDuplicates ls = ls /= List.nub ls

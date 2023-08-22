module Main (main) where

import Data.Gibberish.GenTrigrams (mapTrigrams)

import Data.Aeson.Encode.Pretty (encodePretty)
import Data.ByteString.Lazy (ByteString ())
import Data.Text qualified as Text
import Data.Text.IO qualified as Text
import Paths_gibberish (getDataDir)
import System.FilePath
import Test.Tasty
import Test.Tasty.Golden
import Prelude hiding (writeFile)

dictsDir :: IO FilePath
dictsDir = (</> "data" </> "dicts") <$> getDataDir

trigramsDir :: IO FilePath
trigramsDir = (</> "data" </> "trigrams") <$> getDataDir

main :: IO ()
main = defaultMain =<< tests

tests :: IO TestTree
tests = testGroup "Golden Tests" <$> tests'
  where
    tests' = mapM createTest =<< findByExtension [".txt"] =<< dictsDir

createTest :: FilePath -> IO TestTree
createTest dict = do
  goldenFile <- (</> replaceExtension (takeBaseName dict) "json") <$> trigramsDir
  pure $ goldenVsString (takeBaseName dict) goldenFile (runTest dict)

runTest :: FilePath -> IO ByteString
runTest f = genTrigrams <$> Text.readFile f
  where
    genTrigrams = encodePretty . mapTrigrams . Text.lines

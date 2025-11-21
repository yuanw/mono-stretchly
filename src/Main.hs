module Main where

import System.Process (callCommand)
import Control.Concurrent (threadDelay)
import System.Directory (doesFileExist)

playSound :: IO ()
playSound = do
  let soundFile = "data/assets/sounds/done.aiff"
  exists <- doesFileExist soundFile
  if exists
    then callCommand $ "afplay " ++ soundFile
    else putStrLn "Warning: Sound file not found"

countDownSec :: Int -> IO ()
countDownSec n = do
  if n <= 0
    then playSound
    else do
      print n
      threadDelay 1000000  -- 1 second delay
      countDownSec (n - 1)

main :: IO ()
main = countDownSec 5  -- Start a 5 second countdown

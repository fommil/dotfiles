#! /usr/bin/env cabal
{- cabal:
build-depends: base, type-level-sets
-}
-- more to come https://github.com/haskell/cabal/issues/5698

-- a matching repl would be:
-- cabal new-repl -w ghc-8.4.4 --build-depends type-level-sets

{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Data.Type.Set (Set(..), Proxy(..))

class Get a s where
  get :: Set s -> a

instance {-# OVERLAPS #-} Get a (a ': s) where
  get (Ext a _) = a

instance {-# OVERLAPPABLE #-} Get a s => Get a (b ': s) where
  get (Ext _ xs) = get xs

main :: IO ()
main = do
  let lst = Ext "hello" $ Ext 10 $ Empty
  putStrLn $ show $ get @String lst

-- Local Variables:
--  haskell-compile-command: "./Main.hs"
-- End:

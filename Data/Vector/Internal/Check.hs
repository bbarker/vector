-- |
-- Module      : Data.Vector.Internal.Check
-- Copyright   : (c) Roman Leshchinskiy 2009
-- License     : BSD-style
--
-- Maintainer  : Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   : experimental
-- Portability : non-portable
--
-- Bounds checking infrastructure
--

{-# LANGUAGE MagicHash #-}

module Data.Vector.Internal.Check (
  Checks(..), doChecks,

  error, emptyStream,
  check, assert, checkIndex, checkLength, checkSlice
) where

import GHC.Base( Int(..) )
import GHC.Prim( Int# )
import Prelude hiding( error )
import qualified Prelude as P

data Checks = Bounds | Unsafe | Internal deriving( Eq )

doBoundsChecks :: Bool
#ifdef VECTOR_BOUNDS_CHECKS
doBoundsChecks = True
#else
doBoundsChecks = False
#endif

doUnsafeChecks :: Bool
#ifdef VECTOR_UNSAFE_CHECKS
doUnsafeChecks = True
#else
doUnsafeChecks = False
#endif

doInternalChecks :: Bool
#ifdef VECTOR_INTERNAL_CHECKS
doInternalChecks = True
#else
doInternalChecks = False
#endif


doChecks :: Checks -> Bool
{-# INLINE doChecks #-}
doChecks Bounds   = doBoundsChecks
doChecks Unsafe   = doUnsafeChecks
doChecks Internal = doInternalChecks

error :: String -> Int -> Checks -> String -> String -> a
error file line kind loc msg
  = P.error $ unlines $
      (if kind == Internal
         then (["*** Internal error in package vector ***"
               ,"*** Please submit a bug report at http://trac.haskell.org/vector"]++)
         else id) $
      [ file ++ ":" ++ show line ++ " (" ++ loc ++ "): " ++ msg ]

emptyStream :: String -> Int -> Checks -> String -> a
{-# NOINLINE emptyStream #-}
emptyStream file line kind loc
  = error file line kind loc "empty stream"

check :: String -> Int -> Checks -> String -> String -> Bool -> a -> a
{-# INLINE check #-}
check file line kind loc msg cond x
  | not (doChecks kind) || cond = x
  | otherwise = error file line kind loc msg

assert_msg :: String
assert_msg = "assertion failure"

assert :: String -> Int -> Checks -> String -> Bool -> a -> a
{-# INLINE assert #-}
assert file line kind loc = check file line kind loc assert_msg

checkIndex_msg :: Int -> Int -> String
{-# INLINE checkIndex_msg #-}
checkIndex_msg (I# i#) (I# n#) = checkIndex_msg# i# n#

checkIndex_msg# :: Int# -> Int# -> String
{-# NOINLINE checkIndex_msg# #-}
checkIndex_msg# i# n# = "index out of bounds " ++ show (I# i#, I# n#)

checkIndex :: String -> Int -> Checks -> String -> Int -> Int -> a -> a
{-# INLINE checkIndex #-}
checkIndex file line kind loc i n x
  = check file line kind loc (checkIndex_msg i n) (i >= 0 && i<n) x


checkLength_msg :: Int -> String
{-# INLINE checkLength_msg #-}
checkLength_msg (I# n#) = checkLength_msg# n#

checkLength_msg# :: Int# -> String
{-# NOINLINE checkLength_msg# #-}
checkLength_msg# n# = "negative length " ++ show (I# n#)

checkLength :: String -> Int -> Checks -> String -> Int -> a -> a
{-# INLINE checkLength #-}
checkLength file line kind loc n x
  = check file line kind loc (checkLength_msg n) (n >= 0) x


checkSlice_msg :: Int -> Int -> Int -> String
{-# INLINE checkSlice_msg #-}
checkSlice_msg (I# i#) (I# m#) (I# n#) = checkSlice_msg# i# m# n#

checkSlice_msg# :: Int# -> Int# -> Int# -> String
{-# NOINLINE checkSlice_msg# #-}
checkSlice_msg# i# m# n# = "invalid slice " ++ show (I# i#, I# m#, I# n#)

checkSlice :: String -> Int -> Checks -> String -> Int -> Int -> Int -> a -> a
{-# INLINE checkSlice #-}
checkSlice file line kind loc i m n x
  = check file line kind loc (checkSlice_msg i m n)
                             (i >= 0 && m >= 0 && i+m <= n) x


module Data.Gibberish.Monad.Pass
  ( Pass (),
    PassT (..),
    MonadRandom (..),
    runPass,
    evalPass,
    usingPass,
    runPassT,
    evalPassT,
    usingPassT,
  ) where

import Control.Monad.IO.Class (MonadIO ())
import Control.Monad.Random (MonadRandom (..))
import Control.Monad.Trans.Random (RandT (), evalRandT, runRandT)
import Data.Functor.Identity (Identity (..))

-- | Password/Passphrase generation monad parameterized by the type @gen@ of the generator
-- to carry
type Pass gen = PassT gen Identity

-- | Run a generation computation with the given options and initial generator
runPass :: Pass gen a -> gen -> (a, gen)
runPass action = runIdentity . runPassT action

-- | Evaluate a generation computation with the given options and initial
--   generator, discarding the final generator
evalPass :: Pass gen a -> gen -> a
evalPass action = runIdentity . evalPassT action

-- | Shorter and more readable alias for @flip runPassT@.
usingPass :: gen -> Pass gen a -> (a, gen)
usingPass = flip runPass

-- | Password/Passphrase generation transformer monad parameterized by :
--
--    * @gen@ - the generator.
--    * @m@ - the inner monad.
newtype PassT gen m a = PassT {unPass :: RandT gen m a}
  deriving newtype
    ( Applicative,
      Functor,
      Monad,
      MonadFail,
      MonadRandom,
      MonadIO
    )

-- | Run a generation computation with the given options and initial generator
runPassT :: PassT g m a -> g -> m (a, g)
runPassT = runRandT . unPass

-- | Evaluate a generation computation with the given options and initial
--   generator, discarding the final generator
evalPassT :: Monad m => PassT g m a -> g -> m a
evalPassT = evalRandT . unPass

-- | Shorter and more readable alias for @flip runPassT@.
usingPassT :: g -> PassT g m a -> m (a, g)
usingPassT = flip runPassT
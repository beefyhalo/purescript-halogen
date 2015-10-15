module Example.MultiComponent where

import Prelude

import Control.Monad.Aff (runAff)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (throwException)
import Control.Plus (Plus)

import Data.Either (Either(..), either)
import Data.Functor.Coproduct (Coproduct())
import Data.Generic (Generic, gEq, gCompare)
import Data.Maybe (Maybe(..))

import Halogen
import Halogen.Component.ChildPath (ChildPath(), cpL, cpR, (:>))
import Halogen.Util (appendToBody)
import qualified Halogen.HTML.Indexed as H
import qualified Halogen.HTML.Events.Indexed as E

import Example.ComponentA
import Example.ComponentB
import Example.ComponentC

newtype State = State { a :: Maybe Boolean, b :: Maybe Boolean, c :: Maybe Boolean }

initialState :: State
initialState = State { a: Nothing, b: Nothing, c: Nothing }

data Input a = ReadStates a

type ChildStates = Either StateA (Either StateB StateC)
type ChildInputs = Coproduct InputA (Coproduct InputB InputC)
type ChildSlots = Either SlotA (Either SlotB SlotC)

cpA :: ChildPath StateA ChildStates InputA ChildInputs SlotA ChildSlots
cpA = cpL

cpB :: ChildPath StateB ChildStates InputB ChildInputs SlotB ChildSlots
cpB = cpR :> cpL

cpC :: ChildPath StateC ChildStates InputC ChildInputs SlotC ChildSlots
cpC = cpR :> cpR

ui :: forall g. (Plus g) => ParentComponent State ChildStates Input ChildInputs g ChildSlots
ui = parentComponent' render eval (const (pure unit))
  where

  render :: RenderParent State ChildStates Input ChildInputs g ChildSlots
  render (State state) = H.div_
    [ H.div_ [ H.slot' cpA SlotA componentA \_ -> initStateA ]
    , H.div_ [ H.slot' cpB SlotB componentB \_ -> initStateB ]
    , H.div_ [ H.slot' cpC SlotC componentC \_ -> initStateC ]
    , H.div_ [ H.text $ "Current states: " ++ show state.a ++ " / " ++ show state.b ++ " / " ++ show state.c ]
    , H.button [ E.onClick (E.input_ ReadStates) ] [ H.text "Read states" ]
    ]

  eval :: EvalParent Input State ChildStates Input ChildInputs g ChildSlots
  eval (ReadStates next) = do
    a <- query' cpA SlotA (request GetStateA)
    b <- query' cpB SlotB (request GetStateB)
    c <- query' cpC SlotC (request GetStateC)
    modify (const $ State { a: a, b: b, c: c })
    pure next

main :: Eff (HalogenEffects ()) Unit
main = runAff throwException (const (pure unit)) $ do
  app <- runUI ui (installedState initialState)
  appendToBody app.node
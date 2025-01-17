module MainFrame.Lenses
  ( _webSocketStatus
  , _currentSlot
  , _tzOffset
  , _subState
  , _toast
  , _welcomeState
  , _dashboardState
  ) where

import Prologue
import Data.Lens (Lens', Traversal')
import Data.Lens.Prism.Either (_Left, _Right)
import Data.Lens.Record (prop)
import Type.Proxy (Proxy(..))
import Data.Time.Duration (Minutes)
import MainFrame.Types (State, WebSocketStatus)
import Marlowe.Semantics (Slot)
import Page.Dashboard.Types (State) as Dashboard
import Page.Welcome.Types (State) as Welcome
import Toast.Types (State) as Toast

_webSocketStatus :: Lens' State WebSocketStatus
_webSocketStatus = prop (Proxy :: _ "webSocketStatus")

_currentSlot :: Lens' State Slot
_currentSlot = prop (Proxy :: _ "currentSlot")

_tzOffset :: Lens' State Minutes
_tzOffset = prop (Proxy :: _ "tzOffset")

_subState :: Lens' State (Either Welcome.State Dashboard.State)
_subState = prop (Proxy :: _ "subState")

_toast :: Lens' State Toast.State
_toast = prop (Proxy :: _ "toast")

------------------------------------------------------------
_welcomeState :: Traversal' State Welcome.State
_welcomeState = _subState <<< _Left

_dashboardState :: Traversal' State Dashboard.State
_dashboardState = _subState <<< _Right

module Env
  ( Env
  , WebSocketManager
  ) where

import Capability.PlutusApps.MarloweApp.Types as MarloweApp
import Effect.AVar (AVar)
import Halogen (SubscriptionId)
import Plutus.PAB.Webserver (SPSettings_)
import Plutus.PAB.Webserver.Types (CombinedWSStreamToClient, CombinedWSStreamToServer)
import WebSocket.Support (WebSocketManager) as WS

-- Application enviroment configuration
type Env
  = { ajaxSettings :: SPSettings_
    -- This AVar helps to solve a concurrency problem in the contract carousel subscriptions.
    -- See notes in [Contract.State(unsubscribeFromSelectCenteredStep)]
    -- There are two reasons why this is stored in the `Env` rather than the Contract.State:
    -- 1. There are multiple Contract.State (one per each contract) but only one carousel at a time.
    --    Sharing the subscription makes sense in that regard.
    -- 2. We need to be inside the Effect/Aff monad in order to create an AVar, and most of the state
    --    creation functions didn't require that, so it seemed wrong to lift several functions into Effect.
    --    In contrast, the Env is created in Main, where we already have access to Effect
    , contractStepCarouselSubscription :: AVar SubscriptionId
    -- See note on Capability.PlutusApps.MarloweApp.Types
    , marloweAppEndpointMutex :: MarloweApp.EndpointMutex
    , wsManager :: WebSocketManager
    }

type WebSocketManager
  = WS.WebSocketManager CombinedWSStreamToClient CombinedWSStreamToServer

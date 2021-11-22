module Data.Actus.Contract.PrincipalAtMaturity where

import Data.Actus.Contract (Contract)
import Data.Actus.Types as Types
import Data.DateTime (DateTime)
import Data.Map.Heterogeneous (HMap)
import Data.Maybe (Maybe)

type PrincipalAtMaturity = Contract
  ( calendar :: Calendar
  , contractPerformance :: Types.ContractPerformance
  , fees :: Maybe Fees
  , interest :: Interest
  , notionalPrincipal :: NotionalPrincipal
  , optionality :: Maybe Optionality
  , rateReset :: Maybe RateReset
  )

type Calendar = HMap
  ( capitalizationEndDate :: Types.Calendar
  , businessDayConvention :: Types.BusinessDayConvention
  , endOfMonthConvention :: Types.EndOfMonthConvention
  )

type Fees =
  { rate :: Number
  , basis :: Types.FeeBasis
  , accrued :: Maybe Number
  , cycle :: Types.AnchoredCycle
  }

type Interest =
  { accrued :: Number
  , capitalizationEndDate :: DateTime
  , nominalRate :: Number
  , dayCountConvention :: Types.DayCountConvention
  , paymentCycle :: Maybe Types.AnchoredCycle
  }

type NotionalPrincipal =
  { initialExchangeDate :: DateTime
  , premiumDiscountAtIED :: Maybe Number
  , maturityDate :: DateTime
  , notionalPrincipal :: Number
  , purchase :: Maybe Types.ContractEndEvent
  , termination :: Maybe Types.ContractEndEvent
  , scaling ::
      Maybe
        { cycle :: Types.AnchoredCycle
        , effect :: Types.ScalingEffect
        , marketObjectCodeOfIndex :: String
        }
  }

data Optionality =
  Optionality
    Types.PrepaymentEffect
    ( HMap
        ( cycle :: Maybe Types.AnchoredCycle
        , penaltyType :: Types.PenaltyType
        , penaltyRate :: Number
        )
    )

type RateReset =
  { cycle :: Types.AnchoredCycle
  , rateSpread :: Number
  , marketObjectCode :: String
  , constraints ::
      HMap
        ( lifeCap :: Number
        , lifeFloor :: Number
        , periodCap :: Number
        , periodFloor :: Number
        )
  , nextResetRate :: Maybe Number
  , rateMultiplier :: Maybe Number
  }
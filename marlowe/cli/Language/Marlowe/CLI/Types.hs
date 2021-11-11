
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}


module Language.Marlowe.CLI.Types (
  Command(..)
, MarloweInfo(..)
, ValidatorInfo(..)
, DatumInfo(..)
, RedeemerInfo(..)
) where


import           Cardano.Api                  (AddressInEra, IsCardanoEra, Lovelace, NetworkId, SlotNo,
                                               StakeAddressReference, serialiseAddress)
import           Data.Aeson                   (ToJSON (..), Value, object, (.=))
import           Data.ByteString.Short        (ShortByteString)
import           GHC.Generics                 (Generic)
import           Language.Marlowe.CLI.Orphans ()
import           Language.Marlowe.Semantics   (MarloweData (..))
import           Ledger.Typed.Scripts         (TypedValidator)
import           Plutus.V1.Ledger.Api         (Datum, DatumHash, ExBudget, PubKeyHash, Redeemer, Script, ValidatorHash)


data MarloweInfo era =
  MarloweInfo
  {
    validatorInfo :: ValidatorInfo era
  , datumInfo     :: DatumInfo
  , redeemerInfo  :: RedeemerInfo
  }
    deriving (Eq, Generic, Show)

instance IsCardanoEra era => ToJSON (MarloweInfo era) where
  toJSON MarloweInfo{..} =
    object
      [
        "validator" .= toJSON validatorInfo
      , "datum"     .= toJSON datumInfo
      , "redeemer"  .= toJSON redeemerInfo
      ]

data ValidatorInfo era =
  ValidatorInfo
  {
    viValidator :: TypedValidator MarloweData
  , viScript    :: Script
  , viBytes     :: ShortByteString
  , viHash      :: ValidatorHash
  , viAddress   :: AddressInEra era
  , viSize      :: Int
  , viCost      :: ExBudget
  }
    deriving (Eq, Generic, Show)

instance IsCardanoEra era => ToJSON (ValidatorInfo era) where
  toJSON ValidatorInfo{..} =
    object
      [
        "address" .= serialiseAddress viAddress
      , "hash"    .= toJSON viHash
      , "cborHex" .= toJSON viBytes
      , "size"    .= toJSON viSize
      , "cost"    .= toJSON viCost
      ]


data DatumInfo =
  DatumInfo
  {
    diDatum :: Datum
  , diBytes :: ShortByteString
  , diJson  :: Value
  , diHash  :: DatumHash
  , diSize  :: Int
  }
    deriving (Eq, Generic, Show)

instance ToJSON DatumInfo where
  toJSON DatumInfo{..} =
    object
      [
        "hash"    .= toJSON diHash
      , "cborHex" .= toJSON diBytes
      , "json"    .=        diJson
      , "size"    .= toJSON diSize
      ]


data RedeemerInfo =
  RedeemerInfo
  {
    riRedeemer :: Redeemer
  , riBytes    :: ShortByteString
  , riJson     :: Value
  , riSize     :: Int
  }
    deriving (Eq, Generic, Show)

instance ToJSON RedeemerInfo where
  toJSON RedeemerInfo{..} =
    object
      [
        "cboxHex" .= toJSON riBytes
      , "json"    .=        riJson
      , "size"    .= toJSON riSize
      ]


data Command =
    Export
    {
      network         :: Maybe NetworkId
    , stake           :: Maybe StakeAddressReference
    , accountHash     :: PubKeyHash
    , accountLovelace :: Lovelace
    , minimumSlot'    :: SlotNo
    , minimumSlot     :: SlotNo
    , maximumSlot     :: SlotNo
    , outputFile      :: FilePath
    , printStats      :: Bool
    }
  | ExportAddress
    {
      network :: Maybe NetworkId
    , stake   :: Maybe StakeAddressReference
    }
  | ExportValidator
    {
      network       :: Maybe NetworkId
    , stake         :: Maybe StakeAddressReference
    , validatorFile :: FilePath
    , printAddress  :: Bool
    , printHash     :: Bool
    , printStats    :: Bool
    }
  | ExportDatum
    {
      accountHash     :: PubKeyHash
    , accountLovelace :: Lovelace
    , minimumSlot'    :: SlotNo
    , datumFile       :: FilePath
    , printHash       :: Bool
    , printStats      :: Bool
    }
  | ExportRedeemer
    {
      minimumSlot  :: SlotNo
    , maximumSlot  :: SlotNo
    , redeemerFile :: FilePath
    , printStats   :: Bool
    }
    deriving (Eq, Generic, Show)
#!/usr/bin/env bash


####
#### Example for using `marlowe-cli` to run a Marlowe three-step contract on `testnet`.
####
#### 0. The contract is initially funded with 3 ADA.
#### 1. The sole party then deposits 10 ADA.
#### 2. The contract then permits 5 ADA to be payed back to the party.
#### 3. Finally, the contract closes and the remaining 8 ADA is withdrawn.
####
#### Here is the contract in Marlowe format;
####
####     When
####         [Case
####             (Deposit
####                 (PK "0a11b0c7e25dc5d9c63171bdf39d9741b901dc903e12b4e162348e07")
####                 (PK "0a11b0c7e25dc5d9c63171bdf39d9741b901dc903e12b4e162348e07")
####                 (Token "" "")
####                 (Constant 10)
####             )
####             (Pay
####                 (PK "0a11b0c7e25dc5d9c63171bdf39d9741b901dc903e12b4e162348e07")
####                 (Account (PK "0a11b0c7e25dc5d9c63171bdf39d9741b901dc903e12b4e162348e07"))
####                 (Token "" "")
####                 (Constant 5)
####                 Close
####             )]
####         90000000 Close
####


# Select the network.

NETWORK=testnet
MAGIC=(--testnet-magic 1097911063)
export CARDANO_NODE_SOCKET_PATH=$PWD/$NETWORK.socket


# Select the wallet.

PAYMENT_SKEY=payment.skey
PAYMENT_VKEY=payment.vkey
ADDRESS_P=$(cardano-cli address build "${MAGIC[@]}" --payment-verification-key-file $PAYMENT_VKEY)
PUBKEYHASH_P=$(cardano-cli address key-hash --payment-verification-key-file $PAYMENT_VKEY)


# Find the contract address.

ADDRESS_S=$(marlowe-cli export-address "${MAGIC[@]}")
echo "$ADDRESS_S"


# Create the Plutus script for the validator.

marlowe-cli export-validator "${MAGIC[@]}"             \
                             --out-file example.plutus \
                             --print-stats


# Generate the example contract, state, and inputs files for each step.

marlowe-cli example "$PUBKEYHASH_P" --write-files > /dev/null

for i in 0 1 2
do
  marlowe-cli export-datum --contract-file example-$i.contract \
                           --state-file    example-$i.state    \
                           --out-file      example-$i.datum    \
                           --print-stats
done

for i in 0 1
do
  marlowe-cli export-redeemer --out-file example-$i.redeemer \
                              --print-stats
done
marlowe-cli export-redeemer --input-file example-2.input    \
                            --out-file   example-2.redeemer \
                            --print-stats


# 0. Find some funds, and enter the selected UTxO as "TX_0".

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_P"

TX_0=5ebf09462a66e9abb4ade3e5098bc3e21d587ce65e4d0f7b3eba0fb6af59d847#0


# Fund the contract by sending the initial funds and setting the initial state.

TX_1=$(
marlowe-cli transaction-create "${MAGIC[@]}"                             \
                               --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                               --script-address "$ADDRESS_S"             \
                               --tx-out-datum-file example-2.datum       \
                               --tx-out-value 3000000                    \
                               --tx-in "$TX_0"                           \
                               --change-address "$ADDRESS_P"             \
                               --out-file tx.raw                         \
                               --required-signer $PAYMENT_SKEY           \
                               --print-stats                             \
                               --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)
echo TxId "$TX_1"

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_S"


# 1. Deposit 10 ADA.

TX_2=$(
marlowe-cli transaction-advance "${MAGIC[@]}"                             \
                                --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                                --script-address "$ADDRESS_S"             \
                                --tx-in-script-file example.plutus        \
                                --tx-in-redeemer-file example-2.redeemer  \
                                --tx-in-datum-file example-2.datum        \
                                --required-signer $PAYMENT_SKEY           \
                                --tx-in-marlowe "$TX_1"#1                 \
                                --tx-in "$TX_1"#0                         \
                                --tx-in-collateral "$TX_1"#0              \
                                --tx-out-datum-file example-1.datum       \
                                --tx-out-value 13000000                   \
                                --tx-out "$ADDRESS_P"+50000000            \
                                --change-address "$ADDRESS_P"             \
                                --invalid-before    40000000              \
                                --invalid-hereafter 80000000              \
                                --out-file tx.raw                         \
                                --print-stats                             \
                                --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)
echo TxId "$TX_2"

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_S"


## 2. Pay 5 ADA back.

TX_3=$(
marlowe-cli transaction-advance "${MAGIC[@]}"                             \
                                --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                                --script-address "$ADDRESS_S"             \
                                --tx-in-script-file example.plutus        \
                                --tx-in-redeemer-file example-1.redeemer  \
                                --tx-in-datum-file example-1.datum        \
                                --required-signer $PAYMENT_SKEY           \
                                --tx-in-marlowe "$TX_2"#1                 \
                                --tx-in "$TX_2"#0                         \
                                --tx-in-collateral "$TX_2"#0              \
                                --tx-out-datum-file example-0.datum       \
                                --tx-out-value 8000000                    \
                                --tx-out "$ADDRESS_P"+50000000            \
                                --change-address "$ADDRESS_P"             \
                                --invalid-before    40000000              \
                                --invalid-hereafter 80000000              \
                                --out-file tx.raw                         \
                                --print-stats                             \
                                --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)
echo TxId "$TX_3"

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_S"


# 3. Withdrawn the remaining 8 ADA.

TX_4=$(
marlowe-cli transaction-close "${MAGIC[@]}"                             \
                              --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                              --tx-in-script-file example.plutus        \
                              --tx-in-redeemer-file example-0.redeemer  \
                              --tx-in-datum-file example-0.datum        \
                              --tx-in-marlowe "$TX_3"#1                 \
                              --tx-in "$TX_3"#0                         \
                              --tx-in-collateral "$TX_3"#0              \
                              --tx-out "$ADDRESS_P"+8000000             \
                              --change-address "$ADDRESS_P"             \
                              --invalid-before    40000000              \
                              --invalid-hereafter 80000000              \
                              --out-file tx.raw                         \
                              --required-signer $PAYMENT_SKEY           \
                              --print-stats                             \
                              --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)
echo TxId "$TX_4"


# See that the transaction succeeded.

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_S"

cardano-cli query utxo "${MAGIC[@]}" --address "$ADDRESS_P"
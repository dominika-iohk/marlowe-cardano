#!/usr/bin/env bash

# This script exits with an error value if the end-to-end test fails.
set -e

echo '# Example Escrow Contract: "Everything is alright"'

echo "In this example execution of [an escrow contract](ReadMe.md), the buyer does not report a problem."
echo
echo '![Flow chart for "everything is alright".](everything-is-alright.svg)'

echo "## Prerequisites"

echo "The environment variable "'`CARDANO_NODE_SOCKET_PATH`'" must be set to the path to the cardano node's socket."
echo
echo 'The following tools must be on the PATH:'
echo '* [marlowe-cli](../../ReadMe.md)'
echo '* [cardano-cli](https://github.com/input-output-hk/cardano-node/blob/master/cardano-cli/README.md)'
echo '* [jq](https://stedolan.github.io/jq/manual/)'
echo '* sed'
echo '* xargs'
echo
echo 'Signing and verification keys must be provided below for the bystander and party roles: to do this, set the environment variables `SELLER_PREFIX`, `BUYER_PREFIX`, and `PARTY_PREFIX` where they appear below.'

echo "## Preliminaries"

echo "### Select Network"

if false
then # Use the public testnet.
  MAGIC=(--testnet-magic 1097911063)
  SLOT_LENGTH=1000
  SLOT_OFFSET=1594369216000
else # Use the private testnet.
  MAGIC=(--testnet-magic 1564)
  SLOT_LENGTH=1000
  SLOT_OFFSET=1638215277000
fi

echo "### Select Parties"

echo "#### The Seller"

echo "The seller sells an item for a price."

SELLER_PREFIX="$TREASURY/francis-beaumont"
SELLER_NAME="Francis Beaumont"
SELLER_PAYMENT_SKEY="$SELLER_PREFIX".skey
SELLER_PAYMENT_VKEY="$SELLER_PREFIX".vkey
SELLER_ADDRESS=$(
  cardano-cli address build "${MAGIC[@]}"                                          \
                            --payment-verification-key-file "$SELLER_PAYMENT_VKEY" \
)
SELLER_PUBKEYHASH=$(
  cardano-cli address key-hash --payment-verification-key-file "$SELLER_PAYMENT_VKEY"
)

echo "The seller $SELLER_NAME has the address "'`'"$SELLER_ADDRESS"'`'" and public-key hash "'`'"$SELLER_PUBKEYHASH"'`'". They have the following UTxOs in their wallet:"

cardano-cli query utxo "${MAGIC[@]}" --address "$SELLER_ADDRESS"

echo "We select the UTxO with the most funds to use in executing the contract."

TX_0_SELLER=$(
cardano-cli query utxo "${MAGIC[@]}"                                   \
                       --address "$SELLER_ADDRESS"                     \
                       --out-file /dev/stdout                          \
| jq -r '. | to_entries | sort_by(- .value.value.lovelace) | .[0].key' \
)

echo "$SELLER_NAME will spend the UTxO "'`'"$TX_0_SELLER"'`.'

echo "### The Buyer"

BUYER_PREFIX="$TREASURY/thomas-kyd"
BUYER_NAME="Thomas Kyd"
BUYER_PAYMENT_SKEY="$BUYER_PREFIX".skey
BUYER_PAYMENT_VKEY="$BUYER_PREFIX".vkey
BUYER_ADDRESS=$(
  cardano-cli address build "${MAGIC[@]}"                                          \
                            --payment-verification-key-file "$BUYER_PAYMENT_VKEY" \
)
BUYER_PUBKEYHASH=$(
  cardano-cli address key-hash --payment-verification-key-file "$BUYER_PAYMENT_VKEY"
)

echo "The buyer $BUYER_NAME has the address "'`'"$BUYER_ADDRESS"'`'" and public-key hash "'`'"$BUYER_PUBKEYHASH"'`'". They have the following UTxOs in their wallet:"

cardano-cli query utxo "${MAGIC[@]}" --address "$BUYER_ADDRESS"

echo "We select the UTxO with the most funds to use in executing the contract."

TX_0_BUYER=$(
cardano-cli query utxo "${MAGIC[@]}"                                   \
                       --address "$BUYER_ADDRESS"                     \
                       --out-file /dev/stdout                          \
| jq -r '. | to_entries | sort_by(- .value.value.lovelace) | .[0].key' \
)

echo "$BUYER_NAME will spend the UTxO "'`'"$TX_0_BUYER"'`.'

echo "### The Mediator"

MEDIATOR_PREFIX="$TREASURY/christopher-marlowe"
MEDIATOR_NAME="Christopher Marlowe"
MEDIATOR_PAYMENT_SKEY="$MEDIATOR_PREFIX".skey
MEDIATOR_PAYMENT_VKEY="$MEDIATOR_PREFIX".vkey
MEDIATOR_ADDRESS=$(
  cardano-cli address build "${MAGIC[@]}"                                          \
                            --payment-verification-key-file "$MEDIATOR_PAYMENT_VKEY" \
)
MEDIATOR_PUBKEYHASH=$(
  cardano-cli address key-hash --payment-verification-key-file "$MEDIATOR_PAYMENT_VKEY"
)

echo "The mediator $MEDIATOR_NAME has the address "'`'"$MEDIATOR_ADDRESS"'`'" and public-key hash "'`'"$MEDIATOR_PUBKEYHASH"'`'". They have the following UTxOs in their wallet:"

cardano-cli query utxo "${MAGIC[@]}" --address "$MEDIATOR_ADDRESS"

echo "We select the UTxO with the most funds to use in executing the contract."

TX_0_MEDIATOR=$(
cardano-cli query utxo "${MAGIC[@]}"                                   \
                       --address "$MEDIATOR_ADDRESS"                     \
                       --out-file /dev/stdout                          \
| jq -r '. | to_entries | sort_by(- .value.value.lovelace) | .[0].key' \
)

echo "$MEDIATOR_NAME will spend the UTxO "'`'"$TX_0_MEDIATOR"'`.'

echo "### Validator Script and Address"

echo "The contract has a validator script and address. The bare size and cost of the script provide a lower bound on the resources that running it wiil require."

CONTRACT_ADDRESS=$(
marlowe-cli export-address "${MAGIC[@]}" \
            --slot-length "$SLOT_LENGTH" \
            --slot-offset "$SLOT_OFFSET" \
)
marlowe-cli export-validator "${MAGIC[@]}"                \
                             --slot-length "$SLOT_LENGTH" \
                             --slot-offset "$SLOT_OFFSET" \
                             --out-file escrow.plutus     \
                             --print-stats

echo "### Tip of the Blockchain"

TIP=$(cardano-cli query tip "${MAGIC[@]}" | jq '.slot')

echo "The tip is at slot $TIP. The current POSIX time implies that the tip of the blockchain should be slightly before slot $(($(date -u +%s) - $SLOT_OFFSET / $SLOT_LENGTH)). Tests may fail if this is not the case."

echo "## The Contract"

echo "The contract has a minimum slot and several deadlines."

MINIMUM_SLOT="$TIP"

PAYMENT_DEADLINE=$(($TIP + 1 * 24 * 3600))
COMPLAINT_DEADLINE=$(($TIP + 2 * 24 * 3600))
DISPUTE_DEADLINE=$(($TIP + 3 * 24 * 3600))
MEDIATION_DEADLINE=$(($TIP + 4 * 24 * 3600))

echo "* The current slot is $TIP."
echo "* The buyer $BUYER_NAME must pay before slot $PAYMENT_DEADLINE."
echo "* They buyer $BUYER_NAME has until slot $COMPLAINT_DEADLINE to complain."
echo "* The seller $SELLER_NAME has until slot $DISPUTE_DEADLINE to dispute a complaint."
echo "* The mediator $MEDIATOR_NAME has until slot $MEDIATION_DEADLINE to decide on a disputed complaint."

echo "The contract also involves the price of the good exchanged and a minimum-ADA value."

MINIMUM_ADA=3000000
PRICE=256000000

echo "The selling price is $PRICE lovelace."

echo "## Transaction 1. Create the Contract by Providing the Minimum ADA."

echo "We create the contract for the previously specified parameters."

marlowe-cli contract-escrow --minimum-ada "$MINIMUM_ADA"               \
                            --price "$PRICE"                           \
                            --seller "PK=$SELLER_PUBKEYHASH"           \
                            --buyer "PK=$BUYER_PUBKEYHASH"             \
                            --mediator "PK=$MEDIATOR_PUBKEYHASH"       \
                            --payment-deadline "$PAYMENT_DEADLINE"     \
                            --complaint-deadline "$COMPLAINT_DEADLINE" \
                            --dispute-deadline "$DISPUTE_DEADLINE"     \
                            --mediation-deadline "$MEDIATION_DEADLINE" \
                            --out-file tx-1.marlowe

echo 'We extract the initial state and full contract from the `.marlowe`file that contains comprehensive information.'

jq '.marloweState'    tx-1.marlowe > tx-1.state
jq '.marloweContract' tx-1.marlowe > tx-1.contract

echo "For each transaction, we construct the output datum. Here is its size and hash:"

marlowe-cli export-datum --contract-file tx-1.contract \
                         --state-file    tx-1.state    \
                         --out-file      tx-1.datum    \
                         --print-stats

echo "The mediator $MEDIATOR_NAME submits the transaction along with the minimum ADA $MINIMUM_ADA lovelace required for the contract's initial state. Submitting with the "'`--print-stats`'" switch reveals the network fee for the contract, the size of the transaction, and the execution requirements, relative to the protocol limits."

TX_1=$(
marlowe-cli transaction-create "${MAGIC[@]}"                              \
                               --socket-path "$CARDANO_NODE_SOCKET_PATH"  \
                               --tx-in "$TX_0_MEDIATOR"                   \
                               --change-address "$MEDIATOR_ADDRESS"       \
                               --required-signer "$MEDIATOR_PAYMENT_SKEY" \
                               --script-address "$CONTRACT_ADDRESS"       \
                               --tx-out-datum-file tx-1.datum             \
                               --tx-out-marlowe "$MINIMUM_ADA"            \
                               --out-file tx-1.raw                        \
                               --print-stats                              \
                               --submit=600                               \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)

echo "The contract received the minimum ADA of $MINIMUM_ADA lovelace from the mediator $MEDIATOR_NAME in the transaction "'`'"$TX_1"'`'".  Here is the UTxO at the contract address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$CONTRACT_ADDRESS" | sed -n -e "1p;2p;/$TX_1/p"

echo "Here is the UTxO at the mediator $MEDIATOR_NAME's address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$MEDIATOR_ADDRESS" | sed -n -e "1p;2p;/$TX_1/p"

echo "## Transaction 2. Buyer Deposits Funds into Seller's Account."

echo "First we compute the Marlowe input required to make the initial deposit by the buyer."

marlowe-cli input-deposit --deposit-account "PK=$SELLER_PUBKEYHASH" \
                          --deposit-party "PK=$BUYER_PUBKEYHASH"    \
                          --deposit-amount "$PRICE"                 \
                          --out-file "tx-2.input"

echo "Next we compute the transition caused by that input to the contract."

marlowe-cli compute --contract-file tx-1.contract          \
                    --state-file    tx-1.state             \
                    --input-file    tx-2.input             \
                    --out-file      tx-2.marlowe           \
                    --invalid-before "$TIP"                \
                    --invalid-hereafter "$(($TIP+4*3600))" \
                    --print-stats

echo "As in the first transaction, we compute the new state and contract."

jq '.state'    tx-2.marlowe > tx-2.state
jq '.contract' tx-2.marlowe > tx-2.contract

echo "Because this transaction spends from the script address, it also needs a redeemer:"

marlowe-cli export-redeemer --input-file tx-2.input    \
                            --out-file   tx-2.redeemer \
                            --print-stats

echo "As in the first transaction, we compute the datum and its hash:"

marlowe-cli export-datum --contract-file tx-2.contract \
                         --state-file    tx-2.state    \
                         --out-file      tx-2.datum    \
                         --print-stats

echo "The value held at the contract address must match that required by its state."

CONTRACT_VALUE_2=$(jq '.accounts | [.[][1]] | add' tx-2.state)

echo "Now the buyer $BUYER_NAME submits the transaction along with their deposit:"

TX_2=$(
marlowe-cli transaction-advance "${MAGIC[@]}"                             \
                                --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                                --script-address "$CONTRACT_ADDRESS"      \
                                --tx-in-marlowe "$TX_1"#1                 \
                                --tx-in-script-file escrow.plutus         \
                                --tx-in-datum-file tx-1.datum             \
                                --tx-in-redeemer-file tx-2.redeemer       \
                                --tx-in "$TX_0_BUYER"                     \
                                --tx-in-collateral "$TX_0_BUYER"          \
                                --required-signer "$BUYER_PAYMENT_SKEY"   \
                                --tx-out-marlowe "$CONTRACT_VALUE_2"      \
                                --tx-out-datum-file tx-2.datum            \
                                --tx-out "$BUYER_ADDRESS+$MINIMUM_ADA"    \
                                --change-address "$BUYER_ADDRESS"         \
                                --invalid-before "$TIP"                   \
                                --invalid-hereafter "$(($TIP+4*3600))"    \
                                --out-file tx-2.raw                       \
                                --print-stats                             \
                                --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)

echo "The contract received the deposit of $PRICE lovelace from $BUYER_NAME in the transaction "'`'"$TX_2"'`'". Here is the UTxO at the contract address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$CONTRACT_ADDRESS" | sed -n -e "1p;2p;/$TX_2/p"

echo "Here is the UTxO at $BUYER_NAME's address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$BUYER_ADDRESS" | sed -n -e "1p;2p;/$TX_2/p"

echo "## Transaction 3. The Buyer Reports that Everything is Alright"

echo "Funds are released to the seller and mediator, closing the contract."

echo "First we compute the input for the contract to transition forward."

marlowe-cli input-choose --choice-name "Everything is alright" \
                         --choice-party "PK=$BUYER_PUBKEYHASH" \
                         --choice-number 0                     \
                         --out-file tx-3.input

echo "As in the second transaction we compute the contract's transition, its new state, and the redeemer. Because the contract is being closed, no new datum need be computed."

marlowe-cli compute --contract-file tx-2.contract          \
                    --state-file    tx-2.state             \
                    --input-file    tx-3.input             \
                    --out-file      tx-3.marlowe           \
                    --invalid-before "$TIP"                \
                    --invalid-hereafter "$(($TIP+4*3600))" \
                    --print-stats
jq '.state'    tx-3.marlowe > tx-3.state
jq '.contract' tx-3.marlowe > tx-3.contract
marlowe-cli export-redeemer --input-file tx-3.input    \
                            --out-file   tx-3.redeemer \
                            --print-stats
marlowe-cli export-datum --contract-file tx-3.contract \
                         --state-file    tx-3.state    \
                         --out-file      tx-3.datum    \
                         --print-stats

echo "Now the buyer $BUYER_NAME can submit a transaction to release funds:"

TX_3=$(
marlowe-cli transaction-close "${MAGIC[@]}"                             \
                              --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                              --tx-in-marlowe "$TX_2"#1                 \
                              --tx-in-script-file escrow.plutus         \
                              --tx-in-datum-file tx-2.datum             \
                              --tx-in-redeemer-file tx-3.redeemer       \
                              --required-signer "$BUYER_PAYMENT_SKEY"   \
                              --tx-in "$TX_0_SELLER"                    \
                              --tx-in-collateral "$TX_0_SELLER"         \
                              --required-signer "$SELLER_PAYMENT_SKEY"  \
                              --tx-out "$SELLER_ADDRESS+$PRICE"         \
                              --change-address "$SELLER_ADDRESS"        \
                              --tx-out "$MEDIATOR_ADDRESS+$MINIMUM_ADA" \
                              --invalid-before "$TIP"                   \
                              --invalid-hereafter "$(($TIP+4*3600))"    \
                              --out-file tx-3.raw                       \
                              --print-stats                             \
                              --submit=600                              \
| sed -e 's/^TxId "\(.*\)"$/\1/'
)

echo "The closing of the contract paid $PRICE lovelace to the seller $SELLER_NAME and $MINIMUM_ADA lovelace to the mediator $MEDIATOR_NAME in the transaction "'`'"$TX_3"'`'". There is no UTxO at the contract address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$CONTRACT_ADDRESS" | sed -n -e "1p;2p;/$TX_3/p"

echo "Here is the UTxO at the seller $SELLER_NAME's address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$SELLER_ADDRESS" | sed -n -e "1p;2p;/$TX_3/p"

echo "Here is the UTxO at the buyer $BUYER_NAME's address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$BUYER_ADDRESS" | sed -n -e "1p;2p;/$TX_3/p"

echo "Here is the UTxO at the mediator $MEDIATOR_NAME's address:"

cardano-cli query utxo "${MAGIC[@]}" --address "$MEDIATOR_ADDRESS" | sed -n -e "1p;2p;/$TX_3/p"

echo "## Clean Up Wallets"

echo "It's convenient to consolidate all of the UTxOs into single ones."

cardano-cli query utxo "${MAGIC[@]}" --address "$SELLER_ADDRESS" --out-file /dev/stdout  \
| jq '. | to_entries[] | .key'                                                           \
| sed -e 's/"//g;s/^/--tx-in /'                                                          \
| xargs -n 9999 marlowe-cli transaction-simple "${MAGIC[@]}"                             \
                                               --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                                               --tx-out "$BUYER_ADDRESS+$PRICE"          \
                                               --change-address "$SELLER_ADDRESS"        \
                                               --out-file tx-4.raw                       \
                                               --required-signer "$SELLER_PAYMENT_SKEY"  \
                                               --submit=600                              \
> /dev/null
cardano-cli query utxo "${MAGIC[@]}" --address "$BUYER_ADDRESS" --out-file /dev/stdout   \
| jq '. | to_entries[] | .key'                                                           \
| sed -e 's/"//g;s/^/--tx-in /'                                                          \
| xargs -n 9999 marlowe-cli transaction-simple "${MAGIC[@]}"                             \
                                               --socket-path "$CARDANO_NODE_SOCKET_PATH" \
                                               --change-address "$BUYER_ADDRESS"         \
                                               --out-file tx-5.raw                       \
                                               --required-signer "$BUYER_PAYMENT_SKEY"   \
                                               --submit=600                              \
> /dev/null
cardano-cli query utxo "${MAGIC[@]}" --address "$MEDIATOR_ADDRESS" --out-file /dev/stdout \
| jq '. | to_entries[] | .key'                                                            \
| sed -e 's/"//g;s/^/--tx-in /'                                                           \
| xargs -n 9999 marlowe-cli transaction-simple "${MAGIC[@]}"                              \
                                               --socket-path "$CARDANO_NODE_SOCKET_PATH"  \
                                               --change-address "$MEDIATOR_ADDRESS"       \
                                               --out-file tx-6.raw                        \
                                               --required-signer "$MEDIATOR_PAYMENT_SKEY" \
                                               --submit=600                               \
> /dev/null


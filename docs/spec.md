## Coinmux Protocol Specification

The protocol makes use of two roles:

**Director** - Responsible for validating inputs and outputs, selecting participants, and publishing the final transaction.

**Participant** - Multiple participants join to mix their coins together with one output being untracable back to any one of the involved participants. Their responsibility is to post inputs and outputs to the Director, then finally posting signatures allowing their inputs to be spent on the verified transaction.

One client will act as both a Director and Participant.

## Messages

The messages below, appear in the same order as they are used in the protocol for creating a CoinJoin. Note that the status message is updated multiple times throughout the CoinJoin creation)

### CoinJoin Message
The Director announce a CoinJoin to participants.
Participants read to find a CoinJoin that matches what they are trying to do.

Message Creator: Director
```
coin_joins:
{
  version: 1
  identifier: 12345 # Random value used for inputs#verification
  message_public_key: '123...abc' # RSA 2048 PKI (PKCS1_PADDING); unique from other message_public_key
  participants: 5 # number of inputs / outputs
  amount: 200000000 # in satoshi, n^2
  participant_transaction_fee: 10000 # each participant must pay this fee (for now 0.0005 / num participants)
  inputs: "participant_read_write_key"
  message_verification: "participant_readable_key"
  outputs: "participant_read_write_key"
  transaction: "participant_readable_key"
  transaction_signatures: "participant_read_write_key"
  status: "participant_readable_key"
}
```

### Status Message

Director Updates with state information.
Participants use the status to determine where they are in the state machine.

Message Creator: Director
```
status:
{
  status: "initializing" | "waiting_for_inputs" | "waiting_for_outputs" | "waiting_for_signatures" | "failed" | "completed"
  transaction_id: null | "123...abc" # transaction id available during when completed
}
```

### Input Message

Specify the input address and change address for the CoinJoin.
We do not reveal the output address here so it is not associated to the input.
The change address is revealed, but due to the nature of CoinJoin, this is easy to guess from the block chain transaction.

Message Creator: Participants
```
inputs:
{
  message_public_key: '123...abc' # RSA 2048 PKI (PKCS1_PADDING); unique from other message_public_key; ensure uniqueness
  address: "1abc..." # ensure uniqueness
  change_address: "1abc" # Null if no change
  change_transaction_output_identifier: 67890 # A unique identifier to ensure my change output exists in the transaction
  verification: "123...abc" # Signature with (private_key, coin_joins#identifier) to show ownership of address
}
```

### Message Verification Message

Director creates after input list has enough valid inputs for mixing.
Only accepted inputs are given message verification and allowed to continue this CoinJoin.
A single ```message_identifier``` for all Participants is encrypted by a shared key to ensure that Director cannot link inputs to outputs by giving each input a different identifier. This shared key is encrypted uniquely for each input using its ```inputs#message_public_key```.

Message Creator: Director
```
message_verification:
{
  encrypted_message_identifier: '123...abc' # a pseudo-random value encrypted with AES-256-CBC and a secret key
  encrypted_secret_keys: {
    'inputs#addess': '123...abc', # secret key for #encrypted_message_identifier encrypted PKI for each inputs#message_public_key that will be in transaction
    ...
  }
}
```

### Output Message

Participants post each of their output addresses here.
This scheme maintains no link between the inputs and the outputs and ensures that we only add outputs owned by an input.

```message_verification``` is created by the following:

1. Decrypt my ```message_verification#encrypted_secret_keys``` for my ```inputs#address``` using private key of ```inputs#message_public_key``` to get secret key for ```message_verification#encrypted_message_identifier```.
2. Decrypt ```message_verification#encrypted_message_identifier``` with secret key to get ```message_verification#message_identifier``` used for ```outputs#message_verification```.
3. ```outputs#message_verifcation``` is the SHA256 Hash of (```output:${message_verification#message_identifier}:${outputs#address}```) to show knowledge of ```message_verification#message_identifier```.

Note: it is possible for a participant to create multiple Outputs with different addresses and the outputs will have a valid ```message_verification``` since all Participants share the same ```message_identifier```. This will cause the Director to create a transaction that not all Participants will sign since the Participant will not see his output address in the proposed transaction.

Message Creator: Participants
```
outputs:
{
  address: "1abc..."
  message_verification: '123...abc'
  transaction_output_identifier: 12345 # A unique identifier to ensure my output exists in the transaction when multiple outputs going to the same address (https://bitcointalk.org/index.php?topic=279249.msg4577566#msg4577566)
}
```

### Transaction Message

Director publishes a transaction that meets the CoinJoin criteria (correct number of inputs and verified outputs) using the Participants specified inputs and outputs.
Participant only creates ```transaction_signatures``` when has correct number of inputs/outputs and correctly contains all of his inputs and outputs

Message Creator: Director
```
transaction:
{
  inputs: [
    {
      address: "1abc..." # input addresses
      transaction_id: "123...abc"
      output_index: 0
    },
    {
      address: "1abc..." # input addresses
      transaction_id: "789...xyz"
      output_index: 3
    },
    ...
  ]
  outputs: [
    {
      address: "1abc..." # coin join addresses
      amount: 200000000
      identifier: 12345
    },
    {
      address: "1xyz..." # change addresses
      amount: 2345
      identifier: 67890
    },
    ...
  ]
}
```

### Transaction Signature Message

Participants create a transaction from the Director specified information and add transaction signatures for each input that belong to them.

The transaction must be created with all inputs and outputs specified by the Director's transaction message with all inputs and outputs occurring in the correct order.
Upon publication of all transaction signature messages, the Director creates a transaction, signs each of the inputs and then publish to the Bitcoin Network. The status message will be updated with the transaction identifier.

```transaction_signatures#message_verifcation``` is the SHA256 Hash of (```transaction_signature:${message_verification#message_identifier}:${transaction_signatures#transaction_input_index}:${transaction_signatures#script_sig}```) to show knowledge of ```message_verification#message_identifier```.

Message Creator: Participants
```
transaction_signatures:
{
  transaction_input_index: 0
  script_sig: '304604e3...==' # Base64 encoded
  message_verification: '123...abc'
}
```

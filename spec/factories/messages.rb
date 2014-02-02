FactoryGirl.define do
  factory :association_message, :class => Coinmux::Message::Association do
    sequence(:name) { |n| "association-#{n}" }
    type :list
    read_only false
    data_store_identifier_from_build { Helper.data_store.generate_identifier }
    data_store_identifier do
      if read_only
        data_store.convert_to_request_only_identifier(data_store_identifier_from_build)
      else
        data_store_identifier_from_build
      end
    end
    data_store { Helper.data_store }
  end

  factory :coin_join_message, :class => Coinmux::Message::CoinJoin do
    ignore do
      template_message { Coinmux::Message::CoinJoin.build(Helper.data_store) }
    end

    version { template_message.version }
    identifier { template_message.identifier }
    message_private_key { template_message.message_private_key }
    message_public_key { template_message.message_public_key }
    amount { 100_000_000 }
    participants { 2 }
    participant_transaction_fee { template_message.participant_transaction_fee }
    data_store { Helper.data_store }

    inputs { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'input', type: :list, read_only: false, created_with_build: true }
    outputs { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'output', type: :list, read_only: false, created_with_build: true }
    message_verification { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'message_verification', type: :fixed, read_only: true, created_with_build: true }
    transaction { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'transaction', type: :fixed, read_only: true, created_with_build: true }
    transaction_signatures { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'transaction_signature', type: :list, read_only: false, created_with_build: true }
    status { association :association_message, strategy: :build, data_store: Helper.data_store, name: 'status', type: :variable, read_only: true, created_with_build: true }

    #
    # NOTE: traits ordering is important and should probably be loaded in the order defined below
    #

    trait :with_inputs do
      after(:build) do |coin_join|
        [true, false].each do |created_with_build|
          bitcoin_info = Helper.next_bitcoin_info
          message_keys = pki_facade.generate_keypair

          coin_join.inputs.insert(FactoryGirl.build(:input_message,
            address: bitcoin_info[:address],
            private_key: bitcoin_info[:private_key],
            signature: bitcoin_crypto_facade.sign_message!(coin_join.identifier, bitcoin_info[:private_key]),
            change_address: Helper.next_bitcoin_info[:address],
            change_transaction_output_identifier: rand.to_s,
            message_private_key: message_keys.first,
            message_public_key: message_keys.last,
            created_with_build: created_with_build,
            coin_join: coin_join))
        end
      end
    end

    trait :with_message_verification do
      after(:build) do |coin_join|
        coin_join.message_verification.insert(FactoryGirl.build(:message_verification_message, :coin_join => coin_join, :created_with_build => true))
      end
    end

    trait :with_outputs do
      after(:build) do |coin_join|
        coin_join.outputs.insert(FactoryGirl.build(:output_message, :coin_join => coin_join, :created_with_build => true))
        coin_join.outputs.insert(FactoryGirl.build(:output_message, :coin_join => coin_join, :created_with_build => false))
      end
    end

    trait :with_transaction do
      after(:build) do |coin_join|
        inputs = coin_join.inputs.value.collect do |input|
          { 'address' => input.address, 'transaction_id' => "tx-#{input.address}", 'output_index' => 123 }
        end

        outputs = coin_join.outputs.value.each_with_index.collect do |output|
          { 'address' => output.address, 'amount' => coin_join.amount, 'identifier' => output.transaction_output_identifier }
        end

        outputs += coin_join.inputs.value.each_with_index.collect do |input|
          { 'address' => input.change_address, 'amount' => rand(1..4) * Coinmux::BitcoinUtil::SATOSHIS_PER_BITCOIN - coin_join.participant_transaction_fee, 'identifier' => input.change_transaction_output_identifier }
        end

        coin_join.transaction.insert(FactoryGirl.build(:transaction_message, :coin_join => coin_join, :inputs => inputs, :outputs => outputs))
      end
    end

    trait :with_transaction_signatures do
      after(:build) do |coin_join|
        coin_join.transaction.value.inputs.each_with_index do |input_hash, index|
          script_sig = "scriptsig-#{index}"

          message_verification = coin_join.build_message_verification(:transaction_signature, index, script_sig)

          coin_join.transaction_signatures.insert(FactoryGirl.build(:transaction_signature_message, coin_join: coin_join, transaction_input_index: index, script_sig: Base64.encode64(script_sig), message_verification: message_verification))
        end
      end
    end
  end

  factory :input_message, :class => Coinmux::Message::Input do
    ignore do
      template_message { FactoryGirl.build(:coin_join_message, :with_inputs).inputs.value.detect(&:created_with_build) }
    end

    address { template_message.address }
    private_key { template_message.private_key }
    signature { template_message.signature }
    change_address { template_message.change_address }
    change_transaction_output_identifier { template_message.change_transaction_output_identifier }
    message_private_key { template_message.message_private_key }
    message_public_key { template_message.message_public_key }
    coin_join { template_message.coin_join }
  end

  factory :output_message, :class => Coinmux::Message::Output do
    ignore do
      bitcoin_info { Helper.next_bitcoin_info }
    end

    address { bitcoin_info[:address] }
    transaction_output_identifier { rand.to_s }
    coin_join { association :coin_join_message, strategy: :build, identifier: bitcoin_info[:identifier] }

    after(:build) do |output|
      output.message_verification = output.build_message_verification
    end
  end

  factory :status_message, :class => Coinmux::Message::Status do
    state "completed"
    transaction_id { "valid_transaction_id:#{rand}" }

    association :coin_join, factory: :coin_join_message, strategy: :build
  end

  factory :message_verification_message, :class => Coinmux::Message::MessageVerification do
    ignore do
      template_message { Coinmux::Message::MessageVerification.build(Coinmux::Message::CoinJoin.build(Helper.data_store)) }
    end

    message_identifier { template_message.message_identifier }
    secret_key { template_message.secret_key }
    encrypted_message_identifier { template_message.encrypted_message_identifier }

    coin_join { association :coin_join_message, :with_inputs, strategy: :build }

    after(:build) do |message_verification|
      message_verification.encrypted_secret_keys = message_verification.build_encrypted_secret_keys
    end
  end

  factory :transaction_message, :class => Coinmux::Message::Transaction do
    ignore do
      template_message { FactoryGirl.build(:coin_join_message, :with_inputs, :with_message_verification, :with_outputs, :with_transaction).transaction.value }
    end

    inputs { template_message.inputs }
    outputs { template_message.outputs }
    coin_join { template_message.coin_join }
  end

  factory :transaction_signature_message, :class => Coinmux::Message::TransactionSignature do
    ignore do
      template_message { FactoryGirl.build(:coin_join_message, :with_inputs, :with_message_verification, :with_outputs, :with_transaction, :with_transaction_signatures).transaction_signatures.value.first }
    end

    transaction_input_index { template_message.transaction_input_index }
    script_sig { template_message.script_sig }
    message_verification { template_message.message_verification }
    coin_join { template_message.coin_join }
  end
end



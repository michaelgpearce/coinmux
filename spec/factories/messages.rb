FactoryGirl.define do
  factory :association_message, :class => Coin2Coin::Message::Association do
    sequence(:name) { |n| "association-#{n}" }
    type :list
    read_only false
    data_store_identifier_from_build { Coin2Coin::DataStore.instance.generate_identifier }
    data_store_identifier do
      if read_only
        Coin2Coin::DataStore.instance.convert_to_request_only_identifier(data_store_identifier_from_build)
      else
        data_store_identifier_from_build
      end
    end
  end

  factory :coin_join_message, :class => Coin2Coin::Message::CoinJoin do
    ignore do
      template_message { Coin2Coin::Message::CoinJoin.build }
    end

    version { template_message.version }
    identifier { template_message.identifier }
    message_private_key { template_message.message_private_key }
    message_public_key { template_message.message_public_key }
    amount { template_message.amount }
    participants { template_message.participants }
    participant_transaction_fee { template_message.participant_transaction_fee }

    inputs { association :association_message, strategy: :build, name: 'input', type: :list, read_only: false, created_with_build: true }
    outputs { association :association_message, strategy: :build, name: 'output', type: :list, read_only: false, created_with_build: true }
    message_verification { association :association_message, strategy: :build, name: 'message_verification', type: :fixed, read_only: true, created_with_build: true }
    transaction { association :association_message, strategy: :build, name: 'transaction', type: :fixed, read_only: true, created_with_build: true }
    transaction_signatures { association :association_message, strategy: :build, name: 'transaction_signature', type: :list, read_only: false, created_with_build: true }
    status { association :association_message, strategy: :build, name: 'status', type: :variable, read_only: true, created_with_build: true }

    #
    # NOTE: traits ordering is important and should probably be loaded in the order defined below
    #

    trait :with_inputs do
      after(:build) do |coin_join|
        coin_join.inputs.insert(FactoryGirl.build(:input_message, :coin_join => coin_join, :created_with_build => true))
        coin_join.inputs.insert(FactoryGirl.build(:input_message, :coin_join => coin_join, :created_with_build => false))
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
  end

  factory :input_message, :class => Coin2Coin::Message::Input do
    ignore do
      bitcoin_info { Helper.next_bitcoin_info }
      message_keys { Coin2Coin::PKI.instance.generate_keypair }
    end

    address { bitcoin_info[:address] }
    private_key { bitcoin_info[:private_key] }
    signature { bitcoin_info[:signature] }
    change_address { Helper.next_bitcoin_info[:address] }
    message_private_key { message_keys.first }
    message_public_key { message_keys.last }

    coin_join { association :coin_join_message, strategy: :build, identifier: bitcoin_info[:identifier] }
  end

  factory :output_message, :class => Coin2Coin::Message::Output do
    ignore do
      bitcoin_info { Helper.next_bitcoin_info }
    end

    address { bitcoin_info[:address] }

    coin_join { association :coin_join_message, strategy: :build, identifier: bitcoin_info[:identifier] }

    after(:build) do |output|
      output.message_verification = output.build_message_verification
    end
  end

  factory :status_message, :class => Coin2Coin::Message::Status do
    ignore do
      current_block_height_and_nonce { Coin2Coin::BitcoinNetwork.instance.current_block_height_and_nonce }
    end

    status "Complete"
    transaction_id { "valid_transaction_id:#{rand}" }
    updated_at { { 'block_height' => current_block_height_and_nonce.first, 'nonce' => current_block_height_and_nonce.last } }

    association :coin_join, factory: :coin_join_message, strategy: :build
  end

  factory :message_verification_message, :class => Coin2Coin::Message::MessageVerification do
    ignore do
      template_message { Coin2Coin::Message::MessageVerification.build(Coin2Coin::Message::CoinJoin.build) }
    end

    message_identifier { template_message.message_identifier }
    secret_key { template_message.secret_key }
    encrypted_message_identifier { template_message.encrypted_message_identifier }

    coin_join { association :coin_join_message, :with_inputs, strategy: :build }

    after(:build) do |message_verification|
      message_verification.encrypted_secret_keys = message_verification.build_encrypted_secret_keys
    end
  end

  factory :transaction_message, :class => Coin2Coin::Message::Transaction do
    coin_join { association :coin_join_message }
  end

  factory :transaction_signature_message, :class => Coin2Coin::Message::TransactionSignature do
    coin_join { association :coin_join_message }
  end
end



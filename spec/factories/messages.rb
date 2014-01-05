FactoryGirl.define do
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

    after(:build) do |coin_join|
      coin_join.inputs = Coin2Coin::Message::Association.build(coin_join, 'input', :list, false)
      coin_join.outputs = Coin2Coin::Message::Association.build(coin_join, 'output', :list, false)
      coin_join.message_verification = Coin2Coin::Message::Association.build(coin_join, 'message_verification', :fixed, true)
      coin_join.transaction = Coin2Coin::Message::Association.build(coin_join, 'transaction', :fixed, true)
      coin_join.transaction_signatures = Coin2Coin::Message::Association.build(coin_join, 'transaction_signature', :list, false)
      coin_join.status = Coin2Coin::Message::Association.build(coin_join, 'status', :variable, true)
    end

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
    updated_at { { :block_height => current_block_height_and_nonce.first, :nonce => current_block_height_and_nonce.last } }

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
end



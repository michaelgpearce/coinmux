FactoryGirl.define do
  factory :coin_join_message, :class => Coin2Coin::Message::CoinJoin do
    ignore do
      message_keys { Coin2Coin::PKI.instance.generate_keypair }
    end

    version Coin2Coin::Message::CoinJoin::VERSION
    identifier { Coin2Coin::Digest.instance.random_identifier }
    message_private_key { message_keys.first }
    message_public_key { message_keys.last }
    amount Coin2Coin::Message::CoinJoin::SATOSHIS_PER_BITCOIN
    minimum_participants 5

    after(:build) do |coin_join|
      coin_join.inputs = Coin2Coin::Message::Association.build(coin_join, 'input', :list, false)
      coin_join.outputs = Coin2Coin::Message::Association.build(coin_join, 'output', :list, false)
      coin_join.message_verification = Coin2Coin::Message::Association.build(coin_join, 'message_verification', :fixed, true)
      coin_join.transaction = Coin2Coin::Message::Association.build(coin_join, 'transaction', :fixed, true)
      coin_join.transaction_signatures = Coin2Coin::Message::Association.build(coin_join, 'transaction_signature', :list, false)
      coin_join.status = Coin2Coin::Message::Association.build(coin_join, 'status', :variable, true)
    end
  end

  factory :coin_join_message_with_inputs, :parent => :coin_join_message do
    after(:build) do |coin_join|
      coin_join.inputs.insert(FactoryGirl.build(:input_message, :coin_join => coin_join))
      coin_join.inputs.insert(FactoryGirl.build(:input_message, :coin_join => coin_join))
    end
  end

  factory :input_message, :class => Coin2Coin::Message::Input do
    ignore do
      sequence(:bitcoin_info) { |n| Helpers.create_bitcoin_info(n - 1) }
      message_keys { Coin2Coin::PKI.instance.generate_keypair }
    end

    address { bitcoin_info[:address] }
    private_key { bitcoin_info[:private_key] }
    public_key { bitcoin_info[:public_key] }
    signature { bitcoin_info[:signature] }
    change_address "mi4J2qXAVTwonMhaWGX63eKnjZcFM9Gy8Q"
    change_amount 100000
    message_private_key { message_keys.first }
    message_public_key { message_keys.last }

    coin_join { association :coin_join_message, strategy: :build, identifier: bitcoin_info[:identifier] }
  end

  factory :status_message, :class => Coin2Coin::Message::Status do
    ignore do
      current_block_height_and_nonce { Coin2Coin::Bitcoin.instance.current_block_height_and_nonce }
    end

    status "Complete"
    transaction_id { "valid_transaction_id:#{rand}" }
    updated_at { { :block_height => current_block_height_and_nonce.first, :nonce => current_block_height_and_nonce.last } }

    association :coin_join, factory: :coin_join_message, strategy: :build
  end

  factory :message_verification_message, :class => Coin2Coin::Message::MessageVerification do
    message_identifier { Coin2Coin::Digest.instance.random_identifier }
    secret_key { Coin2Coin::Digest.instance.random_identifier }
    encrypted_message_identifier { Coin2Coin::Cipher.instance.encrypt(secret_key, message_identifier) }

    coin_join { association :coin_join_message_with_inputs, strategy: :build }

    after(:build) do |message_verification|
      message_verification.encrypted_secret_keys = message_verification.build_encrypted_secret_keys
    end
  end
end



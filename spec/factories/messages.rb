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

    input_list { Coin2Coin::Message::Association.new(false) }
    inputs { [] }
    output_list { Coin2Coin::Message::Association.new(false) }
    outputs { [] }
    message_verification_fixed { Coin2Coin::Message::Association.new(true) }
    transaction_fixed { Coin2Coin::Message::Association.new(true) }
    status_variable { Coin2Coin::Message::Association.new(true) }
  end

  factory :input_message, :class => Coin2Coin::Message::Input do
    ignore do
      input_identifier "this is a message"
      message_keys { Coin2Coin::PKI.instance.generate_keypair }
    end

    address "mh9nRF1ZSqLJB3hbUjPLmfDHdnGUURdYdK"
    private_key "585C660C887913E5F40B8E34D99C62766443F9D043B1DE1DFDCC94E386BC6DF6"
    public_key "04FD30E98AF97627082F169B524E4646D31F900C9CAB13743140567C0CAE4B3F303AE48426DD157AEA58DCC239BB8FB19193FB856C312592D8296B02C0EA54E03C"
    signature "HIZQbBLAGJLhSZ310FCQMAo9l1X2ysxyt0kXkf6KcBN3znl2iClC6V9wz9Nkn6mMDUaq4kRlgYQDUUlsm29Bl0o="
    change_address "mi4J2qXAVTwonMhaWGX63eKnjZcFM9Gy8Q"
    change_amount 100000
    message_private_key { message_keys.first }
    message_public_key { message_keys.last }

    association :coin_join, factory: :coin_join_message, strategy: :build, identifier: "this is a message"
  end

  factory :status_message, :class => Coin2Coin::Message::Status do
    ignore do
      current_block_height_and_nonce { Coin2Coin::Bitcoin.instance.current_block_height_and_nonce }
    end

    identifier { "valid_identifier:#{rand}" }
    status "Complete"
    transaction_id { "valid_transaction_id:#{rand}" }
    updated_at { { :block_height => current_block_height_and_nonce.first, :nonce => current_block_height_and_nonce.last } }

    association :coin_join, factory: :coin_join_message, strategy: :build
  end
end



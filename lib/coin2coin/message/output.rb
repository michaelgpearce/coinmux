# OutputList:
# {
#   Address: "1abc..."
#   # This scheme maintains no link between the InputList and the OutputList and ensures that we only add outputs owned by an input.
#   # 1. Decrypt my MessageVerificationInstance#EncryptedIdentifierPrivateKeys to get private key for MessageVerificationInstance#EncryptedIdentifier
#   # 2. Decrypt MessageVerificationInstance#EncryptedIdentifier with private key to get Identifier to allow signing
#   # 3. Hash (Identifier + Address) with OutputList#MessagePublicKey to ControllerInstance#MessagePublicKey
#   MessageVerification: '123...abc'
# }
class Coin2Coin::Message::Output < Coin2Coin::Message::Base
  property :address
  property :message_verification
  
  def initialize(params = {:message_identifier => nil, :address => nil})
    params.assert_valid_keys(:message_identifier, :address)
    
    self.address = params[:address]
    self.message_verification = Coin2Coin::Digest.message_digest(params[:message_identifier], params[:address])
  end
end

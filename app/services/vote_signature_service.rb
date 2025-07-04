class VoteSignatureService
  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, digest: "SHA256")
  end

  def self.generate_signature(ship_event_1_id, ship_event_2_id, user_id)
    # we're using ship events instead of projects, because projects can be voted on multiple times (multiple ship events aka shipchain)
    timestamp = Time.current.to_i

    normalized_ids = normalize_ship_event_order(ship_event_1_id, ship_event_2_id)

    payload = {
      ship_event_1_id: normalized_ids[:ship_event_1_id],
      ship_event_2_id: normalized_ids[:ship_event_2_id],
      user_id: user_id,
      timestamp: timestamp
    }

    verifier.generate(payload)
  end

  def self.verify_signature(signature)
    begin
      payload = verifier.verify(signature)

      # signature is valid for 1h
      if payload["timestamp"] < 1.hour.ago.to_i
        return { valid: false, error: "Voting window has expired" }
      end

      { valid: true, payload: payload }
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      { valid: false, error: "Invalid signature" }
    end
  end

  def self.verify_signature_with_ship_events(signature, ship_event_1_id, ship_event_2_id, user_id)
    verification_result = verify_signature(signature)
    return verification_result unless verification_result[:valid]

    payload = verification_result[:payload]
    normalized_ids = normalize_ship_event_order(ship_event_1_id, ship_event_2_id)

    if payload["ship_event_1_id"] == normalized_ids[:ship_event_1_id] &&
       payload["ship_event_2_id"] == normalized_ids[:ship_event_2_id] &&
       payload["user_id"] == user_id
      { valid: true, payload: payload }
    else
      { valid: false, error: "Vote data has been tampered with" }
    end
  end

  private

  def self.normalize_ship_event_order(ship_event_1_id, ship_event_2_id)
    if ship_event_1_id > ship_event_2_id
      {
        ship_event_1_id: ship_event_2_id,
        ship_event_2_id: ship_event_1_id
      }
    else
      {
        ship_event_1_id: ship_event_1_id,
        ship_event_2_id: ship_event_2_id
      }
    end
  end
end

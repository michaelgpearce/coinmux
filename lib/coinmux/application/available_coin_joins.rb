require 'thread'

class Coinmux::Application::AvailableCoinJoins
  include Coinmux::Facades, Coinmux::Threading

  attr_accessor :data_store

  def initialize(data_store)
    self.data_store = data_store
  end

  # Yields with a Coinmux::Event with Hash data: amount, total_participants, waiting_participants.
  def find(&callback)
    if block_given?
      do_find(&callback)
    else
      event = wait_for_callback(:do_find, &callback)[0]

      raise Coinmux::Error.new(event.error) if event.error

      event.data
    end
  end

  private

  def do_find(&callback)
    data_store.fetch_most_recent(data_store.coin_join_identifier, Coinmux::StateMachine::Participant::COIN_JOIN_MESSAGE_FETCH_SIZE) do |event|
      if event.error
        yield(event)
      else
        coin_join_messages = event.data.collect { |json| Coinmux::Message::CoinJoin.from_json(json, data_store, nil) }.compact

        available_coin_joins = []
        if !coin_join_messages.empty?
          waiting_for = coin_join_messages.size
          waiting_for_mutex = Mutex.new

          coin_join_messages.each do |coin_join_message|
            coin_join_message.status.refresh do |event|
              if event.error
                yield(event)
              else
                if coin_join_message.status.try(:value).try(:state) != 'waiting_for_inputs'
                  waiting_for_mutex.synchronize do
                    waiting_for -= 1
                  end
                else
                  coin_join_message.inputs.refresh do |event|
                    if event.error
                      yield(event)
                    else
                      waiting_for_mutex.synchronize do
                        waiting_for -= 1
                        if coin_join_message.inputs.value.size < coin_join_message.participants
                          available_coin_joins << {
                            amount: coin_join_message.amount,
                            total_participants: coin_join_message.participants,
                            waiting_participants: coin_join_message.inputs.value.size
                          }
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          # we'll block until we get status/inputs for each message. not sure elegant async way to do this
          while waiting_for_mutex.synchronize { waiting_for > 0 }
            sleep(0.1)
          end
        end

        sorted = available_coin_joins.sort do |l, r|
          if (comp = l[:amount] <=> r[:amount]) == 0
            if (comp = l[:total_participants] <=> r[:total_participants]) == 0
              comp = l[:waiting_participants] <=> r[:waiting_participants]
            end
          end
          comp
        end

        debug("Available coin joins: #{sorted}")

        yield(Coinmux::Event.new(data: sorted))
      end
    end
  end
end

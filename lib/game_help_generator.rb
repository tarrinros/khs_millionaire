# Class generates help GameQuestion#help_hash
class GameHelpGenerator
  # Amount of virtual game watchers in %
  TOTAL_WATCHERS = 100

  def self.audience_distribution(keys, correct_key)
    result_array = []

    keys.each do |key|
      if key == correct_key
        result_array << rand(45..90)
      else
        result_array << rand(1..60)
      end
    end

    # Array normalization
    sum = result_array.sum
    result_array.map! { |v| TOTAL_WATCHERS * v / sum }

    # Returns hash from array of keys and values
    Hash[keys.zip(result_array)]
  end

  def self.friend_call(keys, correct_key)
    # 80% returns correct answer & 20% wrong
    key = (rand(10) > 2) ? correct_key : keys.sample

    I18n.t(
      'game_help.friend_call', variant: key.upcase,
      name: I18n.t('game_help.friends').sample
    )
  end
end

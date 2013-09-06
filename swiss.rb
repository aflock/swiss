class Swiss
  attr_accessor :players
  attr_accessor :current_pairs
  attr_accessor :used_pairs
  attr_accessor :current_round
  attr_accessor :number_of_rounds

  def initialize(opts = {})
    self.current_round = 1
    puts "Number of players?"
    self.players = gets.chomp.to_i.times.map do |i|
      puts "Name of player #{i}?"
      name = gets.chomp
      name = nil if name.empty?
      Player.new(:name => name)
    end
    self.number_of_rounds = opts[:number_of_rounds] || calculate_rounds_required(players.size)
  end

  def begin!
    while current_round != (number_of_rounds + 1)
      next_round!
      self.current_round += 1
    end
    announce_winners
    exit
  end

  private

  def puts_announcement(text, options = {})
    puts 80.times.map{ options[:character] || "#" }.to_a.join("") # magic number, terminal width
    announcement_string = (39 - (text.length / 2)).times.map{ options[:character] || "#" }.to_a.join("")
    announcement_string += " #{text} "
    announcement_string = announcement_string.ljust(80, '#')
    puts announcement_string
    puts 80.times.map{ options[:character] || "#" }.to_a.join("")
  end

  def announce_pairings
    puts_announcement("Pairings:")
    current_pairs.each do |pair|
      if pair.length == 1
        puts "#{pair[0].name} gets a bye"
      else
        puts "#{pair[0].name} VS #{pair[1].name}"
      end
      puts "----------------"
    end
  end

  def announce_scores
    puts "|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|"
    puts "|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|"
    puts "Scores after round #{current_round}:"
    players.each { |p| puts "#{p.name} :: #{p.match_points}" }
  end

  def announce_winners
    puts_announcement "Final Scores:"
    final_scores = players.values.map do |player|
      match_score = player.match_points
      game_score = player.game_points
      [player[:name], (game_score + 0.1*match_score)]
    end
    final_scores.sort_by{ |i| i[1] }.reverse.each_with_index do |player, index|
      puts "#{index + 1}. #{player[0]} :: (#{player[1]})"
    end
  end

  def calculate_rounds_required(num_players)
    case num_players
    when 1..8
      3
    when 9..16
      4
    when 17..32
      5
    else
      raise 'Too many players!'
    end
  end

  def initial_round
    self.current_pairs = players.shuffle.each_slice(2).to_a # pair players
    announce_pairings
    retrieve_scores
  end

  def next_round!
    current_round == 1 ? initial_round : regular_round
  end

  def regular_round
    carryover = nil
    # pair players with similar scores
    unassigned_players = players.map do |k,v|
      [k, v[:game_points]]
    end.sort_by{ |i| i[1] }.reverse

    while unassigned_players.length > 1 do
      if carryover
        p = unassigned_players[1]
        eligible_pool = unassigned_players.select do |eligible|
          eligible[1] == p[1]
        end

        potential_pairing = nil

        eligible_pool.each do |eligible|
          potential_pairing = [carryover[0], eligible[0]]
          unless pair_has_already_played?(potential_pairing)
            current_pairs << potential_pairing
            eligible_pool.delete(eligible)
            unassigned_players.delete(eligible)
            unassigned_players.delete(carryover)
            carryover = nil
            break
          end
        end
      else
        p = unassigned_players.first
        eligible_pool = unassigned_players.select do |eligible|
          eligible[1] == p[1]
        end
      end


      while eligible_pool.length > 1
        pairing = eligible_pool.sample(2)
        numeric_pairing = pairing.map{ |t| t[0] }

        # don't rematch
        next if pair_has_already_played?(numeric_pairing)

        current_pairs << numeric_pairing
        pairing.each do |selected|
          eligible_pool.delete(selected)
          unassigned_players.delete(selected)
        end
      end


      if eligible_pool.length == 1
        carryover = eligible_pool.first
      end

      #puts "unassigned player: #{unassigned_players.length}"
    end

    if unassigned_players.length == 1
      current_pairs << [unassigned_players.first[0]]
    end

    announce_pairings
    retrieve_scores
  end

  def retrieve_scores
    puts_announcement("Scoring for Round #{current_round}:")
    current_pairs.each do |pair|
      if pair.size == 1 #bye
        pair[0].award_bye_points
      else
        pair.each { |p| p.award_match_and_game_points }
      end
    end
    #write pairs to 'used_pairs' to prevent rematches
    used_pairs = used_pairs.to_a + self.current_pairs.clone
    current_pairs = []
    announce_scores
  end

  def pair_has_already_played?(pairing)
    used_pairs.each do |used_pair|
      if used_pair.sort == pairing.sort
        return true
      end
    end
    return false
  end

end

class Player
  attr_accessor :name
  attr_accessor :match_points
  attr_accessor :game_points
  attr_accessor :matches

  def initialize(opts = {})
    self.name = opts[:name] || "Player #{(0...4).map{(65+rand(26)).chr.upcase}.join}" # "Player XASB"
    self.game_points = 0
    self.match_points = 0
  end

  def ==(another_player)
    self.name == another_player.name
  end

  def award_bye_points
    self.game_points += 6
    self.match_points += 3
  end

  def award_match_and_game_points
    puts "Match score results for #{name} (3 for win, 1 for draw, 0 for loss):"
    self.match_points += gets.chomp.to_i

    puts "Game score results for #{name} (3 for EACH win, 1 for EACH draw, 0 for loss):"
    self.game_points += gets.chomp.to_i
  end
end

class Match

end


sw = Swiss.new
sw.begin!



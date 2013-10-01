class Swiss
  attr_accessor :players
  attr_accessor :used_pairs
  attr_accessor :current_pairs
  attr_accessor :current_round
  attr_accessor :number_of_rounds

  def initialize(opts = {})
    self.current_round = 1
    puts "Number of players?"
    self.players = gets.chomp.to_i.times.map do |i|
      puts "Name of player #{i + 1}?"
      name = gets.chomp
      name = nil if name.empty?
      Player.new(name: name, id: i)
    end
    self.used_pairs = []
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
        used_pairs << [pair[0].id, pair[1].id]
        puts "#{pair[0].name} VS #{pair[1].name}"
      end
      puts "----------------"
    end
  end

  def pair_has_already_played?(pairing)
    self.used_pairs.each do |used_pair|
      if used_pair.sort == pairing.sort
        return true
      end
    end
    return false
  end

  def announce_scores
    puts_announcement "Scores after round #{current_round}:"
    players.each { |p| puts "#{p.name} :: #{p.match_points}" }
  end

  def announce_winners
    puts_announcement "Final Scores:"
    players.sort_by{ |p| p.match_points }.reverse.each_with_index do |player, index|
      puts "#{index + 1}. #{player.name} :: (#{player.match_points})"
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

  def valid_pairings(user_ids)
    user_ids.combination(2).to_a.reject do |pairing|
      self.pair_has_already_played(pairing)
    end
  end

  def swap_pairs(pairs, pairs_needing_swap)
    user_ids = player_ids
    valid_pairings = valid_pairings(user_ids)
    raise 'no more valid pairs' if valid_pairings*2 < user_ids.length
  end

  def player_ids
    self.players.map(&:id)
  end


  def find_combos(valid_combinations, prior_path = [])
    # right now just do even pairings
    path_length_needed = self.players.count / 2
    valid_combinations.each do |combo|
      prior_path << combo
      if prior_path.length == path_length_needed
        return prior_path
      else
        remaining_ids = player_ids.reject{ |n| prior_path.flatten.include?(n) }
        further_allowed_combos = valid_pairings(remaining_ids)
        if further_allowed_combos.length
          return find_combos(further_allowed_combos, prior_path)
        else
          next
        end
      end
    end
  end

  def sort_by_best_match(combos)
    combos.sort do |c1, c2|
      combo1_p1 = self.players.select{ |p| p.id == c1[0] }
      combo1_p2 = self.players.select{ |p| p.id == c1[1] }
      combo1_score = 1.0/((combo1_p1.match_points - combo1_p2.match_points) + 0.1* (combo1_p1.game_points - combo1_p2.game_points))

      combo2_p1 = self.players.select{ |p| p.id == c2[0] }
      combo2_p2 = self.players.select{ |p| p.id == c2[1] }
      combo2_score = 1.0/((combo2_p1.match_points - combo2_p2.match_points) + 0.1* (combo2_p1.game_points - combo2_p2.game_points))

      combo2_score <=> combo1_score
    end
  end

  def tree_pair
    potential_pairings = valid_pairings(player_ids)
    sorted_potential_pairs = sort_by_best_match(potential_pairings)
    one_true_path = find_combos(sorted_potential_pairs)
    one_true_path.each do |combo|
      player1 = self.players.select{ |p| p.id == combo[0] }
      player2 = self.players.select{ |p| p.id == combo[0] }
      self.current_pairs << [player1, player2]
    end
  end

  def regular_round
    # pair players with the same match points against each other randomly
    # DCI says you do not use tiebreakers when pairing
    sorted_players = players.sort do |p1,p2|
      if p1.match_points != p2.match_points
        p1.match_points <=> p2.match_points
      else
        rand(100) <=> rand(100)
      end
    end.reverse
    self.current_pairs = sorted_players.each_slice(2).to_a

    self.current_pairs.each_with_index do |pair, i|
      if pair_has_already_played(pair.map(&:id))
        pairs_needing_swap << i
      end
    end
    if pairs_needing_swap.length > 0
      tree_pair()
    end


    # this method of pairing will be less likely to have rematches but its still possible
    # self.current_pairs = []
    #groups = players.group_by(&:match_points).values
    #groups.each_with_index do |group, i|

      #while group.length > 1 do
        #potential_pair = group.sample(2)
        #pair_ids = [pair[0].id, pair[1].id]
        #unless pair_has_already_played(pair_ids)
          #current_pairs << potential_pair
          #group.delete(potential_pair[0])
          #group.delete(potential_pair[1])
        #end
      #end

      #if remaining_player = group[0] #an extra player will be bumped to the next group or given a bye
        #if next_group = groups[i+1]
          #next_group << remaining_player
        #else
          #current_pairs << remaining_player
        #end
      #end
    #end


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

    self.current_pairs = []
    announce_scores
  end

end

class Player
  attr_accessor :name
  attr_accessor :match_points
  attr_accessor :game_points
  attr_accessor :matches
  attr_accessor :id

  def initialize(opts = {})
    self.name = opts[:name] || "Player #{(0...4).map{(65+rand(26)).chr.upcase}.join}" # "Player XASB"
    self.id = opts[:id]
    self.game_points = 0
    self.match_points = 0
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


sw = Swiss.new
sw.begin!

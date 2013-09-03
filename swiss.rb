class Swiss
  attr_accessor :players
  attr_accessor :current_pairs
  attr_accessor :used_pairs

  def initialize(num_players)
    self.players = {}
    self.used_pairs = []
    num_players.times do |i|
      puts "Name of player #{i}?"
      name = gets.chomp
      self.players[i] = { name: name, match_points: 0, game_points: 0 }
    end
  end

  def round_one
    # pair players
    self.current_pairs = []
    nums = self.players.keys
    while nums.length > 1 do
      pairing = nums.sample(2)
      nums = nums - pairing
      self.current_pairs << pairing
    end
    if nums.length > 0 # someone gets a bye
      self.current_pairs << nums
    end

    self.announce_pairings
  end

  def announce_pairings
    puts "###################################"
    puts "########### Pairings: #############"
    puts "###################################"
    self.current_pairs.each do |pair|
      if pair.length == 1
        puts "#{players[pair[0]][:name]} gets a bye"
        puts "----------------"
      else
        p1 = players[pair[0]]
        p2 = players[pair[1]]
        puts "#{p1[:name]} VS #{p2[:name]}"
        puts "----------------"
      end
    end
  end

  def retrieve_scores(round_num)
    puts "###################################"
    puts "###### Scoring for Round #{round_num}: "
    puts "###################################"
    puts "Enter match score results for players (3 for win, 1 for draw, 0 for loss):"
    self.current_pairs.each_with_index do |pair|
      if pair.length == 1 #bye
        players[pair[0]][:game_points] += 3
        players[pair[0]][:match_points] += 1
        next
      end
      p1 = players[pair[0]]
      p2 = players[pair[1]]

      puts "#{p1[:name]}?"
      score = gets.strip.to_i
      players[pair[0]][:game_points] += score
      if score > 1 # match win
        players[pair[0]][:match_points] += 1
      end

      puts "#{p2[:name]}?"
      score = gets.strip.to_i
      players[pair[1]][:game_points] += score
      if score > 1 # match win
        players[pair[1]][:match_points] += 1
      end
    end
    #write pairs to 'used_pairs' to prevent rematches
    self.used_pairs += self.current_pairs.clone
    self.current_pairs = []

    puts "|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|>|"
    puts "|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|<|"
    puts "Scores after round #{round_num}:"
    players.each_value do |player|
      puts "#{player[:name]} :: #{player[:game_points]} "
    end
  end

  def round_two
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
          unless self.pair_has_already_played?(potential_pairing)
            self.current_pairs << potential_pairing
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
        next if self.pair_has_already_played?(numeric_pairing)

        self.current_pairs << numeric_pairing
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
      self.current_pairs << [unassigned_players.first[0]]
    end

    self.announce_pairings
  end

  def pair_has_already_played?(pairing)
    self.used_pairs.each do |used_pair|
      if used_pair.sort == pairing.sort
        return true
      end
    end
    return false
  end

  def announce_winners
    puts "Final Scores:"
    final_scores = players.values.map do |player|
      match_score = player[:match_points]
      game_score = player[:game_points]
      [player[:name], (game_score + 0.1*match_score)]
    end
    final_scores.sort_by{ |i| i[1] }.reverse.each_with_index do |player, index|
      puts "#{index + 1}. #{player[0]} :: (#{player[1]})"
    end
  end
end


sw = Swiss.new(8)
sw.round_one
sw.retrieve_scores(1)
sw.round_two
sw.retrieve_scores(2)
sw.round_two
sw.retrieve_scores(3)
sw.announce_winners


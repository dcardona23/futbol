require_relative 'game'
require_relative 'team'
require_relative 'game_team'
require 'CSV'

class StatTracker
    attr_reader :games, :teams, :game_teams

    def initialize
      @games = []
      @teams = []
      @game_teams = []
    end

    def self.from_csv(locations)
       # Create a new instance of the StatTracker class
      stat_tracker = StatTracker.new
      # Call the load_games method on the new StatTracker instance
      # Pass in the value associated with the :games key from the locations hash
      # This value should be the file path to the games CSV file
      stat_tracker.load_games(locations[:games])
      stat_tracker.load_teams(locations[:teams])
      stat_tracker.load_game_teams(locations[:game_teams])
      stat_tracker
    end
    
    def load_games(file_path)
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        @games << Game.new(
            row[:game_id].to_i,
            row[:season],
            row[:type],
            row[:date_time],
            row[:away_team_id],
            row[:home_team_id],
            row[:away_goals].to_i,
            row[:home_goals].to_i,
            row[:venue],
            row[:venue_link]
        )
      end
    end

    def load_teams(file_path)
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        @teams << Team.new(
          row[:team_id], 
          row[:franchiseid], 
          row[:teamname], 
          row[:abbreviation], 
          row[:stadium], 
          row[:link]
          )
      end
    end

    def load_game_teams(file_path)
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        @game_teams << GameTeam.new(
          row[:game_id], 
          row[:team_id], 
          row[:hoa], 
          row[:result], 
          row[:settled_in], 
          row[:head_coach], 
          row[:goals].to_i, 
          row[:shots].to_i, 
          row[:tackles].to_i, 
          row[:pim].to_i, 
          row[:powerplayopportunities].to_i, 
          row[:powerplaygoals].to_i, 
          row[:faceoffwinpercentage].to_f, 
          row[:giveaways].to_i, 
          row[:takeaways].to_i)
      end
    end

    def total_goals
      goals_array= @games.map do |game|
        game.away_goals + game.home_goals
    end
    goals_array
    end

    def highest_total_score
      highest = total_goals.max
      highest
    end

    def lowest_total_score
      lowest = total_goals.min
      lowest
    end
    
  def count_of_teams
    @teams.size
  end

  def create_team_goals_and_games
    team_goals_and_games = {}

    @game_teams.each do |game_team| 
      team_id = game_team.team_id
      
      team_goals_and_games[team_id] ||= { goals: 0, games: 0 }
    
      team_goals_and_games[team_id][:goals] += game_team.goals
      team_goals_and_games[team_id][:games] += 1
    end
    team_goals_and_games
  end

  def calculate_game_stats
    game_stats = {}

    @game_teams.each do |game_team|
      game_id = game_team.game_id
      team_id = game_team.team_id
      game_record = @games.find { |game| game.game_id.to_s == game_id.to_s }
      next unless game_record
  
      season_year = game_record.season
  
      game_stats[game_id] ||= { season_year: season_year, teams: {} }
      game_stats[game_id][:teams][team_id] ||= { goals: 0, games: 0, shots: 0 }
      
      game_stats[game_id][:teams][team_id][:goals] += game_team.goals
      game_stats[game_id][:teams][team_id][:games] += 1
      game_stats[game_id][:teams][team_id][:shots] += game_team.shots
    end
    game_stats
  end

  
  def calculate_average_goals_per_team
    team_goals_and_games = create_team_goals_and_games
    team_stats = {}

    team_goals_and_games.each do |team_id, stats| 
        team_stats[team_id] ||= { goals: 0, games: 0 }
        team_stats[team_id][:goals] += stats[:goals ]
        team_stats[team_id][:games] += stats[:games]
      end

      average_goals = {}
      team_stats.each do |team_id, stats|
        average_goals[team_id] = stats[:goals].to_f / stats[:games]
      end
      average_goals
    end

  def best_offense
    average_goals_per_team = calculate_average_goals_per_team 
    best_team_id = average_goals_per_team.max_by { |team_id, average_goals| average_goals }.first 
    find_team_name(best_team_id)
  end

  def worst_offense
    average_goals_per_team = calculate_average_goals_per_team 
    worst_team_id = average_goals_per_team.min_by { |team_id, average_goals| average_goals }.first 
    find_team_name(worst_team_id)
  end

  def find_team_name(team_id)
    team = @teams.find { |team| team.team_id == team_id }
    team.teamname if team
  end

  def count_of_games_by_season
    games_by_season = {}

    @games.each do |game|
      if games_by_season[game.season]
        games_by_season[game.season] += 1
      else
        games_by_season[game.season] = 1
      end
    end
    games_by_season
  end

  def average_goals_per_game
    total_goals.sum / @games.size.to_f
  end

  def create_season_goals_and_games
    season_goals_and_games = {}
  
    @games.each do |game| 
      season = game.season
  
      season_goals_and_games[season] ||= { goals: 0, games: 0 }
  
      season_goals_and_games[season][:goals] += game.away_goals + game.home_goals
      season_goals_and_games[season][:games] += 1
    end
    season_goals_and_games
  end
  
  def average_goals_by_season
    season_goals_and_games = create_season_goals_and_games
  
    season_goals_and_games.map do |season, stats| 
      [season, (stats[:goals].to_f / stats[:games]).round(2)]
    end.to_h
  end

  def percentage_home_wins
    home_wins = 0
      @games.each do |game|
   if game.home_goals.to_i > game.away_goals.to_i
      home_wins += 1
    end
  end

    total_games = games.size
    percentage = (home_wins.to_f / total_games * 100).round(2)
  end

  def percentage_visitor_wins
    visitor_wins = 0
      @games.each do |game|
    if game.away_goals.to_i > game.home_goals.to_i
      visitor_wins += 1
    end
  end

    total_games = games.size
    percentage = (visitor_wins.to_f / total_games * 100).round(2)
  end

  def percentage_ties
    ties = 0
      @games.each do |game|
    if game.home_goals.to_i == game.away_goals.to_i
      ties +=1
    end
  end

    total_games = games.size
    percentage = (ties.to_f / total_games * 100).round(2)
  end

  def home_games_only #for highest/lowest scoring at home
    home_games = @game_teams.find_all do |game_team|
      game_team.hoa =="home"
    end
    home_games
  end
  
  def home_create_team_goals_and_games
  
    team_goals_and_games = {}
    home_games_only.each do |home_game| 
      team_id = home_game.team_id
      #iterate over each game_team and identifies the team id for each team
  
      team_goals_and_games[team_id] ||= { goals: 0, games: 0 }
      #create an entry for each team and include a default value
  
      team_goals_and_games[team_id][:goals] += home_game.goals
      team_goals_and_games[team_id][:games] += 1
      #add goals and games every time that team id is identified 
    end
    team_goals_and_games
    #return the hash
  end
  
  def home_calculate_average_goals_per_team
  
    team_goals_and_games = home_create_team_goals_and_games
    #use the create team goals and games method
  
      team_goals_and_games.map do |team_id, stats| 
      [team_id, stats[:goals].to_f / stats[:games]]

    end.to_h
  end
  
  def highest_scoring_home_team
    highest_scoring=home_calculate_average_goals_per_team
    #require "pry" ; binding.pry
    highest=highest_scoring.max_by {|team,scoring_percentage| scoring_percentage }
    find_team_name(highest[0])
  end
  
  def lowest_scoring_home_team
    lowest_scoring=home_calculate_average_goals_per_team
    lowest=lowest_scoring.min_by {|team,scoring_percentage| scoring_percentage }
    find_team_name(lowest[0])
  end

  def winningest_coach(season)
    # Returns a nested hash of information with the coach's name as the outer hash 
    # The inner has has total games => qty and wins => qty
    coach_records = {}
    # Allows you to input the season (which come from the game CSV and only use the 
    # first four characters which correspond to the year, or season)
    season_year = season[0..3]

    @game_teams.each do |game|
      next unless game.game_id[0..3] == season_year
      
      coach = game.head_coach
      result = game.result 

      coach_records[coach] ||= { wins: 0, total_games: 0 }
      coach_records[coach][:total_games] += 1
      coach_records[coach][:wins] += 1 if result == "WIN"

      end
      return nil if coach_records.empty?

    win_percentages = {}
      
    coach_records.each do |coach, record|
      win_percentages[coach] = record[:wins].to_f / record[:total_games]
    end

    win_percentages.max_by { |coach, percentage|
      percentage }.first
  end

  def worst_coach(season)
    coach_records = {}
    season_year = season[0..3]

    @game_teams.each do |game|
      next unless game.game_id[0..3] == season_year
      
      coach = game.head_coach
      result = game.result 

      coach_records[coach] ||= { wins: 0, total_games: 0 }
      coach_records[coach][:total_games] += 1
      coach_records[coach][:wins] += 1 if result == "LOSS"

      end
      return nil if coach_records.empty?

    win_percentages = {}
      
    coach_records.each do |coach, record|
      win_percentages[coach] = record[:wins].to_f / record[:total_games]
    end

    win_percentages.max_by { |coach, percentage|
      percentage }.first
  end

  def tackles(season)
    team_records = {}
    season_year = season[0..3]

    @game_teams.each do |game|
      next unless game.game_id[0..3] == season_year
  
    team_id = game.team_id
    tackles = game.tackles
    #require "pry"; binding.pry
    team_records[team_id] ||= {tackles: 0}
    team_records[team_id][:tackles] += tackles
    end
    team_records
  end

def most_tackles(season)
  tackles_tracker = tackles(season)
  most = tackles_tracker.max_by {|team,tackles| tackles[:tackles]}
  find_team_name(most[0])
end

  def fewest_tackles(season)
    tackles_tracker = tackles(season)
    min = tackles_tracker.min_by {|team,tackles| tackles[:tackles]}
  find_team_name(min[0])
end

def opponent_record(team_id)
  #using game_teams to get a record of losses and wins against the team provided
  opponent_records = {}
  @games.each do |game|
    next unless game.away_team_id == team_id || game.home_team_id == team_id
      team_home = game.home_team_id
      team_away = game.away_team_id
      if game.away_team_id ==team_id
         opponent_records[team_home] ||= {wins_against: 0, loss_against: 0, total_games:0}
         opponent_records[team_home][:total_games] +=1
         opponent_records[team_home][:wins_against] += 1 if game.away_goals < game.home_goals

      elsif game.home_team_id ==team_id
        opponent_records[team_away] ||= {wins_against: 0, loss_against: 0, total_games:0}
        opponent_records[team_away][:total_games] +=1
        opponent_records[team_away][:wins_against] += 1 if game.away_goals > game.home_goals
      end
    end
    win_percentages = {}
    opponent_records.each do |team_id,record|
      win_percentages[team_id] = record[:wins_against].to_f/record[:total_games]
    end
    win_percentages
  end

  def favorite_opponent(team_id)
    records = opponent_record(team_id)
    favorite_opponent = records.max_by do |team, percentage|
      percentage
    end
    find_team_name(favorite_opponent[0])
  end

  def rival(team_id)
    records=opponent_record(team_id)
    rival = records.min_by do |team, percentage|
      percentage
    end
    find_team_name(rival[0])
    end

  def calculate_season_accuracy_ratios
    game_stats = calculate_game_stats
    season_accuracy_ratios = {}

    game_stats.each do |game_id, data| 
      season_year = data[:season_year]
      
      season_accuracy_ratios[season_year] ||= {}

      data[:teams].each do |team_id, stats|
        season_accuracy_ratios[season_year][team_id] ||= { total_goals: 0, total_shots: 0 }

        season_accuracy_ratios[season_year][team_id][:total_shots] += stats[:shots]
        season_accuracy_ratios[season_year][team_id][:total_goals] += stats[:goals]
      end
    end

      season_accuracy_ratios.each do |season_year, team_stats|
        team_stats.each do |team_id, totals|
          totals[:accuracy_ratio] = (totals[:total_goals].to_f / totals[:total_shots]).round(3) unless totals[:total_shots].zero?
        end
      end
    season_accuracy_ratios
  end

  def most_accurate_team(season)
    season_accuracy_ratios = calculate_season_accuracy_ratios
    best_team_id = nil
    best_ratio = 0.0

    if season_accuracy_ratios[season]
      season_accuracy_ratios[season].each do |team_id, stats|
        accuracy_ratio = stats[:accuracy_ratio]

        if accuracy_ratio > best_ratio
          best_ratio = accuracy_ratio
          best_team_id = team_id
        end
      end
    end
    find_team_name(best_team_id)
  end

  def least_accurate_team(season)
    season_accuracy_ratios = calculate_season_accuracy_ratios
    worst_team_id = nil
    worst_ratio = Float::INFINITY

    if season_accuracy_ratios[season]
      season_accuracy_ratios[season].each do |team_id, stats|
        accuracy_ratio = stats[:accuracy_ratio]

        if accuracy_ratio < worst_ratio
          worst_ratio = accuracy_ratio
          worst_team_id = team_id
        end
      end
    end
    find_team_name(worst_team_id)
  end

  def team_info(team_id)
    team_info ={}

    @teams.each do |team|
      if team.team_id == team_id
    
      team_info = {
          team_id: team.team_id, 
          franchise_id: team.franchiseid, 
          team_name: team.teamname, 
          abbreviation: team.abbreviation, 
          link: team.link
      }
        break
      end
    end
    team_info
  end

  def away_games_only 
    away_games = @game_teams.find_all do |game_team|
      game_team.hoa =="away"
    end
    away_games
  end

  def away_create_team_goals_and_games
      team_goals_and_games = {}
      away_games_only.each do |away_game| 
        team_id = away_game.team_id

        team_goals_and_games[team_id] ||= { goals: 0, games: 0 }

      team_goals_and_games[team_id][:goals] += away_game.goals
      team_goals_and_games[team_id][:games] += 1
    end
      team_goals_and_games
    end
  def away_calculate_average_goals_per_team
      team_goals_and_games = away_create_team_goals_and_games
        team_goals_and_games.map do |team_id, stats| 
        [team_id, stats[:goals].to_f / stats[:games]]
     end.to_h
  end

  def highest_scoring_visitor
      highest_scoring=away_calculate_average_goals_per_team
      highest=highest_scoring.max_by {|team,scoring_percentage| scoring_percentage }
      find_team_name(highest[0])

  end

  def lowest_scoring_visitor
      lowest_scoring=away_calculate_average_goals_per_team
      lowest=lowest_scoring.min_by {|team,scoring_percentage| scoring_percentage }
      find_team_name(lowest[0])
  end
end
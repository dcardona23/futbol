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
            row[:away_team],
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
    
  def team_count
    @teams.size
  end

  def create_team_goals_and_games
    #need to calculate the total number of goals and total number of games played by each team so we can get the average number of goals scored per game
    team_goals_and_games = {}

    @game_teams.each do |game_team| 
      team_id = game_team.team_id
      #iterate over each game_team and identifies the team id for each team

      team_goals_and_games[team_id] ||= { goals: 0, games: 0 }
      #create an entry for each team and include a default value

      team_goals_and_games[team_id][:goals] += game_team.goals
      team_goals_and_games[team_id][:games] += 1
      #add goals and games every time that team id is identified 
    end
    team_goals_and_games
    #return the hash
  end

  def calculate_average_goals_per_team
    team_goals_and_games = create_team_goals_and_games
    #use the create team goals and games method

    team_goals_and_games.map do |team_id, stats| 
      [team_id, stats[:goals].to_f / stats[:games]]
    end.to_h
    #iterate over team goals and games to identify stats by team id - create a new hash that identifies a team's total goals and divides that by the number of games that team played
  end

  def best_offense
    average_goals_per_team = calculate_average_goals_per_team 
    best_team_id = average_goals_per_team.max_by { |team_id, average_goals| average_goals }.first 
    find_team_name(best_team_id)
    #find best team by identifying the team with the highest average goals - .first identifies team id
  end

  def worst_offense
    average_goals_per_team = calculate_average_goals_per_team 
    worst_team_id = average_goals_per_team.min_by { |team_id, average_goals| average_goals }.first 
    find_team_name(worst_team_id)
  end

  def find_team_name(team_id)
    team = @teams.find { |team| team.team_id == team_id }
    team.teamname if team
    #iterate through teams array to match each team id to a team name
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
  
  def highest_scoring_home
    highest_scoring=home_calculate_average_goals_per_team.max
    find_team_name(highest_scoring[0])
  end
  
  def lowest_scoring_home
    lowest_scoring=home_calculate_average_goals_per_team.min
    find_team_name(lowest_scoring[0])
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
  find_team_name(tackles_tracker.max[0])
end

def fewest_tackles(season)
  tackles_tracker = tackles(season)
  find_team_name(tackles_tracker.min[0])
end

end
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
end
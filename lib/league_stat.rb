module LeagueStat
    def count_of_teams
        @teams.size
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
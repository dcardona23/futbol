module GameStat
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

    def percentage_home_wins
        home_wins = 0
        @games.each do |game|
        if game.home_goals.to_i > game.away_goals.to_i
            home_wins += 1
        end
    end

    total_games = games.count
    percentage = (home_wins.to_f / total_games).round(2)
    end

    def percentage_visitor_wins
    visitor_wins = 0
        @games.each do |game|
        if game.away_goals.to_i > game.home_goals.to_i
            visitor_wins += 1
        end
    end

    total_games = games.count
    percentage = (visitor_wins.to_f / total_games).round(2)
    end

    def percentage_ties
    ties = 0
        @games.each do |game|
        if game.home_goals.to_i == game.away_goals.to_i
            ties +=1
        end
    end

    total_games = games.count
    percentage = (ties.to_f / total_games).round(2)
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

    def average_goals_per_game
        (total_goals.sum / @games.size.to_f).round(2)
    end

    def calculate_game_stats
        game_stats = {}
    
        @game_teams.each do |game_team|
        game_id = game_team.game_id
        team_id = game_team.team_id

        game_record = find_game_record(game_id)
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

    def find_game_record(game_id)
    @games.find { |game| game.game_id.to_s == game_id.to_s }
    end

    def average_goals_by_season
        season_goals_and_games = create_season_goals_and_games
        
        season_goals_and_games.map do |season, stats| 
            [season, (stats[:goals].to_f / stats[:games]).round(2)]
        end.to_h
    end
end
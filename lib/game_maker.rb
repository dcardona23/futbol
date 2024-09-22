module GameMaker
    def goals_and_games(games_or_game_teams, season_or_team)
        goals_and_games = {}
        games_or_game_teams.each do |game_or_game_team|
            goals = 0
            hash_id = "placeholder"
            if season_or_team == "season"
                hash_id = game_or_game_team.season
                goals = game_or_game_team.away_goals + game_or_game_team.home_goals
            elsif season_or_team == "team_id"
                hash_id = game_or_game_team.team_id
                goals = game_or_game_team.goals
            end
    
            goals_and_games[hash_id] ||= { goals: 0, games: 0 }
        
            goals_and_games[hash_id][:goals] += goals
        
            goals_and_games[hash_id][:games] += 1
        end

        goals_and_games
    end
end





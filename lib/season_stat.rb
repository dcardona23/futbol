module SeasonStat
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
            coach_records[coach][:wins] += 1 if result == "WIN"

        end
        return nil if coach_records.empty?

        win_percentages = {}
            
        coach_records.each do |coach, record|
            win_percentages[coach] = record[:wins].to_f / record[:total_games]
        end

        win_percentages.min_by { |coach, percentage|
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

    def calculate_season_stats
        season_stats = {}
    
        @game_teams.each do |game_team|
            game_id = game_team.game_id
            team_id = game_team.team_id
            result = game_team.result
        
            game_record = find_game_record(game_id)
            next unless game_record
        
            season_year = game_record.season
        
            season_stats[team_id] ||= {}
            season_stats[team_id][season_year] ||= { games: 0, wins: 0 }
        
            season_stats[team_id][season_year][:games] += 1 
            season_stats[team_id][season_year][:wins] += 1 if result == 'WIN'
        end
        season_stats
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
                totals[:accuracy_ratio] = (totals[:total_goals].to_f / totals[:total_shots]) unless totals[:total_shots].zero?
            end
        end
    season_accuracy_ratios
    end
    
    def most_accurate_team(season)
        season_accuracy_ratios = calculate_season_accuracy_ratios
        return nil unless season_accuracy_ratios[season] && !season_accuracy_ratios[season].empty?

        most_accurate_team_id, _ = season_accuracy_ratios[season].max_by do |team_id, data|
            data[:accuracy_ratio] || 0
            end
        find_team_name(most_accurate_team_id)
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
end
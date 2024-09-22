module TeamStat
    def team_info(team_id)
        team_info ={}
    
        @teams.each do |team|
            if team.team_id == team_id
    
                team_info = {
                    "team_id" => team.team_id, 
                    "franchise_id" => team.franchiseid, 
                    "team_name" => team.teamname, 
                    "abbreviation" => team.abbreviation, 
                    "link" => team.link
                }
                break
            end
        end
        team_info
    end

    def best_season(team_id)
        season_win_percentages = calculate_season_win_percentages
        best_season = nil
        best_win_percentage = 0.0
        team_id = team_id.to_s
    
        if season_win_percentages.key?(team_id)
            season_win_percentages[team_id].each do |season_year, win_percentage|
            if win_percentage > best_win_percentage
                best_win_percentage = win_percentage
                best_season = season_year
                end
            end
        end
        best_season
    end
    
    def worst_season(team_id)
        season_win_percentages = calculate_season_win_percentages
        worst_season = nil
        worst_win_percentage = Float::INFINITY
        team_id = team_id.to_s
    
        if season_win_percentages.key?(team_id)
            season_win_percentages[team_id].each do |season_year, win_percentage|
                if win_percentage < worst_win_percentage
                worst_win_percentage = win_percentage
                worst_season = season_year
                end
            end
        end
        worst_season
    end

    def opponent_record(team_id)
        #using game_teams to get a record of losses and wins against the team provided
        opponent_records = {}
        @games.each do |game|
        next unless game.away_team_id == team_id || game.home_team_id == team_id
        team_home = game.home_team_id
        team_away = game.away_team_id
        if game.away_team_id ==team_id
            opponent_records[team_home] ||= {wins_against: 0, total_games:0}
            opponent_records[team_home][:total_games] +=1
            opponent_records[team_home][:wins_against] += 1 if game.away_goals > game.home_goals
    
        elsif game.home_team_id ==team_id
            opponent_records[team_away] ||= {wins_against: 0, total_games:0}
            opponent_records[team_away][:total_games] +=1
            opponent_records[team_away][:wins_against] += 1 if game.away_goals < game.home_goals
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

    def calculate_season_win_percentages
        season_stats = calculate_season_stats
        season_win_percentages = {} 
    
        season_stats.each do |team_id, seasons|
            season_win_percentages[team_id] ||= {}
            seasons.each do |season_year, stats|
                total_games = stats[:games]
                total_wins = stats[:wins]
                win_percentage = total_games > 0? (total_wins.to_f / total_games * 100) : 0
                season_win_percentages[team_id][season_year] = win_percentage 
            end
        end
        season_win_percentages
    end
    
    
    def calculate_team_wins(team_id)
        team_wins = []
    
        @game_teams.each do |game_team|
            if game_team.team_id.to_s == team_id.to_s && game_team.result == 'WIN'
                team_wins << game_team.game_id
            end
        end
        team_wins
    end
    
    def calculate_team_losses(team_id)
        team_losses = []
    
        @game_teams.each do |game_team|
            if game_team.team_id.to_s == team_id.to_s && game_team.result == 'LOSS'
                team_losses << game_team.game_id
            end
        end
        team_losses
    end
    
    def calculate_winning_points_differences(team_id)
        team_wins = calculate_team_wins(team_id)
        winning_points_differences = {}
    
        @games.each do |game|
            next unless team_wins.include?(game.game_id.to_s)
        
            points_difference = if game.away_team_id.to_s == team_id.to_s
                game.away_goals - game.home_goals
            else
                game.home_goals - game.away_goals
            end
        
            winning_points_differences[game.game_id] = points_difference
        end
        winning_points_differences
    end
    
    def biggest_team_blowout(team_id)
        winning_points_differences = calculate_winning_points_differences(team_id)
        biggest_team_blowout = winning_points_differences.values.max
        biggest_team_blowout
    end
    
    def calculate_losing_points_differences(team_id)
        team_losses = calculate_team_losses(team_id)
        losing_points_differences = {}
    
        @games.each do |game|
            next unless team_losses.include?(game.game_id.to_s)
        
            points_difference = if game.away_team_id.to_s == team_id.to_s
                game.home_goals - game.away_goals
            else
                game.away_goals - game.home_goals
            end
    
        losing_points_differences[game.game_id] = points_difference
        end
        losing_points_differences
    end
    
    def worst_loss(team_id)
        losing_points_differences = calculate_losing_points_differences(team_id)
        worst_loss = losing_points_differences.values.max
        worst_loss
    end

    def head_to_head(team_id)
        record = opponent_record(team_id)
        head_to_head_hash ={}
        record.each do |team_id,win_percentage|
            head_to_head_hash[find_team_name(team_id)] = win_percentage
        end
        head_to_head_hash
    end

    def most_goals_scored(team_id)
        team_games = @games.select { |game| game.home_team_id == team_id || game.away_team_id == team_id }
      
        max_goals = team_games.map do |game|
          if game.home_team_id == team_id
            game.home_goals
          else
            game.away_goals
          end
        end.max
          max_goals
        end

      def fewest_goals_scored(team_id)
        team_games = @games.select { |game| game.home_team_id == team_id || game.away_team_id == team_id }
      
        min_goals = team_games.map do |game|
          if game.home_team_id == team_id
            game.home_goals
          else
            game.away_goals
          end
        end.min
          min_goals
        end  

    def calculate_season_summary(team_id)
        season_stats ={}
        @games.each do |game|
            next unless game.away_team_id == team_id || game.home_team_id == team_id
            season = game.season
            team_home = game.home_team_id
            team_away = game.away_team_id
            away_goals = game.away_goals
            home_goals = game.home_goals
            type=game.type
            if team_away == team_id
                if game.type == "Postseason"
                season_stats[season] ||={postseason:{wins:0, goals_for: 0, goals_against: 0,games: 0} }
                season_stats[season][:postseason][:goals_for] += away_goals
                season_stats[season][:postseason][:goals_against] += home_goals
                season_stats[season][:postseason][:games] += 1
                if away_goals > home_goals
                    season_stats[season][:postseason][:wins] += 1
                end
            end
                if game.type == "Regular Season"
                season_stats[season] ||={regular_season:{wins:0, goals_for: 0, goals_against: 0,games: 0} }
                season_stats[season][:regular_season][:goals_for] += away_goals
                season_stats[season][:regular_season][:goals_against] += home_goals
                season_stats[season][:regular_season][:games] += 1
                if away_goals > home_goals
                    season_stats[season][:regular_season][:wins] += 1
                end
            end
            else team_home == team_id
                if game.type == "Postseason"
                    season_stats[season] ||={postseason:{wins:0, goals_for: 0, goals_against: 0,games: 0} }
                    season_stats[season][:postseason][:goals_for] += home_goals
                    season_stats[season][:postseason][:goals_against] += away_goals
                    season_stats[season][:postseason][:games] += 1
                    if away_goals < home_goals
                    season_stats[season][:postseason][:wins] += 1
                    end
                end
                if game.type == "Regular Season"
                    season_stats[season] ||={regular_season:{wins:0, goals_for: 0, goals_against: 0,games: 0} }
                    season_stats[season][:regular_season][:goals_for] += home_goals
                    season_stats[season][:regular_season][:goals_against] += away_goals
                    season_stats[season][:regular_season][:games] += 1
                    if away_goals < home_goals
                    season_stats[season][:regular_season][:wins] += 1
                    end
                end
            end
        end
        season_stats
    end
    
    def seasonal_summary(team_id)
        summary = {}
        season_stats=calculate_season_summary(team_id)
        season_stats.each do |season,data|
    
            if data[:regular_season] != nil
                summary[season] ||= summary[season] ||={regular_season:{win_percentage:0, total_goals_scored: 0, total_goals_against: 0, average_goals_scored: 0, average_goals_against: 0}}
                summary[season][:regular_season][:win_percentage] = data[:regular_season][:wins].to_f/data[:regular_season][:games]
                summary[season][:regular_season][:total_goals_scored]=data[:regular_season][:goals_for]
                summary[season][:regular_season][:total_goals_against]=data[:regular_season][:goals_against]
                summary[season][:regular_season][:average_goals_scored]= data[:regular_season][:goals_for].to_f/data[:regular_season][:games]
                summary[season][:regular_season][:average_goals_against]= data[:regular_season][:goals_against].to_f/data[:regular_season][:games]
            end
            if data[:postseason] != nil
                summary[season] ||= summary[season] ||={postseason:{win_percentage:0, total_goals_scored: 0, total_goals_against: 0, average_goals_scored: 0, average_goals_against: 0}}
                summary[season][:postseason][:win_percentage] = data[:postseason][:wins].to_f/data[:postseason][:games]
                summary[season][:postseason][:total_goals_scored]=data[:postseason][:goals_for]
                summary[season][:postseason][:total_goals_against]=data[:postseason][:goals_against]
                summary[season][:postseason][:average_goals_scored]= data[:postseason][:goals_for].to_f/data[:postseason][:games]
                summary[season][:postseason][:average_goals_against]= data[:postseason][:goals_against].to_f/data[:postseason][:games]
            end
        end
        summary
    end
end
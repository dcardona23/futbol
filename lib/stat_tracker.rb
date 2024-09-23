require_relative 'game'
require_relative 'team'
require_relative 'game_team'
require 'CSV'
require_relative 'game_maker'

class StatTracker
  include GameMaker
    attr_reader :games, :teams, :game_teams

    def initialize
      @games = []
      @teams = []
      @game_teams = []
    end

    def self.from_csv(locations)
      stat_tracker = StatTracker.new
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
          row[:takeaways].to_i
          )
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
    
    def home_calculate_average_goals_per_team
        team_goals_and_games = home_create_team_goals_and_games
    
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
        goals_and_games(@game_teams, "team_id")
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
        goals_and_games(away_games_only, "team_id")
    end

    def away_calculate_average_goals_per_team
        team_goals_and_games = away_create_team_goals_and_games
        
        team_goals_and_games.map do |team_id, stats| 
            [team_id, stats[:goals].to_f / stats[:games]]
        end.to_h
    end

    def highest_scoring_home_team
        highest_scoring=home_calculate_average_goals_per_team
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

    def create_season_goals_and_games
        goals_and_games(@games, "season")
    end

    def home_create_team_goals_and_games
        goals_and_games(home_games_only, "team_id")
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

    def winningest_coach(season)
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
    
    def calculate_team_ties(team_id)
        team_ties = []
    
        @game_teams.each do |game_team|
            if game_team.team_id.to_s == team_id.to_s && game_team.result == 'TIE'
                team_ties << game_team.game_id
            end
        end
        team_ties
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

    def average_win_percentage(team_id)
        wins = calculate_team_wins(team_id).size
        ties = calculate_team_ties(team_id).size
        total_games = wins + ties + calculate_team_losses(team_id).size
       
        returm 0.0 if total_games == 0
 
        (wins.to_f/ total_games).round(2)
    end
end
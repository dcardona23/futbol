require './lib/game'
require './lib/game_team'
require './lib/team'
require './lib/stat_tracker'
require 'CSV'
require 'spec_helper'

RSpec.describe StatTracker do
    before(:each) do
      game_path = './data/games_dummy.csv'
      team_path = './data/teams.csv'
      game_teams_path = './data/game_teams_dummy.csv'

      locations = {
          games: game_path,
          teams: team_path,
          game_teams: game_teams_path
          }
        
      @stat_tracker = StatTracker.from_csv(locations)
    end
    
    describe '#initialize' do
        it 'exists' do
            expect(@stat_tracker).to be_instance_of(StatTracker)
        end
    end

    describe "#highest_total_score" do
        it 'can provide the highest combined score' do
            expect(@stat_tracker.highest_total_score).to eq(7)
            #expect(@stat_tracker.highest_total_score).to eq(11)
        end
    end

    describe "#lowest_total_score" do
      it 'can provide the lowest combined score' do
        expect(@stat_tracker.lowest_total_score).to eq(1)
        #expect(@stat_tracker.lowest_total_score).to eq(0)
      end
    end

    describe '#teams' do 
      it 'can count the total number of teams' do
        expect(@stat_tracker.team_count).to eq(32)
      end
    end

    describe '#scoring' do 
        it 'can identify the best offense' do
            # require 'pry'; binding.pry
            expect(@stat_tracker.best_offense).to eq("Toronto FC")
        end

        it 'can identify the worst offense' do
            expect(@stat_tracker.worst_offense).to eq("Atlanta United")
        end
    end

    describe "#count_of_games_by_season" do
      it 'can provide the number of games by season' do
        expect(@stat_tracker.count_of_games_by_season).to eq({"20122013"=>9, "20132014"=>2, "20152016"=>5, "20162017"=>3, "20172018"=>6})
      end
    end

    describe "#average_goals_per_game" do
      it 'can provide provide the averge number of goals scored in a game across all seasons' do
        expect(@stat_tracker.average_goals_per_game).to eq(4.48)
      end
    end

    describe '#average_goals_by season' do
      it 'can provide a hash with season names as keys, and average number of goals for that season as the value' do
        expect(@stat_tracker.average_goals_by_season).to eq({"20122013"=>4.0, "20132014"=>3.5, "20152016"=>4.6, "20162017"=>4.67, "20172018"=>5.33})
      end
    end
    describe "percentage_home_wins" do
    it 'can return the percentage of home wins' do
      expect(@stat_tracker.percentage_home_wins).to eq(40.0)
    end
  end

    describe "percentage_visitor_wins" do
    it 'can return the percentage of away wins' do
      expect(@stat_tracker.percentage_visitor_wins).to eq(36.0)
    end
  end

    describe "percentage_ties" do
    it 'can return the percentage of ties' do
      expect(@stat_tracker.percentage_ties).to eq(24.0)
    end
  end

    describe "highest_scoring_home" do
      it "can return the team with the highest average goals at home" do
        expect(@stat_tracker.highest_scoring_home).to eq("FC Dallas")
      end
    end
    
    describe "lowest_scoring_home" do
      it "can return the team with the lowest average goals at home" do
        expect(@stat_tracker.lowest_scoring_home).to eq("Atlanta United")
      end
    end

    describe "#winningest_coach" do
      it "can return a name of the Coach with the best win percentage for the season" do
        expect(@stat_tracker.winningest_coach("20132014")).to eq("Barry Trotz")
        expect(@stat_tracker.winningest_coach("20122013")).to eq("Claude Julien")
      end
    end

    describe "#worst_coach" do
      it "can return a name of the Coach with the worst win percentage for the season" do
        expect(@stat_tracker.worst_coach("20132014")).to eq("Michel Therrien")
        expect(@stat_tracker.worst_coach("20122013")).to eq("John Tortorella")
      end
    end

    describe "#most_tackles" do
      it "can return the team with the most total tackles based on season" do
        expect(@stat_tracker.most_tackles("2012030221")).to eq("FC Dallas")
      end
    end

    describe "#fewest_tackles" do
    it "can return the team with the fewest total tackles based on season" do
      expect(@stat_tracker.fewest_tackles("2012030221")).to eq("Atlanta United")
    end
  end

  end

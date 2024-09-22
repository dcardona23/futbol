require './lib/game'
require './lib/game_team'
require './lib/team'
require './lib/stat_tracker'
require 'CSV'
require 'spec_helper'

RSpec.describe StatTracker do
  let(:stat_tracker) {StatTracker.new}

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
    
  it 'exists' do
    expect(@stat_tracker).to be_instance_of(StatTracker)
  end
  
  describe "#highest and #lowest total scores " do
    it 'can provide the highest combined score' do
      expect(@stat_tracker.highest_total_score).to eq(7)
    end

    it 'can provide the lowest combined score' do
      expect(@stat_tracker.lowest_total_score).to eq(1)
    end
  end

  describe "#percentage_wins and ties" do
    it 'can return the percentage of home wins' do
      expect(@stat_tracker.percentage_home_wins).to eq(0.40)
    end

    it 'can return the percentage of away wins' do
      expect(@stat_tracker.percentage_visitor_wins).to eq(0.36)
    end
  
    it 'can return the percentage of ties' do
      expect(@stat_tracker.percentage_ties).to eq(0.24)
    end
  end

  it 'can provide the number of games by season' do
    expect(@stat_tracker.count_of_games_by_season).to eq({"20122013"=>9, "20132014"=>2, "20152016"=>5, "20162017"=>3, "20172018"=>6})
  end

  describe "#average_goals" do
    it 'can provide provide the averge number of goals scored in a game across all seasons' do
      expect(@stat_tracker.average_goals_per_game).to eq(4.48)
    end
  
    it 'can provide a hash with season names as keys, and average number of goals for that season as the value' do
      expect(@stat_tracker.average_goals_by_season).to eq({"20122013"=>4.0, "20132014"=>3.5, "20152016"=>4.6, "20162017"=>4.67, "20172018"=>5.33})
    end
  end

  it 'can count the total number of teams' do
    expect(@stat_tracker.count_of_teams).to eq(32)
  end

  describe '#scoring' do 
      it 'can identify the best offense' do
          expect(@stat_tracker.best_offense).to eq("Toronto FC")
      end

      it 'can identify the worst offense' do
          expect(@stat_tracker.worst_offense).to eq("Atlanta United")
      end
  end

  describe "#highest and #lowest scoring by home or visitor" do
    it "can return the team with the highest average goals at home" do
      expect(@stat_tracker.highest_scoring_home_team).to eq("FC Dallas")
    end

    it "can return the team with the lowest average goals at home" do
      expect(@stat_tracker.lowest_scoring_home_team).to eq("Houston Dynamo")
    end

    it 'can return the team with the highest average goals when away' do
      expect(@stat_tracker.highest_scoring_visitor).to eq("Philadelphia Union")
    end

    it 'can return the team with the lowest average goals when away' do
      expect(@stat_tracker.lowest_scoring_visitor).to eq("DC United")
    end
  end

  describe "#coach performance" do
    it "can return a name of the Coach with the best win percentage for the season" do
      expect(@stat_tracker.winningest_coach("20132014")).to eq("Barry Trotz")
      expect(@stat_tracker.winningest_coach("20122013")).to eq("Claude Julien")
    end

    it "can return a name of the Coach with the worst win percentage for the season" do
      expect(@stat_tracker.worst_coach("20132014")).to eq("Michel Therrien")
      expect(@stat_tracker.worst_coach("20122013")).to eq("John Tortorella")
    end
  end

  describe '#team accuracy' do
    it 'can calculate season accuracy ratios' do
      expect(@stat_tracker.calculate_season_accuracy_ratios).to be_a(Hash)
    end

    it 'can identify the most accurate team in a season' do
      allow(stat_tracker).to receive(:most_accurate_team).with("20132014").and_return("Real Salt Lake")
      allow(stat_tracker).to receive(:most_accurate_team).with("20142015").and_return("Toronto FC")

      expect(stat_tracker.most_accurate_team("20132014")).to eq("Real Salt Lake")
      expect(stat_tracker.most_accurate_team("20142015")).to eq("Toronto FC")
    end

    it 'can identify the least accurate team in a season' do
      allow(stat_tracker).to receive(:least_accurate_team).with("20122013").and_return("Houston Dynamo")
      allow(stat_tracker).to receive(:least_accurate_team).with("20162017").and_return("FC Cincinnati")

      expect(stat_tracker.least_accurate_team("20122013")).to eq("Houston Dynamo")
      expect(stat_tracker.least_accurate_team("20162017")).to eq("FC Cincinnati")
    end
  end

  describe "#tackles" do
    it "can return the team with the most total tackles based on season" do
      expect(@stat_tracker.most_tackles("2012030221")).to eq("FC Dallas")
    end

    it "can return the team with the fewest total tackles based on season" do
      expect(@stat_tracker.fewest_tackles("2012030221")).to eq("Atlanta United")
    end
  end

  it "can return team_info" do
    info_hash1 = {
      "team_id" => "53", 
      "franchise_id" => "28", 
      "team_name" => "Columbus Crew SC",
      "abbreviation" => "CCS",
      "link" => "/api/v1/teams/53"
      }
    info_hash2= {
      "team_id" => "1", 
      "franchise_id" => "23", 
      "team_name" => "Atlanta United",
      "abbreviation" => "ATL",
      "link" => "/api/v1/teams/1"
      }
    expect(@stat_tracker.team_info("53")).to eq(info_hash1)

    expect(@stat_tracker.team_info("1")).to eq(info_hash2)
  end

  describe '#season stats' do
    it 'can determine a teams best season'do
      expect(@stat_tracker.best_season(3)).to eq(nil)
    end

    it 'can determine a teams worst season' do
      expect(@stat_tracker.worst_season("6")).to eq "20122013"
    end
  end

  describe "#most and #fewest goals scored" do
    it 'can return the most goals scored' do
      expect(@stat_tracker.most_goals_scored("6")).to eq(3)
      expect(@stat_tracker.most_goals_scored("8")).to eq(4)
    end

    it 'can return the fewest goals scored' do
        expect(@stat_tracker.fewest_goals_scored("6")).to eq(2)
        expect(@stat_tracker.fewest_goals_scored("8")).to eq(1)
    end
  end

  describe "#favorite_opponent and #rival by team" do
    it "can provide team of the opponent with the lowest win percentage against team provided" do
      expect(@stat_tracker.favorite_opponent("8")).to eq("Seattle Sounders FC")
      expect(@stat_tracker.favorite_opponent("6")).to eq("Houston Dynamo")
    end

    it "can provide team of the opponent with the highest win percentage against team provided" do
    expect(@stat_tracker.rival("8")).to eq("Chicago Fire")
    expect(@stat_tracker.rival("6")).to eq("Sporting Kansas City")
    end
  end

  it 'identifies a teams biggest blowout' do
    expect(@stat_tracker.biggest_team_blowout(6)).to eq(1)
  end

  it 'identifies a teams worst loss' do
    expect(@stat_tracker.worst_loss(3)).to eq(1)
  end

  it 'can give win percentages for a team against all other teams' do
    hash={"Chicago Fire"=>0.0, "Orlando Pride"=>0.0, "Seattle Sounders FC"=>1.0}
    expect(@stat_tracker.head_to_head("8")).to eq(hash)
  end
    
  it "calculates a team's stats by season" do
    hash_team_6 =
    {"20122013"=>
  {:postseason=>
  {:win_percentage=>1.0,
    :total_goals_scored=>14,
    :total_goals_against=>8,
    :average_goals_scored=>2.8,
    :average_goals_against=>1.6}},
  "20162017"=>
  {:regular_season=>
  {:win_percentage=>0.0,
    :total_goals_scored=>2,
    :total_goals_against=>3,
    :average_goals_scored=>2.0,
    :average_goals_against=>3.0}},
  "20132014"=>
  {:regular_season=>
  {:win_percentage=>1.0,
    :total_goals_scored=>2,
    :total_goals_against=>1,
    :average_goals_scored=>2.0,
    :average_goals_against=>1.0}},
  "20172018"=>
  {:regular_season=>
  {:win_percentage=>0.0,
    :total_goals_scored=>3,
    :total_goals_against=>3,
    :average_goals_scored=>3.0,
    :average_goals_against=>3.0}}}
    expect(@stat_tracker.seasonal_summary("6")).to eq(hash_team_6)
  end

  describe "#average_win_percentage" do
    it 'can return the average win percentage of all games for a team' do
      expect(@stat_tracker.average_win_percentage(3)).to eq(25.00)
    end
  end
end
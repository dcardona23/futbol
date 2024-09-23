require './lib/team' 
require './lib/stat_tracker'


RSpec.describe Team do
    before(:each) do
        @team = Team.new(1,23,"Atlanta United","ATL","Mercedes-Benz Stadium","/api/v1/teams/1")
    end

    describe '#initialze' do
        it "exists" do
            expect(@team).to be_instance_of(Team)
        end

        it 'has attributes' do
            expect(@team.team_id).to eq(1)
            expect(@team.franchiseid).to eq(23)
            expect(@team.teamname).to eq("Atlanta United")
            expect(@team.abbreviation).to eq("ATL")
            expect(@team.stadium).to eq("Mercedes-Benz Stadium")
            expect(@team.link).to eq("/api/v1/teams/1")
        end
    end
end
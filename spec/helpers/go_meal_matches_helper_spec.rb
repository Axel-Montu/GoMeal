require "rails_helper"

RSpec.describe GoMealMatchesHelper, type: :helper do
  describe "#restaurant_cover_photo" do
    let(:restaurant) do
      Restaurant.create!(
        name: "L'Atelier Verde",
        address: "14 rue des Petits-Champs, 75002 Paris"
      )
    end

    it "always gives the same restaurant the same cover" do
      # 1. Two calls on the same record must not drift
      first_call  = helper.restaurant_cover_photo(restaurant)
      second_call = helper.restaurant_cover_photo(restaurant)

      expect(first_call).to eq(second_call)
    end

    it "only ever returns a cover we actually ship" do
      # 2. Guards against an id that would fall outside the list
      expect(GoMealMatchesHelper::COVER_PHOTOS)
        .to include(helper.restaurant_cover_photo(restaurant))
    end
  end
end

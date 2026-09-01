require "rails_helper"

RSpec.describe "Reviews index", type: :request do
  # 1. Two users, each with a lunch of their own. The second one exists only to
  #    prove they never show up in the first one's list.
  let(:owner) { User.create!(email: "list@example.com", password: "password") }
  let(:other) { User.create!(email: "other3@example.com", password: "password") }

  # 2. Two restaurants, one per user. Both need an address: Restaurant
  #    validates its presence, and these go through the database.
  let(:mine) do
    Restaurant.create!(name: "Chez Marcelle",
                       address: "8 rue Rambuteau, 75003 Paris")
  end
  let(:theirs) do
    Restaurant.create!(name: "Trattoria Nona",
                       address: "3 rue Charlot, 75003 Paris")
  end

  describe "GET /reviews" do
    it "lists my own matches only" do
      # 1. One lunch each, both over an hour ago, so both are waiting for a
      #    rating. Without expected_back_at in the past, neither would appear.
      GoMealMatch.create!(user: owner, restaurant: mine,
                          expected_back_at: 1.hour.ago)
      GoMealMatch.create!(user: other, restaurant: theirs,
                          expected_back_at: 1.hour.ago)

      # 2. Signed in as the first one
      sign_in owner

      # 3. `reviews_path` rather than "/reviews": a hand-written URL would not
      #    follow a change of routes, and would fail silently
      get reviews_path

      # 4. What the page holds is the real subject here. A 200 would also be
      #    returned by an empty page, so it would prove nothing.
      expect(response.body).to include("Chez Marcelle")
      expect(response.body).not_to include("Trattoria Nona")
    end

    it "shows the empty state when there is nothing at all" do
      # 1. This user has no match at all: no lunch is created here
      sign_in owner

      get reviews_path

      # 2. An empty list must lead somewhere, so the empty state is a
      #    deliverable of its own, not the absence of one
      expect(response.body).to include("Aucun déjeuner à noter")
    end
  end
end

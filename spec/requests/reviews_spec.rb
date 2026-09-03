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

  describe "POST /go_meal_matches/:id/review" do
    let(:match) do
      GoMealMatch.create!(user: owner, restaurant: mine,
                          expected_back_at: 1.hour.ago)
    end

    it "saves the review and lands back on the match" do
      sign_in owner

      post go_meal_match_review_path(match),
           params: { review: { rating: 4, comment: "Servi en douze minutes." } }

      expect(match.reload.review.rating).to eq(4)
      expect(response).to redirect_to(go_meal_match_path(match))
    end

    it "writes nothing when the rating is missing" do
      sign_in owner

      # 1. This is the case the stars are meant to prevent. It must hold server
      #    side too, since a form can always be submitted without JavaScript.
      expect {
        post go_meal_match_review_path(match), params: { review: { rating: "" } }
      }.not_to change(Review, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "answers 404 on a match belonging to someone else" do
      theirs_match = GoMealMatch.create!(user: other, restaurant: theirs)
      sign_in owner

      post go_meal_match_review_path(theirs_match),
           params: { review: { rating: 5 } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /go_meal_matches/:id/review" do
    let(:match) do
      GoMealMatch.create!(user: owner, restaurant: mine,
                          expected_back_at: 1.hour.ago)
    end

    it "updates the review in place, without creating a second one" do
      Review.create!(go_meal_match: match, rating: 2, comment: "Bof.")
      sign_in owner

      expect {
        patch go_meal_match_review_path(match),
              params: { review: { rating: 5, comment: "En fait très bien." } }
      }.not_to change(Review, :count)

      expect(match.reload.review.rating).to eq(5)
      expect(response).to redirect_to(go_meal_match_path(match))
    end

    it "changes nothing when the rating is cleared" do
      Review.create!(go_meal_match: match, rating: 3)
      sign_in owner

      patch go_meal_match_review_path(match), params: { review: { rating: "" } }

      expect(match.reload.review.rating).to eq(3)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /go_meal_matches/:id/review" do
    let(:match) do
      GoMealMatch.create!(user: owner, restaurant: mine,
                          expected_back_at: 1.hour.ago)
    end

    it "removes the review and lands back on the match" do
      Review.create!(go_meal_match: match, rating: 4)
      sign_in owner

      expect {
        delete go_meal_match_review_path(match)
      }.to change(Review, :count).by(-1)

      expect(response).to redirect_to(go_meal_match_path(match))
    end

    it "answers 404 on a review that belongs to someone else" do
      theirs_match = GoMealMatch.create!(user: other, restaurant: theirs)
      Review.create!(go_meal_match: theirs_match, rating: 5)
      sign_in owner

      # 1. The match is loaded among the current user's own, so this one is
      #    simply not found, and its review is never reached
      expect {
        delete go_meal_match_review_path(theirs_match)
      }.not_to change(Review, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end

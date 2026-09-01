require "rails_helper"

RSpec.describe Review, type: :model do
  # 1. A match to hang the review on, rebuilt by each example that needs one
  def build_match
    user = User.new(email: "review@example.com", password: "password")
    restaurant = Restaurant.create!(name: "Chez Marcelle",
    address: "8 rue Rambuteau, 75003 Paris")
    GoMealMatch.new(user: user, restaurant: restaurant)
  end

  it "is valid with a rating between 1 and 5" do
    review = Review.new(go_meal_match: build_match, rating: 4)

    expect(review).to be_valid
  end

  it "refuses a review without a rating" do
    review = Review.new(go_meal_match: build_match, rating: nil)

    expect(review).not_to be_valid
  end

  it "refuses a rating outside 1 to 5" do
    review = Review.new(go_meal_match: build_match, rating: 6)

    expect(review).not_to be_valid
  end

  it "accepts a review with no comment" do
    review = Review.new(go_meal_match: build_match, rating: 3, comment: nil)

    expect(review).to be_valid
  end

  it "refuses a comment longer than 500 characters" do
    review = Review.new(go_meal_match: build_match, rating: 3,
                        comment: "a" * 501)

    expect(review).not_to be_valid
  end

  it "destroys the review when its match is destroyed" do
    # 1. This one goes through the database, since dependent: :destroy is the
    #    subject
    user = User.create!(email: "destroy@example.com", password: "password")
    restaurant = Restaurant.create!(name: "Chez Marcelle",
    address: "8 rue Rambuteau, 75003 Paris")
    match = GoMealMatch.create!(user: user, restaurant: restaurant)
    Review.create!(go_meal_match: match, rating: 5)

    # 2. Destroying the match must take the review with it
    expect { match.destroy }.to change(Review, :count).by(-1)
  end
end

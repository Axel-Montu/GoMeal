class ReviewsController < ApplicationController
  def index
    # 1. Start from the current user's own matches. policy_scope does the
    #    filtering, so no `where(user: current_user)` is written by hand.
    #    Restaurants and reviews load in the same go: without that, every row
    #    of the list would open two more queries.
    matches = policy_scope(GoMealMatch).includes(:restaurant, :review)

    # 2. Those still waiting for a rating
    @awaiting = matches.select(&:awaiting_review?)

    # 3. Those already rated, most recent review first
    @reviewed = matches.select { |match| match.review.present? }
                       .sort_by { |match| match.review.created_at }
                       .reverse
  end
end

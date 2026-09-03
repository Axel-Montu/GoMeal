class ReviewsController < ApplicationController
  before_action :set_match, only: [:new, :create, :edit, :update, :destroy]

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

  def new
    # 1. An empty review, already tied to its lunch
    @review = @match.build_review
    authorize @review
  end

  def create
    # 1. Build from what the form sent, on this lunch and no other
    @review = @match.build_review(review_params)
    authorize @review

    if @review.save
      # 2. Back to the match, which now shows the review
      redirect_to go_meal_match_path(@match),
                  notice: "Merci, ton avis est enregistré."
    else
      # 3. Same form, errors shown, nothing written. 422 rather than 200:
      #    Turbo only re-renders a failed form on an error status.
      render :new, status: :unprocessable_entity
    end
  end


  def edit
    # 1. The review this lunch already carries
    @review = @match.review
    authorize @review
  end

  def update
    @review = @match.review
    authorize @review

    if @review.update(review_params)
      redirect_to go_meal_match_path(@match), notice: "Ton avis est à jour."
    else
      # 2. Same form, errors shown, nothing changed
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review = @match.review
    authorize @review

    @review.destroy

    # 3. Back to the match, which offers the rating form again
    redirect_to go_meal_match_path(@match), notice: "Ton avis a été supprimé."
  end

  private

  def set_match
    # 1. Look among the current user's own matches only: someone else's is
    #    simply not found
    @match = current_user.go_meal_matches.find_by(id: params[:go_meal_match_id])

    return if @match.present?

    # 2. A 404, and we never say whether the match exists elsewhere
    skip_authorization
    head :not_found
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

module GoMealMatchesHelper
  # Placeholder covers, until restaurants carry a photo of their own.
  # See the follow-up US: fetch the real photo from Google Places and attach
  # it with Active Storage. This helper is meant to be deleted then.
  COVER_PHOTOS = %w[
    restaurants/cover-1.jpg
    restaurants/cover-2.jpg
    restaurants/cover-3.jpg
    restaurants/cover-4.jpg
    restaurants/cover-5.jpg
  ].freeze

  def restaurant_cover_photo(restaurant)
    # The id picks the photo, so one restaurant always shows the same cover
    # while two cards in a row look different.
    COVER_PHOTOS[restaurant.id % COVER_PHOTOS.size]
  end
end

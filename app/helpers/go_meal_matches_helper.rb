module GoMealMatchesHelper
  # Emoji shown on the card cover, picked from the restaurant Google "types".
  CUISINE_EMOJI = {
    "pizza"        => "🍕",
    "italian"      => "🍝",
    "sushi"        => "🍣",
    "japanese"     => "🍣",
    "korean"       => "🍲",
    "chinese"      => "🥡",
    "thai"         => "🍜",
    "vietnamese"   => "🍜",
    "indian"       => "🍛",
    "ramen"        => "🍜",
    "noodle"       => "🍜",
    "burger"       => "🍔",
    "fast_food"    => "🍔",
    "american"     => "🍔",
    "mexican"      => "🌮",
    "seafood"      => "🦐",
    "steak"        => "🥩",
    "barbecue"     => "🍖",
    "french"       => "🥐",
    "bakery"       => "🥖",
    "cafe"         => "☕️",
    "coffee"       => "☕️",
    "breakfast"    => "🍳",
    "brunch"       => "🥞",
    "vegetarian"   => "🥗",
    "vegan"        => "🥗",
    "dessert"      => "🍰",
    "ice_cream"    => "🍨",
    "bar"          => "🍸",
    "pub"          => "🍺",
    "brewery"      => "🍺",
    "wine"         => "🍷"
  }.freeze

  # Placeholder cover photos, cycled per restaurant so the same one always
  # gets the same photo, while different ones look different in the deck.
  RESTAURANT_COVER_PHOTOS = %w[
    restaurants/cover-1.jpg
    restaurants/cover-2.jpg
    restaurants/cover-3.jpg
    restaurants/cover-4.jpg
    restaurants/cover-5.jpg
  ].freeze

  def restaurant_cuisine_emoji(restaurant)
    types = Array(restaurant.types).map(&:to_s)
    match = CUISINE_EMOJI.find { |keyword, _| types.any? { |t| t.include?(keyword) } }
    match ? match.last : "🍽️"
  end

  def restaurant_cover_photo(restaurant)
    RESTAURANT_COVER_PHOTOS[restaurant.id % RESTAURANT_COVER_PHOTOS.size]
  end

  # First readable "type" turned into a human label ("korean_restaurant" -> "Korean").
  def restaurant_category_label(restaurant)
    raw = Array(restaurant.types).find { |t| t.to_s.exclude?("point_of_interest") && t.to_s.exclude?("establishment") }
    return "Restaurant" if raw.blank?

    raw.to_s.sub(/_?restaurant\z/, "").tr("_", " ").strip.capitalize.presence || "Restaurant"
  end
end

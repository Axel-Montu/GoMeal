class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :go_meal_matches, dependent: :destroy

  WALK_SPEED_M_PER_MIN = 80    # ~4.8 km/h, marche urbaine réaliste
  DETOUR_FACTOR        = 1.3   # rues ≠ ligne droite

  def max_radius_search_meters
    return nil if max_walking_minutes.blank?
    (WALK_SPEED_M_PER_MIN * max_walking_minutes / DETOUR_FACTOR).round
  end
end

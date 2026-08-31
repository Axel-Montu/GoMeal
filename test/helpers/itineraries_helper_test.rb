require "test_helper"

class ItinerariesHelperTest < ActionView::TestCase
  test "rounds the walking time up to the next minute" do
    # 1. 611.7 seconds is 10.2 minutes: a user told "10 min" who takes 11
    #    has been lied to
    assert_equal "11 min", walking_time(611.7)
  end

  test "shows the distance in metres, without decimals" do
    assert_equal "842 m", walking_distance(842.3)
  end

  test "shows the distance in kilometres past a thousand metres" do
    assert_equal "1,2 km", walking_distance(1240.0)
  end

  test "gives the arrival time as now plus the walk" do
    # 2. Freeze the clock: a test that depends on the real time fails at midnight
    travel_to Time.zone.parse("2026-08-28 12:30:00") do
      assert_equal "12:41", arrival_time(611.7)
    end
  end

  test "shows the meal time from the user's preference" do
    assert_equal "30 min", meal_time(30)
  end

  test "totals the walk there, the meal, and the walk back" do
    # 240 seconds each way is 4 minutes, plus 30 at the table
    assert_equal "38 min", total_time(240.0, 30)
  end
end

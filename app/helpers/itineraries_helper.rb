module ItinerariesHelper
  # Walking time, rounded UP: someone told "10 min" who takes 11 has been lied to
  def walking_time(seconds)
    "#{(seconds / 60.0).ceil} min"
  end

  # Metres below a kilometre, kilometres above — nobody reads "1240 m"
  def walking_distance(metres)
    return "#{metres.round} m" if metres < 1000

    kilometres = (metres / 1000.0).round(1)
    "#{number_with_precision(kilometres, precision: 1, separator: ',')} km"
  end

  # Now plus the walking time AS DISPLAYED: announcing 11 minutes and an arrival
  # at 12:40 would contradict itself
  def arrival_time(seconds)
    minutes = (seconds / 60.0).ceil
    I18n.l(Time.zone.now + minutes.minutes, format: "%H:%M")
  end
end

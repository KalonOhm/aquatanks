require "test_helper"

class UnitsHelperTest < ActionView::TestCase
  # stands in for ApplicationHelper#preferences
  def preferences = @preferences

  def size_for(text, units)
    @preferences = User.new(units:)
    species_size(Species.new(size: text))
  end

  test "picks the preferred half of each measurement pair" do
    assert_equal "33 cm", size_for("33 cm (13.0 in)", "metric")
    assert_equal "13.0 in", size_for("33 cm (13.0 in)", "us")
    assert_equal "12 in", size_for("12 in (30.5 cm)", "us")
    assert_equal "1.6–2.0 in", size_for("4–5 cm (1.6–2.0 in)", "us")
    assert_equal "15 cm fem / 10 cm male", size_for("15 cm (5.9 in) fem / 10 cm (3.9 in) male", "metric")
  end

  test "leaves other formats as written" do
    assert_equal "15\"", size_for("15\"", "metric")
    assert_equal "2-2.5 cm", size_for("2-2.5 cm", "us")
  end

  test "tank volume" do
    tank = Aquarium.new(size: 20)
    @preferences = User.new(units: "us")
    assert_equal "20 gallons", tank_volume(tank)
    @preferences = User.new(units: "metric")
    assert_equal "75.7 L", tank_volume(tank)
  end

  test "Units round-trips litres through gallons" do
    gallons = Units.to_gallons("100", "metric")
    assert_equal 100, Units.from_gallons(gallons, "metric").round
    assert_equal 20, Units.to_gallons("20", "us")
  end
end

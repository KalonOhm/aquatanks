require "test_helper"

class SpeciesTest < ActiveSupport::TestCase
  test "search finds a species by any of its names" do
    tetra = species(:one)
    assert_includes Species.search("Black tetra"), tetra
    assert_includes Species.search("skirt"), tetra
    assert_includes Species.search("Gymnocorymbus"), tetra
    assert_not_includes Species.search("skirt"), species(:two)
  end

  test "search matches each word separately, in any order, across names" do
    tetra = species(:one)
    assert_includes Species.search("tetra black"), tetra
    assert_includes Species.search("bla ternetzi"), tetra       # common name + scientific name
    assert_includes Species.search("SKIRT gymno"), tetra        # alias + scientific name
    assert_not_includes Species.search("black fern"), tetra     # every word has to match
  end

  test "needs a common or scientific name, nothing else" do
    assert Species.new(taxonomic_name: "Anubias barteri").valid?
    assert Species.new(common_name: "Anubias").valid?
    assert_not Species.new.valid?
  end

  test "deleting a species removes it from tanks" do
    aquaria(:one).aquarium_species.create!(species: species(:one), count: 2)
    assert_difference("AquariumSpecies.count", -1) { species(:one).destroy }
  end

  test "alias_list replaces the aliases" do
    tetra = species(:one)
    tetra.update!(alias_list: "skirt tetra, black widow tetra, , skirt tetra")
    assert_equal ["skirt tetra", "black widow tetra"], tetra.reload.alias_names
  end
end

require File.dirname(__FILE__) + '/abstract_unit'

# These tests will only pass if run independantly.
# /usr/bin/ruby -Ilib:lib "/usr/lib/ruby/gems/1.8/gems/rake-0.7.3/lib/rake/rake_test_loader.rb" "test/acts_as_ordered_tree2_test.rb"
#
# As soon as 'fixtures' are used, the tests fail.
#
class ActsAsOrderedTree2Test < Test::Unit::TestCase
  #fixtures :people

  def test_create_with_position_method_1
    people = reload_test_tree
    # method 1
    assert people[2].children << Person.new(:position => 3, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[4],people[22],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3 ,people[22].position_in_list
    assert_equal 4, people[9].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_2
    people = reload_test_tree
    # method 2
    assert Person.create(:parent_id => people[2].id, :position => 2, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[22],people[4],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[22].position_in_list
    assert_equal 3 ,people[4].position_in_list
    assert_equal 4, people[9].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_3
    people = reload_test_tree
    # method 3
    assert people[2].children.create(:position => 4, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[4],people[9],people[22],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3, people[9].position_in_list
    assert_equal 4 ,people[22].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_4
    people = reload_test_tree
    # method 4 (new 'root')
    assert Person.create(:position => 2, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[0],people[22],people[11]], Person.roots
    assert_equal 1, people[0].position_in_list
    assert_equal 2 ,people[22].position_in_list
    assert_equal 3 ,people[11].position_in_list
  end

  def test_create_with_invalid_position
    # invalid positions go to bottom of the list
    people = reload_test_tree
    person_23 = people[2].children.create(:position => 15, :name => 'Person_23')
    assert_equal 5, person_23.position_in_list
  end

private
  # Test Tree
  #
  # people_001
  #   \_ people_002
  #   \_ people_003
  #   |    \_ people_004
  #   |    \_ people_005
  #   |    |   \_ people_008
  #   |    |   \_ people_009
  #   |    \_ people_010
  #   |    \_ people_011
  #   \_ people_006
  #   \_ people_007
  #   |
  #   |
  # people_012
  #   \_ people_013
  #   \_ people_014
  #   |    \_ people_015
  #   |    \_ people_016
  #   |    |   \_ people_019
  #   |    |   \_ people_020
  #   |    \_ people_021
  #   |    \_ people_022
  #   \_ people_017
  #   \_ people_018
  #
  #
  #  +----+-----------+----------+-----------+
  #  | id | parent_id | position | name      |
  #  +----+-----------+----------+-----------+
  #  |  1 |         0 |        1 | Person_1  |
  #  |  2 |         1 |        1 | Person_2  |
  #  |  3 |         1 |        2 | Person_3  |
  #  |  4 |         3 |        1 | Person_4  |
  #  |  5 |         3 |        2 | Person_5  |
  #  |  6 |         1 |        3 | Person_6  |
  #  |  7 |         1 |        4 | Person_7  |
  #  |  8 |         5 |        1 | Person_8  |
  #  |  9 |         5 |        2 | Person_9  |
  #  | 10 |         3 |        3 | Person_10 |
  #  | 11 |         3 |        4 | Person_11 |
  #  | 12 |         0 |        2 | Person_12 |
  #  | 13 |        12 |        1 | Person_13 |
  #  | 14 |        12 |        2 | Person_14 |
  #  | 15 |        14 |        1 | Person_15 |
  #  | 16 |        14 |        2 | Person_16 |
  #  | 17 |        12 |        3 | Person_17 |
  #  | 18 |        12 |        4 | Person_18 |
  #  | 19 |        16 |        1 | Person_19 |
  #  | 20 |        16 |        2 | Person_20 |
  #  | 21 |        14 |        3 | Person_21 |
  #  | 22 |        14 |        4 | Person_22 |
  #  +----+-----------+----------+-----------+
  #
  def reload_test_tree
    Person.delete_all
    people = []
    i = 1
    people << Person.create(:name => "Person_#{i}")
    [0,2,0,4,2,-1,11,13,11,15,13].each do |n|
      if n == -1
        i = i.next
        people << Person.create(:name => "Person_#{i}")
      else
        2.times do
          i = i.next
          people << people[n].children.create(:name => "Person_#{i}")
        end
      end
    end
    return people
  end
end

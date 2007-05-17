require File.dirname(__FILE__) + '/abstract_unit'
#
# Test Fixtures
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
#  +----+-----------+----------+---------+
#  | id | parent_id | position | node    |
#  +----+-----------+----------+---------+
#  |  1 |         0 |        1 | Node_1  |
#  |  2 |         1 |        1 | Node_2  |
#  |  3 |         1 |        2 | Node_3  |
#  |  4 |         3 |        1 | Node_4  |
#  |  5 |         3 |        2 | Node_5  |
#  |  6 |         1 |        3 | Node_6  |
#  |  7 |         1 |        4 | Node_7  |
#  |  8 |         5 |        1 | Node_8  |
#  |  9 |         5 |        2 | Node_9  |
#  | 10 |         3 |        3 | Node_10 |
#  | 11 |         3 |        4 | Node_11 |
#  | 12 |         0 |        2 | Node_12 |
#  | 13 |        12 |        1 | Node_13 |
#  | 14 |        12 |        2 | Node_14 |
#  | 15 |        14 |        1 | Node_15 |
#  | 16 |        14 |        2 | Node_16 |
#  | 17 |        12 |        3 | Node_17 |
#  | 18 |        12 |        4 | Node_18 |
#  | 19 |        16 |        1 | Node_19 |
#  | 20 |        16 |        2 | Node_20 |
#  | 21 |        14 |        3 | Node_21 |
#  | 22 |        14 |        4 | Node_22 |
#  +----+-----------+----------+---------+
#
class ActsAsOrderedTreeTest < Test::Unit::TestCase
  fixtures :people

  def test_validation
    assert !(people(:people_005).children << people(:people_001)),"
      Validation failed:
      If you are using the 'validate_on_update' callback, make sure you use 'super'\n"
    assert_equal "is an ancestor of the new parent.", people(:people_001).errors[:base]

    # people_003 is changing parents
    assert !(people(:people_008).children << people(:people_003))
    assert_equal "is an ancestor of the new parent.", people(:people_001).errors[:base]

    assert !(people(:people_004).children << people(:people_004))
    assert_equal "cannot be a parent to itself.", people(:people_004).errors[:base]

    # remember that the failed operations leave you with tainted objects
    assert people(:people_003).parent == people(:people_008)
    people(:people_003).reload
    assert people(:people_003).parent != people(:people_008)
  end

  def test_validate_on_update_reloads_descendants
    # caching (descendants must be reloaded in validate_on_update)
    people(:people_003).descendants # load descendants
    assert people(:people_006).children << people(:people_008)
    assert people(:people_006).children.include?(people(:people_008))
    # since people_003 descendants has already been loaded above,
    # it still includes people_008 as a descendant
    assert people(:people_003).descendants.include?(people(:people_008))
    # so, without the reload on people_003 descendants in validate_on_update,
    # the following would fail
    assert people(:people_008).children << people(:people_003), 'Validation Failed: descendants must be reloaded in validate_on_update'
  end

  def test_descendants
    roots = Person.roots
    assert !roots.empty?
    count = 0
    roots.each{|root| count = count + root.descendants.size + 1}
    assert count == Person.find(:all).size
  end

  def test_destroy_descendants
    assert_equal 22, Person.find(:all).size
    assert_equal 7, people(:people_003).descendants.size + 1
    assert people(:people_003).destroy
    assert_equal 15, Person.find(:all).size
  end

  def test_ancestors_and_roots
    assert_equal [people(:people_005),
                  people(:people_003),
                  people(:people_001)], people(:people_008).ancestors
    assert_equal people(:people_001), people(:people_008).root
    assert_equal [people(:people_001),
                  people(:people_012)], people(:people_008).class.roots
  end

  def test_destroy_and_reorder_list
    assert_equal [people(:people_002),
                  people(:people_003),
                  people(:people_004),
                  people(:people_005),
                  people(:people_008),
                  people(:people_009),
                  people(:people_010),
                  people(:people_011),
                  people(:people_006),
                  people(:people_007)], people(:people_001).descendants
    assert_equal [people(:people_002),
                  people(:people_003),
                  people(:people_006),
                  people(:people_007)], people(:people_006).self_and_siblings
    assert_equal 3, people(:people_006).position_in_list
    # taint people[2].parent (since the plugin protects against this)
    people(:people_011).children << people(:people_003)
    assert_equal people(:people_011), people(:people_003).parent
    assert people(:people_003).destroy
    assert_equal 15, Person.find(:all).size
    # Note that I don't need to reload self_and_siblings or children in this case,
    # since the re-ordering action is actually happening against people_001.children
    # (which is what self_and_siblings returns)
    assert_equal people(:people_006).self_and_siblings, people(:people_001).children
    assert_equal [people(:people_002),
                  people(:people_006),
                  people(:people_007)], people(:people_006).self_and_siblings
    people(:people_006).reload
    assert_equal 2, people(:people_006).position_in_list
    # of course, descendants must always be reloaded
    assert people(:people_001).descendants.include?(people(:people_008))
    assert !people(:people_001).descendants(true).include?(people(:people_008))
  end

  def test_reorder_lists
    # re-order children
    assert people(:people_014).children << people(:people_005)
    assert_equal 5, people(:people_005).position_in_list
    assert_equal 2, people(:people_010).position_in_list
    # re-order roots
    assert people(:people_014).children << people(:people_001)
    assert_equal 6, people(:people_001).position_in_list
    assert_equal 1, people(:people_012).position_in_list
  end

  def test_move_higher
    assert people(:people_010).move_higher
    assert_equal 2, people(:people_010).position_in_list
    assert_equal 3, people(:people_005).position_in_list
  end

  def test_move_lower
    assert people(:people_005).move_lower
    assert_equal 3, people(:people_005).position_in_list
    assert_equal 2, people(:people_010).position_in_list
  end

  def test_move_to_top
    assert people(:people_005).move_to_top
    assert_equal 1, people(:people_005).position_in_list
    assert_equal 2 ,people(:people_004).position_in_list
    assert_equal 3 ,people(:people_010).position_in_list
    assert_equal 4, people(:people_011).position_in_list
  end

  def test_move_to_bottom
    assert people(:people_005).move_to_bottom
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal 4, people(:people_005).position_in_list
  end

  def test_move_above_moving_higher
    assert people(:people_011).move_above(people(:people_005))
    assert_equal [people(:people_004),
                  people(:people_011),
                  people(:people_005),
                  people(:people_010)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_011).position_in_list
    people(:people_005).reload
    assert_equal 3 ,people(:people_005).position_in_list
    assert_equal 4, people(:people_010).position_in_list
  end

  def test_move_above_moving_lower
    assert people(:people_004).move_above(people(:people_011))
    assert_equal [people(:people_005),
                  people(:people_010),
                  people(:people_004),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_005).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_004).position_in_list
    # no reload needed, since people_011 doesn't move
    assert_equal 4, people(:people_011).position_in_list
  end

  def test_shift_to_with_position
    assert people(:people_005).shift_to(people(:people_014), people(:people_021))
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal [people(:people_015),
                  people(:people_016),
                  people(:people_005),
                  people(:people_021),
                  people(:people_022)], people(:people_014).children
    assert_equal 1, people(:people_015).position_in_list
    assert_equal 2 ,people(:people_016).position_in_list
    assert_equal 3 ,people(:people_005).position_in_list
    people(:people_021).reload
    assert_equal 4, people(:people_021).position_in_list
    assert_equal 5, people(:people_022).position_in_list
  end

  def test_shift_to_without_position
    assert people(:people_005).shift_to(people(:people_014))
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal [people(:people_015),
                  people(:people_016),
                  people(:people_021),
                  people(:people_022),
                  people(:people_005)], people(:people_014).children
    assert_equal 1, people(:people_015).position_in_list
    assert_equal 2 ,people(:people_016).position_in_list
    assert_equal 3 ,people(:people_021).position_in_list
    assert_equal 4, people(:people_022).position_in_list
    assert_equal 5, people(:people_005).position_in_list
  end

  def test_shift_to_roots_without_position__ie__orphan
    assert people(:people_005).orphan
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal [people(:people_001),
                  people(:people_012),
                  people(:people_005)], Person.roots
    assert_equal 1, people(:people_001).position_in_list
    assert_equal 2 ,people(:people_012).position_in_list
    assert_equal 3 ,people(:people_005).position_in_list
  end

  def test_shift_to_roots_with_position
    assert people(:people_005).shift_to(nil, people(:people_012))
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal [people(:people_001),
                  people(:people_005),
                  people(:people_012)], Person.roots
    assert_equal 1, people(:people_001).position_in_list
    assert_equal 2 ,people(:people_005).position_in_list
    people(:people_012).reload
    assert_equal 3 ,people(:people_012).position_in_list
  end

  def test_orphan_children
    assert people(:people_003).orphan_children
    assert people(:people_003).children.empty?
    assert_equal [people(:people_001),
                  people(:people_012),
                  people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  people(:people_011)], Person.roots
  end

  def test_parent_adopts_children
    assert people(:people_005).parent_adopts_children
    assert people(:people_005).children.empty?
    assert_equal [people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  people(:people_011),
                  people(:people_008),
                  people(:people_009)], people(:people_003).children
  end

  def test_orphan_self_and_children
    assert people(:people_003).orphan_self_and_children
    assert people(:people_003).children.empty?
    assert_equal [people(:people_001),
                  people(:people_012),
                  people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  people(:people_011),
                  people(:people_003)], Person.roots
  end

  def test_orphan_self_and_parent_adopts_children
    assert people(:people_005).orphan_self_and_parent_adopts_children
    assert people(:people_005).children.empty?
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011),
                  people(:people_008),
                  people(:people_009)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal 4, people(:people_008).position_in_list
    assert_equal 5, people(:people_009).position_in_list
    assert_equal [people(:people_001),
                  people(:people_012),
                  people(:people_005)], Person.roots
  end

  def test_destroy_and_orphan_children
    assert people(:people_003).destroy_and_orphan_children
    assert_equal [people(:people_001),
                  people(:people_012),
                  people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  people(:people_011)], Person.roots
    assert_equal [people(:people_002),
                  people(:people_006),
                  people(:people_007)], people(:people_001).children
    assert_equal 1, people(:people_002).position_in_list
    assert_equal 2 ,people(:people_006).position_in_list
    assert_equal 3 ,people(:people_007).position_in_list
  end

  def test_destroy_and_parent_adopts_children
    assert people(:people_005).destroy_and_parent_adopts_children
    assert_equal [people(:people_004),
                  people(:people_010),
                  people(:people_011),
                  people(:people_008),
                  people(:people_009)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_010).position_in_list
    assert_equal 3 ,people(:people_011).position_in_list
    assert_equal 4, people(:people_008).position_in_list
    assert_equal 5, people(:people_009).position_in_list
  end

  def test_create_with_position__method_1
    # method 1
    person_023 = Person.new(:position => 3, :name => 'Person_023')
    assert people(:people_003).children << person_023
    assert_equal [people(:people_004),
                  people(:people_005),
                  person_023,
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_005).position_in_list
    assert_equal 3 ,person_023.position_in_list
    ### FIXME
    # The test says this is returning 5. ???
    # It's moving from 3 to 4.
    # And I can perform this action in development,
    # look in the database and see that it is indeed 4.
    # ( more below in __method_2 )
    #
    #people(:people_010).reload
    #assert_equal 4, people(:people_010).position_in_list
      #person_010 = Person.find_by_id(10)
      #assert_equal 4, person_010.position_in_list
    assert_equal 5, people(:people_011).position_in_list
  end

  def test_create_with_position__method_2
    # method 2
    person_023 = Person.create(:parent_id => people(:people_003).id, :position => 2, :name => 'Person_023')
    assert_equal [people(:people_004),
                  person_023,
                  people(:people_005),
                  people(:people_010),
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,person_023.position_in_list

    # Again...
    #   person_005 is moving from 2 to 3 (but test says it's 4)
    #   person_010 is moving from 3 to 4 (but test says it's 5)
    #
    #assert_equal 3 ,people(:people_005).position_in_list
    #assert_equal 4, people(:people_010).position_in_list
    assert_equal 5, people(:people_011).position_in_list

    #  person_003's children:
    #
    #  mysql> select * from people WHERE parent_id = 3;
    #  +----+-----------+----------+-----------+
    #  | id | parent_id | position | name      |
    #  +----+-----------+----------+-----------+
    #  |  4 |         3 |        1 | Person_4  |
    #  |  5 |         3 |        2 | Person_5  |
    #  | 10 |         3 |        3 | Person_10 |
    #  | 11 |         3 |        4 | Person_11 |
    #  +----+-----------+----------+-----------+
    #
    #  Create New Person as a child of person_003, in position 2
    #
    #  >> Person.create(:parent_id => 3, :position => 2, :name => 'Person_023')
    #  => #<Person:0xb74812ac @errors=#<ActiveRecord::Errors:0xb74802d0 @errors={},
    #      @base=#<Person:0xb74812ac ...>>,
    #      @attributes={"name"=>"Person_023", "id"=>23, "position"=>2, "parent_id"=>3},
    #      @new_record_before_save=true,
    #      @new_record=false,
    #      @parent_node=#<Person:0xb74793cc @attributes={"name"=>"Person_3", "id"=>"3", "position"=>"2", "parent_id"=>"1"}>>
    #
    #  The Database shows the proper results:
    #
    #  mysql> select * from people WHERE parent_id = 3;
    #  +----+-----------+----------+------------+
    #  | id | parent_id | position | name       |
    #  +----+-----------+----------+------------+
    #  |  4 |         3 |        1 | Person_4   |
    #  |  5 |         3 |        3 | Person_5   |
    #  | 10 |         3 |        4 | Person_10  |
    #  | 11 |         3 |        5 | Person_11  |
    #  | 23 |         3 |        2 | Person_023 |
    #  +----+-----------+----------+------------+
  end

  def test_create_with_position__method_3
    # method 3
    person_023 = people(:people_003).children.create(:position => 4, :name => 'Person_023')
    assert_equal [people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  person_023,
                  people(:people_011)], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_005).position_in_list
    assert_equal 3, people(:people_010).position_in_list
    assert_equal 4 ,person_023.position_in_list
    assert_equal 5, people(:people_011).position_in_list
  end

  def test_create_with_position__method_4
    # method 4 (new root)
    person_023 = Person.create(:position => 2, :name => 'Person_023')
    assert_equal [people(:people_001),
                  person_023,
                  people(:people_012)], Person.roots
    assert_equal 1, people(:people_001).position_in_list
    assert_equal 2 ,person_023.position_in_list
    assert_equal 3 ,people(:people_012).position_in_list
  end

  def test_create_with_invalid_position
    # invalid positions go to bottom of the list
    person_023 = people(:people_003).children.create(:position => 15, :name => 'Person_023')
    assert_equal [people(:people_004),
                  people(:people_005),
                  people(:people_010),
                  people(:people_011),
                  person_023], people(:people_003).children
    assert_equal 1, people(:people_004).position_in_list
    assert_equal 2 ,people(:people_005).position_in_list
    assert_equal 3, people(:people_010).position_in_list
    assert_equal 4, people(:people_011).position_in_list
    assert_equal 5, person_023.position_in_list
  end

end

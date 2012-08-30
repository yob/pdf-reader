# coding: utf-8

require File.dirname(__FILE__) + "/spec_helper"

describe PDF::Reader, "column specs" do

  it "should correctly read page 1" do
    filename = pdf_spec_file("column_integration")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(1)
      # the first page has one centered header
      # followed by full width text
      # then followed by two column text, below is the last of the one column
      # text followed by the two column text
      col_text = Regexp::new(<<-TEXT, Regexp::MULTILINE)
\s*esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui
\s*officia deserunt mollit anim id est laborum.
\s*Lorem ipsum dolor sit amet, consectetur adipisic-\s{20,80}adipisicing elit, sed do eiusmod tempor incididunt
\s*ing elit, sed do eiusmod tempor incididunt ut labore\s{20,80}ut labore et dolore magna aliqua. Ut enim ad minim
\s*et dolore magna aliqua. Ut enim ad minim veniam,\s{20,80}veniam, quis nostrud exercitation ullamco laboris
\s*quis nostrud exercitation ullamco laboris nisi ut\s{20,80}nisi ut aliquip ex ea commodo consequat. Duis aute
\s*aliquip ex ea commodo consequat. Duis aute irure\s{20,80}irure dolor in reprehenderit in voluptate velit esse
      TEXT
      ft = page.formatted_text()
      ft.should =~ /Some Headline/
      ft.should =~ /ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu/
      ft.should =~ col_text

      # The following lines are in the second column, and their position with in the
      # string (from the left) should all be at the same spot
      match_pos_1 = find_position_of_match(ft, /\s{10}adipisicing elit, sed do eiusmod tempor incididunt$/)
      match_pos_2 = find_position_of_match(ft, /\s{10}ut labore et dolore magna aliqua. Ut enim ad minim$/)
      match_pos_3 = find_position_of_match(ft, /\s{10}veniam, quis nostrud exercitation ullamco laboris$/)
      match_pos_4 = find_position_of_match(ft, /\s{10}nisi ut aliquip ex ea commodo consequat. Duis aute$/)
      match_pos_5 = find_position_of_match(ft, /\s{10}irure dolor in reprehenderit in voluptate velit esse$/)

      match_pos_1.should eql(match_pos_2)
      match_pos_1.should eql(match_pos_3)
      match_pos_1.should eql(match_pos_4)
      match_pos_1.should eql(match_pos_5)
    end
  end

  it "should correctly read page 2" do
    filename = pdf_spec_file("column_integration")

    PDF::Reader.open(filename) do |reader|
      page = reader.page(2)
      # the second page has three columns of text with a
      # black rectangle in the middle of the page interrupting the entire
      # second column
      three_to_two_cols = Regexp::new(<<-TEXT, Regexp::MULTILINE)
\s*fugiat nulla pariatur. Excepteur\s{20,40}sunt in culpa qui officia deserunt\s{20,40}sum dolor sit amet, consectetur
\s*sint occaecat cupidatat non proi-\s{20,40}mollit anim id est laborum. Lo-\s{20,40}adipisicing elit, sed do eiusmod
\s*dent, sunt in culpa qui officia de-\s{20,40}rem ipsum dolor sit amet, con-\s{20,40}tempor incididunt ut labore et
\s*serunt mollit anim id est\s{100,120}dolore magna aliqua. Ut
\s*laborum. Lorem ipsum\s{100,120}enim ad minim veniam,
\s*dolor sit amet, consecte-\s{100,120}quis nostrud exercitation
      TEXT
      two_to_three_cols = Regexp::new(<<-TEXT2, Regexp::MULTILINE)
\s*pariatur. Excepteur sint\s{100,120}lor sit amet, consectetur
\s*occaecat cupidatat non\s{100,120}adipisicing elit, sed do
\s*proident, sunt in culpa\s{100,120}eiusmod tempor incidid-
\s*qui officia deserunt mollit anim\s{20,40}sectetur adipisicing elit, sed do\s{20,40}unt ut labore et dolore magna ali-
\s*id est laborum. Lorem ipsum do-\s{20,40}eiusmod tempor incididunt ut\s{20,40}qua. Ut enim ad minim veniam,
\s*lor sit amet, consectetur adipisic-\s{20,40}labore et dolore magna aliqua. Ut\s{20,40}quis nostrud exercitation ullamco
      TEXT2
      ft = page.formatted_text()
      ft.should =~ three_to_two_cols
      ft.should =~ two_to_three_cols

      # The following lines are in the second column of the page prior to the interruption
      col2_1   = find_position_of_match(ft, /\s{10}occaecat cupidatat non proident,\s{10}/)
      col2_2   = find_position_of_match(ft, /\s{10}sunt in culpa qui officia deserunt\s{10}/)
      col2_3   = find_position_of_match(ft, /\s{10}mollit anim id est laborum. Lo-\s{10}/)
      col2_4   = find_position_of_match(ft, /\s{10}rem ipsum dolor sit amet, con-\s{10}/)

      # The following lines are in the third column of the page prior to the interruption
      col3_a_1 = find_position_of_match(ft, /\s{10}anim id est laborum. Lorem ip-$/)
      col3_a_2 = find_position_of_match(ft, /\s{10}sum dolor sit amet, consectetur$/)
      col3_a_3 = find_position_of_match(ft, /\s{10}adipisicing elit, sed do eiusmod$/)
      col3_a_4 = find_position_of_match(ft, /\s{10}tempor incididunt ut labore et$/)

      #the following lines are in the third column of the page _during_ the interruption
      col3_b_1 = find_position_of_match(ft, /\s{10}dolore magna aliqua. Ut$/)
      col3_b_2 = find_position_of_match(ft, /\s{10}enim ad minim veniam,$/)
      col3_b_3 = find_position_of_match(ft, /\s{10}quis nostrud exercitation$/)
      col3_b_4 = find_position_of_match(ft, /\s{10}ullamco laboris nisi ut$/)

      col2_1.should eql(col2_2)
      col2_1.should eql(col2_3)
      col2_1.should eql(col2_4)

      col3_a_1.should eql(col3_a_2)
      col3_a_1.should eql(col3_a_3)
      col3_a_1.should eql(col3_a_4)

      col3_b_1.should eql(col3_b_2)
      col3_b_1.should eql(col3_b_3)
      col3_b_1.should eql(col3_b_4)

    end
  end

  def find_position_of_match(source, regex)
    source.each_line do |line|
      if x_pos = line =~ regex
        return x_pos
      end
    end
  end

end
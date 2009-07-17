require File.join(File.dirname(__FILE__), 'test_helper')

class Bond::AgentTest < Test::Unit::TestCase
  before(:all) {|e| Bond.debrief(:readline_plugin=>valid_readline_plugin) }

  context "InvalidAgent" do
    test "prints error if no action given for mission" do
      capture_stderr { Bond.complete :on=>/blah/ }.should =~ /Invalid mission/
    end

    test "prints error if no condition given" do
      capture_stderr { Bond.complete {|e| []} }.should =~ /Invalid mission/
    end
  
    test "prints error if invalid condition given" do
      capture_stderr { Bond.complete(:on=>'blah') {|e| []} }.should =~ /Invalid mission/
    end
    
    test "prints error if setting mission fails unpredictably" do
      Bond.agent.expects(:complete).raises(ArgumentError)
      capture_stderr { Bond.complete(:on=>/blah/) {|e| [] } }.should =~ /Mission setup failed/
    end
  end

  context "Agent" do
    before(:each) {|e| Bond.agent.instance_eval("@missions = []") }

    test "chooses default mission if no missions match" do
      Bond.complete(:on=>/bling/) {|e| [] }
      Bond.agent.default_mission.expects(:execute)
      complete 'blah'
    end

    test "chooses default mission if internal processing fails" do
      Bond.complete(:on=>/bling/) {|e| [] }
      Bond.agent.expects(:find_mission).raises
      Bond.agent.default_mission.expects(:execute)
      complete('bling')
    end

    test "prints error if action generates failure" do
      Bond.complete(:on=>/bling/) {|e| raise "whoops" }
      capture_stderr { complete('bling') }.should =~ /bling.*whoops/m
    end
  end

  context "spy" do
    before(:all) {
      Bond.reset; Bond.complete(:on=>/end$/) { [] }; Bond.complete(:method=>'the') { %w{spy who loved me} }
      Bond.complete(:object=>"Symbol")
    }

    test "detects basic mission" do
      capture_stdout { Bond.spy('the end')}.should =~ /end/
    end

    test "detects object mission" do
      capture_stdout { Bond.spy(':dude.i')}.should =~ /object.*Symbol.*dude\.id/m
    end

    test "detects method mission" do
      capture_stdout { Bond.spy('the ')}.should =~ /method.*the.*loved/m
    end

    test "detects no mission" do
      capture_stdout { Bond.spy('blah')}.should =~ /Doesn't match/
    end
  end
end

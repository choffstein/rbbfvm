Feature: Move tape pointer right
	In order to ensure tape adds right
	
	Scenario: Move tape pointer right when already at zero
		Given I have evaluated '>' in the virtual machine
		Then the tape pointer should be 1
			And the tape size should be 2
			And the tape value at 0 should be 0
			And the tape value at 1 should be 0
Feature: Decrement tape value
	In order to ensure tape value decrements by 1
	
	Scenario: Move tape pointer right when already at zero
		Given I have evaluated '-' in the virtual machine
		Then the tape pointer should be 0
			And the tape size should be 1
			And the tape value at 0 should be -1
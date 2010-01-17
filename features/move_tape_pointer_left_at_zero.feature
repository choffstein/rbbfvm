Feature: Move tape pointer left
	In order to ensure tape shifts right
	
	Scenario: Move tape pointer left when already at zero
		Given I have evaluated '<' in the virtual machine
		Then the tape pointer should be 0
			And the tape size should be 2
			And the tape value at 0 should be 0
			And the tape value at 1 should be 0

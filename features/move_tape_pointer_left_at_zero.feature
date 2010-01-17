Feature: Move tape pointer left
	In order to ensure tape shifts right
	

	Scenario: Move tape pointer left when already at zero
		Given I have entered '<' into the virtual machine
		And I have executed the script
		Then the tape pointer should be at 0
		And the tape size should be 2
		And the tape value at 0 should be 0
		And the tape value at 1 should be 0

# encoding: utf-8
require 'spec/expectations'
require 'cucumber/formatter/unicode'

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'vm'

Before do
	@vm = RbBFVM::VM.new
end

After do
end

Given /I have evaluated '([\[\]<>+\-,.]*)' in the virtual machine/ do |c|
  @vm.evaluate(c)
end

Given /I have interpreted '([\[\]<>+\-,.]*)' in the virtual machine/ do |c|
  @vm.interpret(c)
end

When /I step the virtual machine/ do
  @vm.step
end

Then /the tape pointer should be (.*)/ do |result|
  @vm.tape_pointer.should == result.to_i
end

And /the tape value at (\d*) should be (\d*)/ do |location, result|
  @vm.tape[location.to_i].should == result.to_i
end

And /the tape size should be (.*)/ do |result|
  @vm.tape.size.should == result.to_i
end
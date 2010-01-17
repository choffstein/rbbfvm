module RbBFVM
  class VM

    attr_reader :tape, :tape_pointer

    def initialize
      @tape = [0]
      @tape_pointer = 0
      
      @instructions = []
      @jump_locations = []
      @jump_table = {}
      @instruction_pointer = 0
      @break_points = {}
    end
    
    def interpret(string)
      characters = strip_string(string)
      
      characters.each_char { |character| 
        evaluate_character(character)
      }
      
      raise "Unclosed [ somewhere..." unless @jump_locations.size == 0
    end
    
    def execute
      begin
        while @instruction_pointer < @instructions.size
          if @break_points[@instruction_pointer]
            debug
          else 
            step
          end
        end
      rescue
        puts "Error raised @ #{@instruction_pointer} #{tape_to_string}"
        raise
      end
    end
    
    def evaluate(string) 
      characters = strip_string(string)
      
      characters.each_char { |character| 
        evaluate_character(character)
      }
      
      raise "Unclosed [ somewhere..." unless @jump_locations.size == 0
      
      execute
    end
    
    def debug
      input = ''
      
      puts "HIT BREAK POINT: "
      puts nearby_instructions_to_string
      puts tape_to_string
      
      while input != 'c' 
        print '> '
        input = gets.strip
        
        case input
        when 't'
          puts tape_to_string
        when 's'
          step(true)
        when 'c'
          step
        when 'i'
          puts nearby_instructions_to_string
        when 'r'
          print "Which break point? "
          bp = gets.strip.to_i
          @break_points[bp] = nil
        else
          puts "Not a valid input"
        end
      end
    end
    
    def step(verbose = false)
      instruction = @instructions[@instruction_pointer]
      
      if verbose
        puts "#{@instruction_pointer}: #{instruction.to_s}"
      end
      
      case instruction.code
      when Instruction::INCREMENT_TAPE
        @tape_pointer = @tape_pointer + 1
        
        # add to the end of our tape -- add more
        if @tape_pointer > (@tape.size-1)
          @tape << 0
        end
    
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::DECREMENT_TAPE
        @tape_pointer = @tape_pointer - 1
        
        #prepend our tape with a value so we don't 
        #go off the left of the tape
        if @tape_pointer < 0
          @tape.unshift(0)
          @tape_pointer = 0
        end
        
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::INCREMENT_VALUE
        @tape[@tape_pointer] = @tape[@tape_pointer] + 1
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::DECREMENT_VALUE
        @tape[@tape_pointer] = @tape[@tape_pointer] - 1
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::PRINT_CHARACTER
        print @tape[@tape_pointer].chr
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::GET_CHARACTER
        @tape[@tape_pointer] = STDIN.gets.to_i
        @instruction_pointer = @instruction_pointer + 1
        
      when Instruction::WHILE_LOOP
        if(@tape[@tape_pointer] == 0)
          @instruction_pointer = @jump_table[@instruction_pointer]
        else
          @instruction_pointer = @instruction_pointer + 1
        end
        
      when Instruction::JUMP
        if(@tape[@tape_pointer] != 0)
          @instruction_pointer = instruction.arguments
        else
          @instruction_pointer = @instruction_pointer + 1
        end
        
      else
        raise 'Illegal instruction type'
      end
    end
    
    def add_breakpoint(n)
      @break_points[n] = true
    end
  
  private
    
    class Instruction
      INCREMENT_TAPE = 1
      DECREMENT_TAPE = 2
      INCREMENT_VALUE = 3
      DECREMENT_VALUE = 4
      PRINT_CHARACTER = 5
      GET_CHARACTER = 6
      WHILE_LOOP = 7
      JUMP = 8
      
      attr_reader :code, :arguments
      
      def initialize(code, arguments = nil)
        @code = code
        @arguments = arguments
      end
      
      def to_s
        case @code
        when INCREMENT_TAPE
          return "Increment Tape (>)"
        when DECREMENT_TAPE
          return "Decrement Tape (<)"
        when INCREMENT_VALUE
          return "Increment Value (+)"
        when DECREMENT_VALUE
          return "Decrement Value (-)"
        when PRINT_CHARACTER
          return "Print Character (.)"
        when GET_CHARACTER
          return "Get Character (,)"
        when WHILE_LOOP
          return "While loop ([)"
        when JUMP
          return "End While Loop (]), Jump to #{@arguments}"
        end
      end
    end
    
    def strip_string(string)
      return string.gsub(/[^\[\]<>+\-,.]*/, "") #remove all whitespace from the string
    end
    
    def tape_to_string
      s = ""
      0.upto(@tape.size-1) { |i|
        if @tape_pointer == i
          s = s + "[>#{@tape[i]}<]"
        else
          s = s + "[#{@tape[i]}]"
        end
      }
      return s
    end
    
    def nearby_instructions_to_string
      begin_iterator = [0, @instruction_pointer-5].max
      end_iterator = [@instructions.size-1, @instruction_pointer+5].min
      
      s = ""
      ins = @instructions[begin_iterator..end_iterator]
      begin_iterator.upto(end_iterator) { |i|
        if i == @instruction_pointer
          s = s + "> "
        end
        s = s + "#{i}: #{ins[i-begin_iterator].to_s}\n"
      }
      
      return s
    end
    
    def evaluate_character(character) 
      case character
      when '>'
        @instructions << Instruction.new(Instruction::INCREMENT_TAPE)
      when '<'
        @instructions << Instruction.new(Instruction::DECREMENT_TAPE)
      when '+'
        @instructions << Instruction.new(Instruction::INCREMENT_VALUE)
      when '-'
        @instructions << Instruction.new(Instruction::DECREMENT_VALUE)
      when '.'
        @instructions << Instruction.new(Instruction::PRINT_CHARACTER)
      when ','
        @instructions << Instruction.new(Instruction::GET_CHARACTER)
      when '['
        @instructions << Instruction.new(Instruction::WHILE_LOOP)
        @jump_locations << (@instructions.size-1) #while loop instruction location
      when ']'
        # close the last {
        location = @jump_locations[-1]
        @jump_locations.slice!(-1)
        
        # we want to jump to that WHILE_LOOP location
        @instructions << Instruction.new(Instruction::JUMP, location)
        
        # put an entry in our jump table to let the while-loop instruction
        # at 'location' where to jump to if it is false -- one position
        # after the jump back
        
        @jump_table[location] = @instructions.size
      end
    end
  end
end

if ARGV.size == 0
  vm = RbBFVM::VM.new
  vm.interpret("++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.")
  vm.add_breakpoint(20)
  vm.execute
  
elsif ARGV.size == 1
  vm = RbBFVM::VM.new
  code = ''
  File.open(ARGV[0], "r") { |f|
    code = f.read
  }
  
  vm.evaluate(code)
end
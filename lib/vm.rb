module RbBFVM
  class VM
    
    def initialize
      @tape = [0]
      @tape_pointer = 0
      
      @instructions = []
      @jump_locations = []
      @jump_table = {}
    end
    
    def evaluate_string(string) 
      string.gsub(/[^\[\]<>+\-,.]*/, "") #remove all whitespace from the string
      
      string.each_char { |character| 
        evaluate_character(character)
      }
      
      throw "Unclosed [ somewhere..." unless @jump_locations.size == 0
      
      evaluate_instructions
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
    
    def evaluate_instructions
      instruction_pointer = 0
      while instruction_pointer < @instructions.size
        
        instruction = @instructions[instruction_pointer]
        
        case instruction.code
        when Instruction::INCREMENT_TAPE
          @tape_pointer = @tape_pointer + 1
          
          # add to the end of our tape -- add more
          if @tape_pointer > (@tape.size-1)
            @tape << 0
          end
      
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::DECREMENT_TAPE
          @tape_pointer = @tape_pointer - 1
          
          #prepend our tape with a value so we don't 
          #go off the left of the tape
          if @tape_pointer < 0
            @tape.unshift(0)
            @tape_pointer = 0
          end
          
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::INCREMENT_VALUE
          @tape[@tape_pointer] = @tape[@tape_pointer] + 1
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::DECREMENT_VALUE
          @tape[@tape_pointer] = @tape[@tape_pointer] - 1
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::PRINT_CHARACTER
          print @tape[@tape_pointer].chr
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::GET_CHARACTER
          @tape[@tape_pointer] = STDIN.gets.to_i
          instruction_pointer = instruction_pointer + 1
          
        when Instruction::WHILE_LOOP
          if(@tape[@tape_pointer] == 0)
            instruction_pointer = @jump_table[instruction_pointer]
          else
            instruction_pointer = instruction_pointer + 1
          end
          
        when Instruction::JUMP
          if(@tape[@tape_pointer] != 0)
            instruction_pointer = instruction.arguments
          else
            instruction_pointer = instruction_pointer + 1
          end
          
        else
          raise 'Illegal instruction type'
        end

=begin
        if (instruction_pointer-1) > 543
        sleep 0.05
        print "#{instruction_pointer-1}/#{@instructions.size}: "
        0.upto(@tape.size-1) { |i|
          if @tape_pointer == i
            print "[>#{@tape[i]}<]"
          else
            print "[#{@tape[i]}]"
          end
        }
        puts
      end
=end
      
      end
    end
  end
end

if ARGV.size == 0
  vm = RbBFVM::VM.new
  vm.evaluate_string("++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.")
  
elsif ARGV.size == 1
  vm = RbBFVM::VM.new
  code = ''
  File.open(ARGV[0], "r") { |f|
    code = f.read
  }
  
  vm.evaluate_string(code)
end
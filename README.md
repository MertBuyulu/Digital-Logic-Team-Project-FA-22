### Verilog Basics

##### Verilog Operators

- https://web.engr.oregonstate.edu/~traylor/ece474/beamer_lectures/verilog_operators.pdf

##### Concatenation operator

- https://verilogguide.readthedocs.io/en/latest/verilog/datatype.html
- https://www.chipverify.com/verilog/verilog-concatenation

##### Always block

- https://verilogguide.readthedocs.io/en/latest/verilog/procedure.html

##### Initial vs Always block

- https://www.chipverify.com/verilog/verilog-initial-block

##### Assign statement

- https://www.chipverify.com/verilog/verilog-assign-statement

##### For loop rules

- https://stackoverflow.com/questions/33163267/genvar-is-missing-for-generate-loop-variable-verilog

##### Wires vs Registers

- https://stackoverflow.com/questions/33459048/what-is-the-difference-between-reg-and-wire-in-a-verilog-module

##### How can an output and a register can share the same name?

- https://stackoverflow.com/questions/5360508/using-wire-or-reg-with-input-or-output-in-verilog

##### What is the difference between write vs display oeprations?

- The only difference is that the display task adds a new line character at the end of the output, while the $write task does not.
- So if you want to print something as new lines, use $display.
- $write becomes useful if you want to print a set of values - all on a single line.
  - **Link**: https://www.quora.com/What-is-the-difference-between-write-and-display-in-SystemVerilog

#### Control Flow of a Module in Verilog

- https://stackoverflow.com/questions/67394965/can-someone-explain-the-control-flow-of-modules-in-system-verilog

##### What is genvar variable used for?

- A genvar is a variable used in generate-for loop. It stores positive integer values.
- It differs from other Verilog variables in that it can be assigned values and changed during compilation and elaboration time.

##### Packed vs Unpacked Arrays

- Currently the compiler only supports variable indices for the final dimension of a packed array. This is an Icarus limitation, not a bug in your code.
- https://github.com/steveicarus/iverilog/issues/276

##### Other Useful Information

- Wires / registers contain one bit value unless declared as an array.
- Generate block doesn't assign values to the wires
  - https://stackoverflow.com/questions/16949007/generate-block-is-not-assigning-any-values-to-wire
  - Conflicting assignment values will cause the output to be X and having an assignment that feedback on self without a way to break the loop will also always be X.
- Declaring dynamic arrays is not permitted in Verilog.
- Verilog arrays could only be accessed one element at a time.

##### High-level workflow of the program below

1. Set up the test module, which contains the hardcoded values for 4-bit opcode.

2. two 16-bit binary numbers, and a 32 bit output [i.e. in the form of [0......0] initially).

3. Set up the breadboard, which instantiates all necesaary components of our circuit starting with a 4x16 decoder and 16:1 multiplexter.

4. The inputs/opcodes are passed into the basic math operators.

5. The operators executes and feeds the 32 bit binary number to their respective channels.

6. Decoder sends the one hot select.

7. The Multiplexer receives the 16 bit one hot select and maps it to the selected channel.

8. The binary number stored in the selected channel gets mapped into the output wire.

9. At this point, we have the desired output. Thus, we now go back in program's hierarchy to display the output.
   - (i.e. individual modules -> mux -> breadboard -> testbench -> display the result -> go to next test case -> repeat)

module FullAdder(InputA, InputB, C, Carry, Sum);
	input InputA;
	input InputB;
	input C;
	output Carry;
	output Sum;
	reg Carry;
	reg Sum;
 
	always @(*) 
	  begin
		// the equations below can be derived from the truth table of a full adder
		Sum= InputA^InputB^C;
		Carry= ((InputA^InputB)&C)|(InputA&InputB);  
	  end

endmodule

module SixteenBitFullAdder(InputA, InputB, C, Carry, Sum);
input [15:0] InputA;
input [15:0] InputB;
input C;

output Carry;
output [15:0] Sum;

wire [14:0] carryWires;

generate
    for(genvar i = 0; i < 16; i = i + 1) begin
        case(i)
            0: FullAdder FA0(InputA[i], InputB[i], C, carryWires[i], Sum[i]);
           15: FullAdder FA0(InputA[i], InputB[i], carryWires[i-1], Carry, Sum[i]);
           default: FullAdder FA0(InputA[i], InputB[i], carryWires[i-1], carryWires[i], Sum[i]);
        endcase
    end
endgenerate

endmodule

module SixteenBitAddSub(InputA, InputB, modeSUB, outputADDSUB, Carry, ADDerror);
input [15:0] InputA;
input [15:0] InputB;
input modeSUB;

output Carry;
output ADDerror;
output [31:0] outputADDSUB;

// XOR Interfaces: wires b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15
wire [15:0] xorWires;
// Carry Interfaces: wires c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16
wire [16:0] carryWires;

// Mode assigned to the initial carry [0/1]. Mode=0, Addition; Mode=1, Subtraction
assign carryWires[0]= modeSUB;

genvar i; 
generate
    for(i = 0; i < 16; i = i + 1) begin
        assign xorWires[i] = InputB[i] ^ modeSUB;
    end

    for(i = 0; i < 16; i = i + 1) begin
        FullAdder FA(InputA[i], xorWires[i], carryWires[i], carryWires[i+1], outputADDSUB[i]);
    end

    for(i = 31; i > 15; i = i - 1) begin
        assign outputADDSUB[i] = outputADDSUB[15];
    end
endgenerate

assign Carry = carryWires[16];
// overflow occurs if the value of the left most 2 bits have different values 
assign ADDerror = carryWires[16]^carryWires[15];

endmodule

module SixteenBitMultiplier(InputA, InputB, outputMUL);
input [15:0] InputA;
input [15:0] InputB;
output [31:0] outputMUL;

reg [31:0] outputMUL;

// Local Variables
reg [15:0][15:0] Augends;
reg [15:0][15:0] Adends;

// range [16*16-1:0]
wire[16*16-1:0] Sums; 

// Carry Interfaces: wires c0,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15
wire [15:0] carryWires;

generate
    for(genvar i = 0; i < 16; i = i + 1) begin
        SixteenBitFullAdder SFA(Augends[i], Adends[i], 1'b0, carryWires[i], Sums[16*i+15:16*i]);    
    end
endgenerate

integer j;

always@(*) begin

    Augends[0]= { 1'b0, ({15{InputA[0]}}&InputB[15:1]) };

    //Augends[1]...Augends[15] is initialized inside the for loop
    for(j = 0; j < 15; j = j + 1) begin
        Augends[j+1] = { carryWires[0], Sums[(16*j+1)+:15] };
        Adends[j] = { {16{InputA[j+1]}}&InputB };
    end

    outputMUL[0] = InputA[0]&InputB[0];
    outputMUL[1+:15] = {
                        Sums[208], Sums[192], Sums[176], Sums[160], Sums[144], Sums[128], Sums[112],
                        Sums[96], Sums[80], Sums[64], Sums[48], Sums[32], Sums[16], Sums[0]
                    };
    outputMUL[15+:16] = Sums[239:224];
    outputMUL[31] = carryWires[14];

end

endmodule

module SixteenBitModulus(InputA,InputB,outputMOD,MODerror);

input [15:0] InputA;
input [15:0] InputB;
output [31:0] outputMOD;

wire [15:0] InputA;
wire [15:0] InputB;
reg [31:0] outputMOD;

output MODerror;
reg MODerror;

integer i;

always @(InputA,InputB) begin
    outputMOD=InputA%InputB;

    for(i = 16; i < 32; i = i+1) begin
        outputMOD[i] = outputMOD[15];
    end

    MODerror=(InputB == 16'b0000000000000000);

end

endmodule

module SixteenBitDivision(InputA,InputB,outputDIV,DIVerror);

input [15:0] InputA;
input [15:0] InputB;
output [31:0] outputDIV;

wire [15:0] InputA;
wire [15:0] InputB;
reg [31:0] outputDIV;

output DIVerror;
reg DIVerror;

integer i;

always @(InputA,InputB) begin
    outputDIV=InputA/InputB;

    for(i = 16; i < 32; i = i+1) begin
        outputDIV[i]= outputDIV[15];
    end

    DIVerror=(InputB == 16'b0000000000000000);

end

endmodule

module Mux16x1(channels, onehot, selected);
input [15:0][31:0] channels; // 16 channels where each of the channels contain 32 bit number
input [15:0] onehot;
output[31:0] selected;

    // A x 1 = A or A x 0 = 0
	assign selected =   ({32{onehot[15]}} & channels[15]) | 
                        ({32{onehot[14]}} & channels[14]) |
			            ({32{onehot[13]}} & channels[13]) |
			            ({32{onehot[12]}} & channels[12]) |
			            ({32{onehot[11]}} & channels[11]) |
			            ({32{onehot[10]}} & channels[10]) |
			            ({32{onehot[ 9]}} & channels[ 9]) | 
			            ({32{onehot[ 8]}} & channels[ 8]) |
			            ({32{onehot[ 7]}} & channels[ 7]) |
			            ({32{onehot[ 6]}} & channels[ 6]) |
			            ({32{onehot[ 5]}} & channels[ 5]) |  
			            ({32{onehot[ 4]}} & channels[ 4]) |  
			            ({32{onehot[ 3]}} & channels[ 3]) |  
			            ({32{onehot[ 2]}} & channels[ 2]) |  
                        ({32{onehot[ 1]}} & channels[ 1]) |  
                        ({32{onehot[ 0]}} & channels[ 0]) ;

endmodule

module Dec4x16(Opcode, onehot);

	input [3:0] Opcode; // opcode
	output [15:0] onehot; // 16 bit hot select being fed into a 16:1 MUX
	
	assign onehot[ 0]=~Opcode[3]&~Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 1]=~Opcode[3]&~Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[ 2]=~Opcode[3]&~Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[ 3]=~Opcode[3]&~Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[ 4]=~Opcode[3]& Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 5]=~Opcode[3]& Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[ 6]=~Opcode[3]& Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[ 7]=~Opcode[3]& Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[ 8]= Opcode[3]&~Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[ 9]= Opcode[3]&~Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[10]= Opcode[3]&~Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[11]= Opcode[3]&~Opcode[2]& Opcode[1]& Opcode[0];
	assign onehot[12]= Opcode[3]& Opcode[2]&~Opcode[1]&~Opcode[0];
	assign onehot[13]= Opcode[3]& Opcode[2]&~Opcode[1]& Opcode[0];
	assign onehot[14]= Opcode[3]& Opcode[2]& Opcode[1]&~Opcode[0];
	assign onehot[15]= Opcode[3]& Opcode[2]& Opcode[1]& Opcode[0];

endmodule

module breadboard(InputA, InputB, Result, OpCode, Error);

input [15:0] InputA;
input [15:0] InputB;
input [3:0]  OpCode; 

wire [15:0] InputA;
wire [15:0] InputB;
wire [3:0]  OpCode; 

output [1:0] Error;
reg [1:0] Error;

output [31:0] Result;
reg [31:0] Result;

// Control
wire [15:0][31:0] channels;
wire [15:0] onehot;
wire [31:0] selected;
wire [31:0] unknown;

Dec4x16 decoder(OpCode, onehot);
Mux16x1 multiplexer(channels, onehot, selected);

// Operations

wire [31:0] outputADDSUB;
wire ADDerror;
wire [31:0] outputMUL;
wire [31:0] outputDIV;
wire DIVerror;
wire [31:0] outputMOD;
wire MODerror;

SixteenBitAddSub add(InputA, InputB, modeSUB, outputADDSUB, Carry, ADDerror);
SixteenBitMultiplier mult(InputA, InputB, outputMUL);
SixteenBitDivision div(InputA, InputB, outputDIV, DIVerror);
SixteenBitModulus mod(InputA, InputB, outputMOD, MODerror); 

// Error Reporting
reg modeADD;
reg modeSUB;
reg modeDIV;
reg modeMOD;

// Connect the MUX to the OpCodes
assign channels[ 0]=unknown;
assign channels[ 1]=unknown;
assign channels[ 2]=unknown;
assign channels[ 3]=unknown;
assign channels[ 4]=outputADDSUB;
assign channels[ 5]=outputADDSUB;
assign channels[ 6]=outputMUL;
assign channels[ 7]=outputDIV;
assign channels[ 8]=outputMOD;
assign channels[ 9]=unknown;
assign channels[10]=unknown;
assign channels[11]=unknown;
assign channels[12]=unknown;
assign channels[13]=unknown;
assign channels[14]=unknown;
assign channels[15]=unknown;

//Perform the gate-level operations in the Breadboard
always@(*)
begin

   modeADD=~OpCode[3]& OpCode[2]&~OpCode[1]&~OpCode[0];//0100, Channel 4
   modeSUB=~OpCode[3]& OpCode[2]&~OpCode[1]& OpCode[0];//0101, Channel 5
   modeDIV=~OpCode[3]& OpCode[2]& OpCode[1]& OpCode[0];//0111, Channel 7
   modeMOD= OpCode[3]&~OpCode[2]&~OpCode[1]&~OpCode[0];//1000, Channel 8
   // connect the output line of the multiplexer to the register containing the final output
   Result = selected;
   //Only show overflow if in add or subtract operation
   Error[0]=ADDerror&(modeADD|modeSUB);
   //only show divide by zero if in division or modulus operation
   Error[1]=(DIVerror|MODerror)&(modeDIV|modeMOD);

end

endmodule

module testbench();

    // Local Variables
    reg  [15:0] InputA;
    reg  [15:0] InputB;
    reg  [3:0] OpCode;
    wire [31:0] Result;
    wire [1:0] Error;

    // create breadboard
    breadboard bb32(InputA, InputB, Result, OpCode, Error);

    // stimulous

    initial begin // start stimulous thread
    #2
        $display("|------------------------------------------+---------------------------------------|");
        $display("|               Inputs                     |               Outputs                 |");
        $display("|------------------------------------------+---------------------------------------|");
        $display("|    Input A     |    Input B   |  OpCode  |      Result      |       Error        |");
        $display("|------------------------------------------+---------------------------------------|");

        // Addition
        InputA = 16'b0000000001100100;
        InputB = 16'b0000000010010110;
        OpCode= 4'b0100;
        #10

        $write("|      %3d       |", InputA);
        $write("     %3d      |", InputB);
        $write("   %4b   |", OpCode);
        $write("       %3d        |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Substraction 
        InputA = 16'b0000000011001000;
        InputB = 16'b0000000001010111;
        OpCode= 4'b0101;
        #10

        $write("|      %3d       |", InputA);
        $write("     %3d      |", InputB);
        $write("   %4b   |", OpCode);
        $write("       %3d        |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Multiplication
        InputA = 16'b00000011011101;
        InputB = 16'b00000001110100;
        OpCode= 4'b0110;
        #10

        $write("|      %3d       |", InputA);
        $write("     %3d      |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d       |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Division with error
        InputA = 16'b0000000000010101;
        InputB = 16'b0000000000000000;
        OpCode= 4'b0111;
        #10

        $write("|      %3d       |", InputA);
        $write("     %3d      |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d         |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Modulus with error
        InputA = 16'b0000000010101001;
        InputB = 16'b0000000000000000;
        OpCode= 4'b1000; 
        #10
        
        $write("|      %3d       |", InputA);
        $write("     %3d      |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d         |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");
        
        // Addition with error 
        InputA = 16'b0100100001000100;
        InputB = 16'b0101001011101110;
        OpCode= 4'b0100; 
        #10

        $write("|     %5d      |", InputA);
        $write("    %5d     |", InputB);
        $write("   %4b   |", OpCode);
        $write("    %3d    |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Substraction with error
        InputA = 16'b1100000000000000;
        InputB = 16'b0110000000000000;
        OpCode= 4'b0101; 
        #10

        $write("|     %5d      |", InputA);
        $write("    %5d     |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d       |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Multiplication with zero
        InputA = 16'b0101100000000010;
        InputB = 16'b0000000000000000;
        OpCode= 4'b0110; 
        #10

        $write("|     %5d      |", InputA);
        $write("    %5d     |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d         |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Division
        InputA = 16'b0111001100001010;
        InputB = 16'b0100000001000010;
        OpCode= 4'b1000; // changed from opcode 0111
        #10

        $write("|     %5d      |", InputA);
        $write("    %5d     |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d       |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        // Modulus
        InputA = 16'b0111111010010000;
        InputB = 16'b0011111101001000;
        OpCode= 4'b0111; // changed from opcode 0111
        #10

        $write("|     %5d      |", InputA);
        $write("    %5d     |", InputB);
        $write("   %4b   |", OpCode);
        $write("      %3d         |", Result);
        $write("        %2b          |", Error);
        $display("\n|------------------------------------------+---------------------------------------|");

        $finish;
    end

endmodule